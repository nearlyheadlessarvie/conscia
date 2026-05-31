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
    public async Task<Transaction> AddAsync(
        Transaction transaction,
        CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(transaction)
        }, ct);

        return transaction;
    }

    public async Task<Transaction> AddWithOutboxAsync(
        Transaction transaction,
        OutboxEvent outboxEvent,
        CancellationToken ct = default)
    {
        var transactItems = new List<TransactWriteItem>();

        if (RecurringOccurrenceSentinelToItem(transaction) is { } sentinelItem)
        {
            transactItems.Add(new TransactWriteItem
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = sentinelItem,
                    ConditionExpression = "attribute_not_exists(PK)"
                }
            });
        }

        transactItems.Add(new TransactWriteItem
        {
            Put = new Put
            {
                TableName = TableName,
                Item = ToItem(transaction)
            }
        });

        transactItems.Add(new TransactWriteItem
        {
            Put = new Put
            {
                TableName = "OutboxEvents",
                Item = OutboxToItem(outboxEvent)
            }
        });

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = transactItems
        }, ct);

        return transaction;
    }

    public async Task UpdateAsync(Transaction transaction, CancellationToken ct = default)
    {
        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = await BuildReplaceTransactionWritesAsync(transaction, ct)
        }, ct);
    }

    public async Task UpdateWithOutboxAsync(
        Transaction transaction,
        OutboxEvent outboxEvent,
        CancellationToken ct = default)
    {
        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems = await BuildReplaceTransactionWritesAsync(transaction, ct, outboxEvent)
        }, ct);
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found");

        await Dynamo.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.User(existing.UserId), DynamoKeys.Transaction(existing.Date, id))
        }, ct);
    }

    public async Task DeleteWithOutboxAsync(Guid userId, Guid id, OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(userId, id, ct)
            ?? throw new InvalidOperationException($"Transaction {id} not found");

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems =
            [
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
            ]
        }, ct);
    }

    // ---------------- READ ----------------
    public async Task<Transaction?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
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
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            if (FirstItem(response) is { } item)
                return FromItem(item);

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return null;
    }

    public async Task<bool> ExistsRecurringOccurrenceAsync(
        Guid userId,
        Guid recurringScheduleId,
        DateTime occurrenceDate,
        CancellationToken ct = default)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.QueryAsync(new QueryRequest
            {
                TableName = TableName,
                KeyConditionExpression = "PK = :pk",
                FilterExpression = "RecurringScheduleId = :recurringScheduleId AND RecurringOccurrenceDate = :occurrenceDate",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(DynamoKeys.User(userId)),
                    [":recurringScheduleId"] = new(recurringScheduleId.ToString()),
                    [":occurrenceDate"] = new(occurrenceDate.ToString("O"))
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            if (response.Items.Count > 0)
                return true;

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return false;
    }

    public async Task<IReadOnlyList<Transaction>> ListByRecurringScheduleAsync(
        Guid userId,
        Guid recurringScheduleId,
        CancellationToken ct = default)
    {
        var transactions = new List<Transaction>();
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.QueryAsync(new QueryRequest
            {
                TableName = TableName,
                KeyConditionExpression = "PK = :pk",
                FilterExpression = "RecurringScheduleId = :recurringScheduleId",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(DynamoKeys.User(userId)),
                    [":recurringScheduleId"] = new(recurringScheduleId.ToString())
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            transactions.AddRange(Items(response).Select(FromItem));
            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return transactions;
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

        var hasCategoryFilter = !string.IsNullOrEmpty(category);
        var list = new List<Transaction>();
        var lastEvaluatedKey = DecodePaginationToken(paginationToken);

        do
        {
            request.ExclusiveStartKey = lastEvaluatedKey;
            var response = await Dynamo.QueryAsync(request, ct);

            var items = Items(response).Select(FromItem);
            if (hasCategoryFilter)
                items = items.Where(t => t.Category == category);

            foreach (var item in items)
            {
                list.Add(item);
                if (list.Count >= limit)
                    break;
            }

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (hasCategoryFilter && list.Count < limit && lastEvaluatedKey is { Count: > 0 });

        return (list, EncodePaginationToken(lastEvaluatedKey));
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

        return Items(response).Select(FromItem).ToList();
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

        return Items(response).Select(FromItem).ToList();
    }

    public async Task<IReadOnlyList<Transaction>> GetByFamilySpaceAndDateRangeAsync(
        Guid familySpaceId,
        DateTime from,
        DateTime to,
        CancellationToken ct = default)
    {
        var transactions = new List<Transaction>();
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.ScanAsync(new ScanRequest
            {
                TableName = TableName,
                FilterExpression = "#scope = :scope AND FamilySpaceId = :familySpaceId AND #date BETWEEN :from AND :to",
                ExpressionAttributeNames = new Dictionary<string, string>
                {
                    ["#scope"] = "Scope",
                    ["#date"] = "Date"
                },
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":scope"] = new(RecordScope.Family.ToString()),
                    [":familySpaceId"] = new(familySpaceId.ToString()),
                    [":from"] = new(from.ToString("O")),
                    [":to"] = new(to.ToString("O"))
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            transactions.AddRange(Items(response).Select(FromItem));
            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return transactions;
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

    private async Task<List<TransactWriteItem>> BuildReplaceTransactionWritesAsync(
        Transaction transaction,
        CancellationToken ct,
        OutboxEvent? outboxEvent = null)
    {
        var transactionItem = ToItem(transaction);
        var currentKey = Key(transactionItem["PK"].S, transactionItem["SK"].S);
        var existingKeys = await QueryKeysByTransactionIdAsync(transaction.UserId, transaction.Id, ct);

        var writes = new List<TransactWriteItem>();
        writes.AddRange(existingKeys
            .Where(key => !IsSameKey(key, currentKey))
            .Select(key => new TransactWriteItem
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = key
                }
            }));

        writes.Add(new TransactWriteItem
        {
            Put = new Put
            {
                TableName = TableName,
                Item = transactionItem
            }
        });

        if (outboxEvent is not null)
        {
            writes.Add(new TransactWriteItem
            {
                Put = new Put
                {
                    TableName = "OutboxEvents",
                    Item = OutboxToItem(outboxEvent)
                }
            });
        }

        return writes;
    }

    private async Task<List<Dictionary<string, AttributeValue>>> QueryKeysByTransactionIdAsync(
        Guid userId,
        Guid transactionId,
        CancellationToken ct)
    {
        var keys = new List<Dictionary<string, AttributeValue>>();
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.QueryAsync(new QueryRequest
            {
                TableName = TableName,
                KeyConditionExpression = "PK = :pk",
                FilterExpression = "Id = :id",
                ProjectionExpression = "PK, SK",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(DynamoKeys.User(userId)),
                    [":id"] = new(transactionId.ToString())
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            keys.AddRange(Items(response)
                .Where(item => item.ContainsKey("PK") && item.ContainsKey("SK"))
                .Select(item => Key(item["PK"].S, item["SK"].S)));

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return keys;
    }

    private static bool IsSameKey(
        Dictionary<string, AttributeValue> left,
        Dictionary<string, AttributeValue> right) =>
        left["PK"].S == right["PK"].S && left["SK"].S == right["SK"].S;

    private static Dictionary<string, AttributeValue>? DecodePaginationToken(string? paginationToken) =>
        string.IsNullOrEmpty(paginationToken)
            ? null
            : JsonSerializer.Deserialize<Dictionary<string, AttributeValue>>(
                Convert.FromBase64String(paginationToken));

    private static string? EncodePaginationToken(Dictionary<string, AttributeValue>? lastEvaluatedKey) =>
        lastEvaluatedKey is { Count: > 0 }
            ? Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(lastEvaluatedKey))
            : null;

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
            ["Scope"] = new(t.Scope.ToString()),

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

        if (t.RecurringScheduleId.HasValue)
            item["RecurringScheduleId"] = new(t.RecurringScheduleId.Value.ToString());

        if (t.RecurringOccurrenceDate.HasValue)
            item["RecurringOccurrenceDate"] = new(t.RecurringOccurrenceDate.Value.ToString("O"));

        if (t.FamilySpaceId.HasValue)
            item["FamilySpaceId"] = new(t.FamilySpaceId.Value.ToString());

        if (t.SharedAt.HasValue)
            item["SharedAt"] = new(t.SharedAt.Value.ToString("O"));

        if (t.SharedByUserId.HasValue)
            item["SharedByUserId"] = new(t.SharedByUserId.Value.ToString());

        return item;
    }

    private static Dictionary<string, AttributeValue>? RecurringOccurrenceSentinelToItem(Transaction t)
    {
        if (!t.RecurringScheduleId.HasValue || !t.RecurringOccurrenceDate.HasValue)
            return null;

        return new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.RecurringSchedule(t.RecurringScheduleId.Value)),
            ["SK"] = new($"OCCURRENCE#{t.RecurringOccurrenceDate.Value:O}"),
            ["UserId"] = new(t.UserId.ToString()),
            ["RecurringScheduleId"] = new(t.RecurringScheduleId.Value.ToString()),
            ["RecurringOccurrenceDate"] = new(t.RecurringOccurrenceDate.Value.ToString("O")),
            ["TransactionId"] = new(t.Id.ToString()),
            ["CreatedAt"] = new(t.CreatedAt.ToString("O"))
        };
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
            RecurringScheduleId = item.TryGetValue("RecurringScheduleId", out var recurringScheduleId)
                && Guid.TryParse(recurringScheduleId.S, out var scheduleId)
                    ? scheduleId
                    : null,
            RecurringOccurrenceDate = item.TryGetValue("RecurringOccurrenceDate", out var recurringOccurrenceDate)
                && DateTime.TryParse(recurringOccurrenceDate.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var occurrenceDate)
                    ? occurrenceDate
                    : null,
            Scope = item.TryGetValue("Scope", out var scope)
                ? Enum.Parse<RecordScope>(scope.S)
                : RecordScope.Personal,
            FamilySpaceId = item.TryGetValue("FamilySpaceId", out var familySpaceId)
                && Guid.TryParse(familySpaceId.S, out var parsedFamilySpaceId)
                    ? parsedFamilySpaceId
                    : null,
            SharedAt = item.TryGetValue("SharedAt", out var sharedAt)
                && DateTime.TryParse(sharedAt.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsedSharedAt)
                    ? parsedSharedAt
                    : null,
            SharedByUserId = item.TryGetValue("SharedByUserId", out var sharedByUserId)
                && Guid.TryParse(sharedByUserId.S, out var parsedSharedByUserId)
                    ? parsedSharedByUserId
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

    private static Dictionary<string, AttributeValue> OutboxToItem(OutboxEvent e) =>
        new()
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
