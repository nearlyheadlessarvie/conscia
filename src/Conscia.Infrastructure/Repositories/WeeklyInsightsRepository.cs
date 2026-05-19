using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Repositories;

public class WeeklyInsightsRepository : DynamoRepository, IWeeklyInsightsRepository
{
    private const string TableName = "WeeklyInsights";

    public WeeklyInsightsRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<WeeklyInsights?> GetLatestByUserIdAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId))
            },
            ScanIndexForward = false, // Most recent first
            Limit = 1
        }, ct);

        return FirstItem(response) is { } item ? FromItem(item) : null;
    }

    public async Task<WeeklyInsights?> GetByUserIdAndWeekAsync(Guid userId, DateTime weekStartDate, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new(DynamoKeys.User(userId)),
                ["SK"] = new(DynamoKeys.Week(weekStartDate))
            }
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    public async Task UpsertAsync(WeeklyInsights insights, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(insights)
        }, ct);
    }

    public async Task<List<WeeklyInsights>> GetByUserIdAsync(Guid userId, int limit = 10, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new($"USER#{userId}")
            },
            ScanIndexForward = false, // Most recent first
            Limit = limit
        }, ct);

        return Items(response).Select(FromItem).ToList();
    }

    private static Dictionary<string, AttributeValue> ToItem(WeeklyInsights insights) => new()
    {
        ["PK"] = new(DynamoKeys.User(insights.UserId)),
        ["SK"] = new(DynamoKeys.Week(insights.WeekStartDate)),
        ["UserId"] = new(insights.UserId.ToString()),
        ["WeekStartDate"] = new(insights.WeekStartDate.ToString("O")),
        ["Mood"] = new(insights.Mood.ToString()),
        ["WorthItPercentage"] = new() { N = insights.WorthItPercentage.ToString("F2") },
        ["WorthItCount"] = new() { N = insights.WorthItCount.ToString() },
        ["TotalTransactionCount"] = new() { N = insights.TotalTransactionCount.ToString() },
        ["ImpulseTrends"] = new() { S = System.Text.Json.JsonSerializer.Serialize(insights.ImpulseTrends) }
    };

    private static WeeklyInsights FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["UserId"].S),
        WeekStartDate = DateTime.Parse(item["WeekStartDate"].S),
        Mood = Enum.Parse<FinancialMood>(item["Mood"].S),
        WorthItPercentage = double.Parse(item["WorthItPercentage"].N),
        WorthItCount = int.Parse(item["WorthItCount"].N),
        TotalTransactionCount = int.Parse(item["TotalTransactionCount"].N),
        ImpulseTrends = item.TryGetValue("ImpulseTrends", out var trends) && trends.S != null
            ? System.Text.Json.JsonSerializer.Deserialize<List<CategoryTrend>>(trends.S) ?? new()
            : new()
    };
}
