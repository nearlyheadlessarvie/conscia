using System.Text.Json;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Infrastructure.Repositories;

public class TransactionRepository : ITransactionRepository
{
    private const string TableName = "Transactions";
    private readonly IAmazonDynamoDB _dynamo;

    public TransactionRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task<Transaction> AddWithOutboxAsync(Transaction transaction, OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        var transactItems = new List<TransactWriteItem>
        {
            new()
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = ToItem(transaction)
                }
            },
            new()
            {
                Put = new Put
                {
                    TableName = "OutboxEvents",
                    Item = OutboxToItem(outboxEvent)
                }
            }
        };

        await _dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = transactItems
        }, ct);

        return transaction;
    }

    public async Task<Transaction?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :skPrefix)",
            FilterExpression = "Id = :id",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new($"USER#{userId}"),
                [":skPrefix"] = new("TXN#"),
                [":id"] = new(id.ToString())
            }
        }, ct);

        if (response.Items.Count > 0)
            return FromItem(response.Items[0]);

        return null;
    }

    public async Task<(IReadOnlyList<Transaction> Items, string? NextToken)> QueryByUserAsync(
        Guid userId, DateTime? from, DateTime? to, string? category, int limit,
        string? paginationToken, CancellationToken ct = default)
    {
        var keyCondition = "PK = :pk";
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":pk"] = new($"USER#{userId}")
        };

        if (from.HasValue && to.HasValue)
        {
            keyCondition += " AND SK BETWEEN :skFrom AND :skTo";
            attrValues[":skFrom"] = new($"TXN#{from.Value:yyyy-MM-dd}");
            attrValues[":skTo"] = new($"TXN#{to.Value:yyyy-MM-dd}~");
        }

        string? filterExpression = null;
        if (!string.IsNullOrEmpty(category))
        {
            filterExpression = "Category = :cat";
            attrValues[":cat"] = new(category);
        }

        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = keyCondition,
            ExpressionAttributeValues = attrValues,
            FilterExpression = filterExpression,
            Limit = limit,
            ScanIndexForward = false
        };

        if (!string.IsNullOrEmpty(paginationToken))
        {
            request.ExclusiveStartKey = JsonSerializer.Deserialize<Dictionary<string, AttributeValue>>(
                Convert.FromBase64String(paginationToken));
        }

        var response = await _dynamo.QueryAsync(request, ct);
        var items = response.Items.Select(FromItem).ToList();

        string? nextToken = null;
        if (response.LastEvaluatedKey?.Count > 0)
        {
            nextToken = Convert.ToBase64String(
                JsonSerializer.SerializeToUtf8Bytes(response.LastEvaluatedKey));
        }

        return (items, nextToken);
    }

    public async Task UpdateAsync(Transaction transaction, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(transaction)
        }, ct);
    }

    public async Task DeleteWithOutboxAsync(Guid userId, Guid id, OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found for user {userId}");

        var transactItems = new List<TransactWriteItem>
        {
            new()
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new($"TXN#{existing.Date:yyyy-MM-dd}#{id}")
                    }
                }
            },
            new()
            {
                Put = new Put
                {
                    TableName = "OutboxEvents",
                    Item = OutboxToItem(outboxEvent)
                }
            }
        };

        await _dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = transactItems
        }, ct);
    }

    public async Task UpdateRegretLevelAsync(Guid userId, Guid id, RegretLevel level, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found");

        existing.RegretLevel = level;
        await UpdateAsync(existing, ct);
    }

    public async Task<IReadOnlyList<Transaction>> GetPendingRegretPromptsAsync(
        Guid userId, DateTime from, DateTime to, CancellationToken ct = default)
    {
        var (items, _) = await QueryByUserAsync(userId, from, to, null, 100, null, ct);
        return items.Where(t => t.RegretLevel is null && t.Type == TransactionType.Expense).ToList();
    }

    private static Dictionary<string, AttributeValue> ToItem(Transaction t)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{t.UserId}"),
            ["SK"] = new($"TXN#{t.Date:yyyy-MM-dd}#{t.Id}"),
            ["Id"] = new(t.Id.ToString()),
            ["UserId"] = new(t.UserId.ToString()),
            ["Type"] = new(t.Type.ToString()),
            ["Amount"] = new() { N = t.Amount.Amount.ToString("G") },
            ["CurrencyCode"] = new(t.Amount.CurrencyCode),
            ["Category"] = new(t.Category),
            ["Date"] = new(t.Date.ToString("yyyy-MM-dd")),
            ["CreatedAt"] = new(t.CreatedAt.ToString("O"))
        };

        if (t.Merchant is not null)
            item["Merchant"] = new(t.Merchant);

        if (t.Amount.ExchangeRateToBase.HasValue)
            item["ExchangeRateToBase"] = new() { N = t.Amount.ExchangeRateToBase.Value.ToString("G") };

        if (t.Location is not null)
            item["Location"] = new() { S = JsonSerializer.Serialize(t.Location) };

        if (t.RegretLevel.HasValue)
            item["RegretLevel"] = new(t.RegretLevel.Value.ToString());

        return item;
    }

    private static Transaction FromItem(Dictionary<string, AttributeValue> item)
    {
        decimal? exchangeRate = item.TryGetValue("ExchangeRateToBase", out var er)
            ? decimal.Parse(er.N) : null;

        return new Transaction
        {
            Id = Guid.Parse(item["Id"].S),
            UserId = Guid.Parse(item["UserId"].S),
            Type = Enum.Parse<TransactionType>(item["Type"].S),
            Amount = new Money(decimal.Parse(item["Amount"].N), item["CurrencyCode"].S, exchangeRate),
            Category = item["Category"].S,
            Merchant = item.TryGetValue("Merchant", out var m) ? m.S : null,
            Date = DateTime.Parse(item["Date"].S),
            Location = item.TryGetValue("Location", out var loc)
                ? JsonSerializer.Deserialize<Location>(loc.S) : null,
            RegretLevel = item.TryGetValue("RegretLevel", out var rl)
                ? Enum.Parse<RegretLevel>(rl.S) : null,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S)
        };
    }

    private static Dictionary<string, AttributeValue> OutboxToItem(OutboxEvent e)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"AGG#{e.AggregateId}"),
            ["SK"] = new($"EVENT#{e.CreatedAt:O}"),
            ["Id"] = new(e.Id.ToString()),
            ["AggregateId"] = new(e.AggregateId.ToString()),
            ["EventType"] = new(e.EventType.ToString()),
            ["Payload"] = new(e.Payload),
            ["CreatedAt"] = new(e.CreatedAt.ToString("O")),
            ["Status"] = new("PENDING"),
            ["TTL"] = new() { N = new DateTimeOffset(e.CreatedAt.AddDays(7)).ToUnixTimeSeconds().ToString() }
        };

        return item;
    }
}
