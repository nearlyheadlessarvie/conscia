using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class PurchasePatternRepository : DynamoRepository, IPurchasePatternRepository
{
    private const string TableName = "PurchasePatterns";

    public PurchasePatternRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<PurchasePatternSummary?> GetSummaryAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(userId, DynamoKeys.PurchasePatternSummary())
        }, ct);

        return IsMissingItem(response.Item) ? null : SummaryFromItem(response.Item);
    }

    public async Task<IReadOnlyList<CategoryPattern>> GetCategoriesAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new("CAT#")
            }
        }, ct);

        return Items(response).Select(CategoryFromItem).ToList();
    }

    public async Task<IReadOnlyList<MerchantPattern>> GetMerchantsAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new("MER#")
            }
        }, ct);

        return Items(response).Select(MerchantFromItem).ToList();
    }

    public async Task UpsertManyAsync(
        Guid userId,
        PurchasePatternSummary summary,
        IEnumerable<CategoryPattern> categories,
        IEnumerable<MerchantPattern> merchants,
        CancellationToken ct = default)
    {
        var allItems = new List<Dictionary<string, AttributeValue>>
        {
            SummaryToItem(summary)
        };
        allItems.AddRange(categories.Select(CategoryToItem));
        allItems.AddRange(merchants.Select(MerchantToItem));

        // BatchWriteItem hard limit is 25 items per request
        foreach (var chunk in allItems.Chunk(25))
        {
            var requests = chunk.Select(item => new WriteRequest
            {
                PutRequest = new PutRequest { Item = item }
            }).ToList();

            await Dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
            {
                RequestItems = new Dictionary<string, List<WriteRequest>>
                {
                    [TableName] = requests
                }
            }, ct);
        }
    }

    // ---- Key helpers ----

    private static Guid ExtractUserId(Dictionary<string, AttributeValue> item)
        => Guid.Parse(item["PK"].S.Replace("USER#", ""));

    private static Dictionary<string, AttributeValue> Key(Guid userId, string sk) =>
        new()
        {
            ["PK"] = new(DynamoKeys.User(userId)),
            ["SK"] = new(sk)
        };

    // ---- Mappers ----

    private static Dictionary<string, AttributeValue> SummaryToItem(PurchasePatternSummary s) => new()
    {
        ["PK"] = new(DynamoKeys.User(s.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternSummary()),
        ["RegrettedAmount"] = new() { N = s.RegrettedAmount.ToString("G") },
        ["RegrettedCategory"] = new(s.RegrettedCategory),
        ["AvgRegretRate"] = new() { N = s.AvgRegretRate.ToString("F4") },
        ["PatternCount"] = new() { N = s.PatternCount.ToString() },
        ["UpdatedAt"] = new(s.UpdatedAt.ToString("O"))
    };

    private static PurchasePatternSummary SummaryFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = ExtractUserId(item),
        RegrettedAmount = decimal.Parse(item["RegrettedAmount"].N),
        RegrettedCategory = item["RegrettedCategory"].S,
        AvgRegretRate = double.Parse(item["AvgRegretRate"].N),
        PatternCount = int.Parse(item["PatternCount"].N),
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };

    private static Dictionary<string, AttributeValue> CategoryToItem(CategoryPattern c) => new()
    {
        ["PK"] = new(DynamoKeys.User(c.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternCategory(c.Category)),
        ["Category"] = new(c.Category),
        ["TotalSpend"] = new() { N = c.TotalSpend.ToString("G") },
        ["RegrettedSpend"] = new() { N = c.RegrettedSpend.ToString("G") },
        ["RegretRate"] = new() { N = c.RegretRate.ToString("F4") },
        ["TransactionCount"] = new() { N = c.TransactionCount.ToString() },
        ["ProjectedAnnual"] = new() { N = c.ProjectedAnnual.ToString("G") },
        ["UpdatedAt"] = new(c.UpdatedAt.ToString("O"))
    };

    private static CategoryPattern CategoryFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = ExtractUserId(item),
        Category = item["Category"].S,
        TotalSpend = decimal.Parse(item["TotalSpend"].N),
        RegrettedSpend = decimal.Parse(item["RegrettedSpend"].N),
        RegretRate = double.Parse(item["RegretRate"].N),
        TransactionCount = int.Parse(item["TransactionCount"].N),
        ProjectedAnnual = decimal.Parse(item["ProjectedAnnual"].N),
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };

    private static Dictionary<string, AttributeValue> MerchantToItem(MerchantPattern m) => new()
    {
        ["PK"] = new(DynamoKeys.User(m.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternMerchant(m.Merchant)),
        ["Merchant"] = new(m.Merchant),
        ["VisitCount"] = new() { N = m.VisitCount.ToString() },
        ["RegretCount"] = new() { N = m.RegretCount.ToString() },
        ["RegretRate"] = new() { N = m.RegretRate.ToString("F4") },
        ["LastVisitDate"] = new(m.LastVisitDate),
        ["UpdatedAt"] = new(m.UpdatedAt.ToString("O"))
    };

    private static MerchantPattern MerchantFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = ExtractUserId(item),
        Merchant = item["Merchant"].S,
        VisitCount = int.Parse(item["VisitCount"].N),
        RegretCount = int.Parse(item["RegretCount"].N),
        RegretRate = double.Parse(item["RegretRate"].N),
        LastVisitDate = item["LastVisitDate"].S,
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };
}
