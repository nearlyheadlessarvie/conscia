using System.Text.Json;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Infrastructure.Repositories;

public class TransactionRepository : DynamoRepository, ITransactionRepository
{
    private const string TableName = "Transactions";

    public TransactionRepository(IAmazonDynamoDB dynamo) : base(dynamo) 
    {}

    // ---------------- WRITE ----------------
    public async Task<Transaction> AddWithOutboxAsync(
        Transaction transaction,
        OutboxEvent outboxEvent,
        CancellationToken ct = default)
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

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = transactItems
        }, ct);

        return transaction;
    }

    public async Task UpdateAsync(Transaction transaction, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(transaction)
        }, ct);
    }

    public async Task DeleteWithOutboxAsync(Guid userId, Guid id, OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        var transactItems = new List<TransactWriteItem>
        {
            new()
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = Key(DynamoKeys.User(userId), DynamoKeys.Transaction(id))
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

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = transactItems
        }, ct);
    }

    // ---------------- READ ----------------
    public async Task<Transaction?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.User(userId), DynamoKeys.Transaction(id))
        }, ct);

        return response.IsItemSet ? FromItem(response.Item) : null;
    }

    public async Task<(IReadOnlyList<Transaction> Items, string? NextToken)> QueryByUserAsync(
        Guid userId,
        DateTime? from,
        DateTime? to,
        string? category,
        int limit,
        string? paginationToken,
        CancellationToken ct = default)
    {
        var keyCondition = "UserId = :uid";
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":uid"] = new(userId.ToString())
        };
        Dictionary<string, string>? attrNames = null;

        if (from.HasValue && to.HasValue)
        {
            keyCondition += " AND #d BETWEEN :from AND :to";
            attrNames = new Dictionary<string, string> { ["#d"] = "Date" };
            attrValues[":from"] = new(from.Value.ToString("yyyy-MM-dd"));
            attrValues[":to"]   = new(to.Value.ToString("yyyy-MM-dd"));
        }

        var request = new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI-Date",
            KeyConditionExpression = keyCondition,
            ExpressionAttributeValues = attrValues,
            Limit = limit,
            ScanIndexForward = false
        };

        if (attrNames is not null)
            request.ExpressionAttributeNames = attrNames;

        if (!string.IsNullOrEmpty(paginationToken))
        {
            request.ExclusiveStartKey =
                JsonSerializer.Deserialize<Dictionary<string, AttributeValue>>(
                    Convert.FromBase64String(paginationToken));
        }

        var response = await Dynamo.QueryAsync(request, ct);

        var items = response.Items.Select(FromItem);

        if (!string.IsNullOrEmpty(category))
            items = items.Where(t => t.Category == category);

        var list = items.ToList();

        string? nextToken = null;
        if (response.LastEvaluatedKey?.Count > 0)
        {
            nextToken = Convert.ToBase64String(
                JsonSerializer.SerializeToUtf8Bytes(response.LastEvaluatedKey));
        }

        return (list, nextToken);
    }

    public async Task<IReadOnlyList<Transaction>> GetByUserIdAndDateRangeAsync(
        Guid userId,
        DateTime from,
        DateTime to,
        CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI-Date",
            KeyConditionExpression = "UserId = :uid AND #d BETWEEN :from AND :to",
            ExpressionAttributeNames = new Dictionary<string, string> { ["#d"] = "Date" },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":uid"] = new(userId.ToString()),
                [":from"] = new(from.ToString("yyyy-MM-dd")),
                [":to"]   = new(to.ToString("yyyy-MM-dd"))
            },
            ScanIndexForward = false
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    public async Task UpdateRegretLevelAsync(Guid userId, Guid id, RegretLevel level, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found");

        existing.RegretLevel = level;
        await UpdateAsync(existing, ct);
    }

    public async Task<IReadOnlyList<Transaction>> GetUserPendingRegretPromptsAsync(
        Guid userId,
        DateTime from,
        DateTime to,
        CancellationToken ct = default)
    {
        var (items, _) = await QueryByUserAsync(userId, from, to, null, 100, null, ct);
        return items.Where(t => t.RegretLevel is null && t.Type == TransactionType.Expense).ToList();
    }

    // ---------------- MAPPERS ----------------

    private static Dictionary<string, AttributeValue> ToItem(Transaction t)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(t.UserId)),
            ["SK"] = new(DynamoKeys.Transaction(t.Id)),

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
            item["ExchangeRateToBase"] = new()
            {
                N = t.Amount.ExchangeRateToBase.Value.ToString("G")
            };

        if (t.Location is not null)
            item["Location"] = new()
            {
                S = JsonSerializer.Serialize(t.Location)
            };

        if (t.RegretLevel.HasValue)
            item["RegretLevel"] = new(t.RegretLevel.Value.ToString());

        return item;
    }

    private static Transaction FromItem(Dictionary<string, AttributeValue> item)
    {
        decimal? exchangeRate = item.TryGetValue("ExchangeRateToBase", out var er)
            ? decimal.Parse(er.N)
            : null;

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
                ? JsonSerializer.Deserialize<Location>(loc.S)
                : null,
            RegretLevel = item.TryGetValue("RegretLevel", out var rl)
                ? Enum.Parse<RegretLevel>(rl.S)
                : null,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S)
        };
    }

    private static Dictionary<string, AttributeValue> OutboxToItem(OutboxEvent e)
    {
        return new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.Outbox(e.AggregateId)),
            ["SK"] = new(DynamoKeys.EventCreatedAt(e.CreatedAt)),
            ["Id"] = new(e.Id.ToString()),
            ["AggregateId"] = new(e.AggregateId.ToString()),
            ["EventType"] = new(e.EventType.ToString()),
            ["Payload"] = new(e.Payload),
            ["CreatedAt"] = new(e.CreatedAt.ToString("O")),
            ["Status"] = new("PENDING"),
            ["TTL"] = new()
            {
                N = new DateTimeOffset(e.CreatedAt.AddDays(7))
                    .ToUnixTimeSeconds()
                    .ToString()
            }
        };
    }
}