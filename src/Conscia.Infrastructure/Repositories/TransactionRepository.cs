using System.Globalization;
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
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found");

        var transactItems = new List<TransactWriteItem>
        {
            new()
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = Key(DynamoKeys.User(existing.UserId), DynamoKeys.Transaction(existing.Date, id))
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
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            FilterExpression = "Id = :id",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":id"] = new(id.ToString())
            },
            Limit = 1
        }, ct);

        if (response.Items.Count == 0)
            return null;

        return FromItem(response.Items[0]);
    }

    // Primary timeline query (FAST)
    public async Task<(IReadOnlyList<Transaction> Items, string? NextToken)> QueryByUserAsync(
        Guid userId,
        DateTime? from,
        DateTime? to,
        string? category,
        int limit,
        string? paginationToken,
        CancellationToken ct = default)
    {
        var keyCondition = "PK = :pk";
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":pk"] = new(DynamoKeys.User(userId))
        };

        if (from.HasValue && to.HasValue)
        {
            keyCondition += " AND SK BETWEEN :skFrom AND :skTo";
            attrValues[":skFrom"] = new(DynamoKeys.DateRangeStart(from.Value));
            attrValues[":skTo"]   = new(DynamoKeys.DateRangeEnd(to.Value));
        }

        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = keyCondition,
            ExpressionAttributeValues = attrValues,
            Limit = limit,
            ScanIndexForward = false
        };

        if (!string.IsNullOrEmpty(paginationToken))
        {
            request.ExclusiveStartKey =
                JsonSerializer.Deserialize<Dictionary<string, AttributeValue>>(
                    Convert.FromBase64String(paginationToken));
        }

        var response = await Dynamo.QueryAsync(request, ct);

        var items = response.Items.Select(FromItem);

        // small-set filter only (UI case)
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

    // GSI-backed category query (scalable)
    public async Task<IReadOnlyList<Transaction>> QueryByUserAndCategoryAsync(
        Guid userId,
        string category,
        DateTime from,
        DateTime to,
        CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI-UserId-Category-Date",
            KeyConditionExpression = "UserId = :uid AND GSI1SK BETWEEN :from AND :to",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":uid"] = new(userId.ToString()),
                [":from"] = new(DynamoKeys.TransactionSortKey(category, from)),
                [":to"]   = new($"{DynamoKeys.TransactionSortKey(category, to)}~")
            },
            ScanIndexForward = false
        }, ct);

        return response.Items.Select(FromItem).ToList();
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
            KeyConditionExpression = "PK = :pk AND SK BETWEEN :skFrom AND :skTo",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":skFrom"] = new(DynamoKeys.DateRangeStart(from)),
                [":skTo"]   = new(DynamoKeys.DateRangeEnd(to))
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
            ["SK"] = new(DynamoKeys.Transaction(t.Date, t.Id)),

            ["Id"] = new(t.Id.ToString()),
            ["UserId"] = new(t.UserId.ToString()),
            ["Type"] = new(t.Type.ToString()),
            ["Amount"] = new() { N = t.Amount.Amount.ToString("G") },
            ["CurrencyCode"] = new(t.Amount.CurrencyCode),
            ["Category"] = new(t.Category),
            ["Date"] = new(t.Date.ToString("O")),
            ["CreatedAt"] = new(t.CreatedAt.ToString("O")),

            // GSI SUPPORT
            ["GSI1SK"] = new(DynamoKeys.TransactionSortKey(t.Category, t.Date))
        };

        if (t.Counterparty is not null)
            item["Counterparty"] = new(t.Counterparty);

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
            Counterparty = item.TryGetValue("Counterparty", out var counterparty)
                ? counterparty.S
                : item.TryGetValue("Merchant", out var merchant) ? merchant.S : null,
            Date = ParseTransactionDate(item),
            Location = item.TryGetValue("Location", out var loc)
                ? ParseLocation(loc.S)
                : null,
            RegretLevel = item.TryGetValue("RegretLevel", out var rl)
                ? Enum.Parse<RegretLevel>(rl.S)
                : null,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
        };
    }

    private static Location? ParseLocation(string json)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        if (!root.TryGetProperty("Latitude", out var latitudeElement)
            || !root.TryGetProperty("Longitude", out var longitudeElement))
        {
            return null;
        }

        string? placeName = null;
        if (root.TryGetProperty("PlaceName", out var placeNameElement))
            placeName = placeNameElement.GetString();
        else if (root.TryGetProperty("MerchantName", out var merchantNameElement))
            placeName = merchantNameElement.GetString();

        return new Location
        {
            Latitude = latitudeElement.GetDouble(),
            Longitude = longitudeElement.GetDouble(),
            PlaceName = placeName
        };
    }

    private static DateTime ParseTransactionDate(Dictionary<string, AttributeValue> item)
    {
        if (item.TryGetValue("SK", out var sk)
            && sk.S is { } sortKey
            && TryParseDateFromSortKey(sortKey, out var preciseDate))
        {
            return preciseDate;
        }

        return DateTime.Parse(item["Date"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);
    }

    private static bool TryParseDateFromSortKey(string sortKey, out DateTime date)
    {
        date = default;

        const string prefix = "DATE#";
        const string separator = "#TX#";

        if (!sortKey.StartsWith(prefix, StringComparison.Ordinal))
            return false;

        var separatorIndex = sortKey.IndexOf(separator, StringComparison.Ordinal);
        if (separatorIndex <= prefix.Length)
            return false;

        var dateValue = sortKey[prefix.Length..separatorIndex];
        return DateTime.TryParse(
            dateValue,
            CultureInfo.InvariantCulture,
            DateTimeStyles.RoundtripKind,
            out date);
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
