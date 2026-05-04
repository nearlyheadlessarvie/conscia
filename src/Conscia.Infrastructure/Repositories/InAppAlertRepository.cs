using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Infrastructure.Repositories;

public class InAppAlertRepository : DynamoRepository, IInAppAlertRepository
{
    private const string TableName = "InAppAlerts";

    public InAppAlertRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {}

    public async Task AddAsync(InAppAlert alert, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(alert)
        }, ct);
    }

    public async Task<IReadOnlyList<InAppAlert>> GetByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId))
            },
            ScanIndexForward = false
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    private static Dictionary<string, AttributeValue> ToItem(InAppAlert a) => new()
    {
        ["PK"] = new(DynamoKeys.User(a.UserId)),
        ["SK"] = new(DynamoKeys.Alert(a.CreatedAt)),
        ["Id"] = new(a.Id.ToString()),
        ["UserId"] = new(a.UserId.ToString()),
        ["TriggerName"] = new(a.TriggerName),
        ["Title"] = new(a.Title),
        ["Message"] = new(a.Message),
        ["CreatedAt"] = new(a.CreatedAt.ToString("O")),
        ["TTL"] = new() { N = a.TTL.ToString() }
    };

    private static InAppAlert FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        UserId = Guid.Parse(item["UserId"].S),
        TriggerName = item["TriggerName"].S,
        Title = item["Title"].S,
        Message = item["Message"].S,
        CreatedAt = DateTime.Parse(item["CreatedAt"].S),
        TTL = long.Parse(item["TTL"].N)
    };
}
