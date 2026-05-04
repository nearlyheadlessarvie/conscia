using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class BehaviorProfileRepository : IBehaviorProfileRepository
{
    private const string TableName = "BehaviorProfiles";
    private readonly IAmazonDynamoDB _dynamo;

    public BehaviorProfileRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task<BehaviorProfile?> GetByUserIdAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await _dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"USER#{userId}")
            }
        }, ct);

        return response.Item?.Count > 0 ? FromItem(response.Item) : null;
    }

    public async Task UpsertAsync(BehaviorProfile profile, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(profile)
        }, ct);
    }

    private static Dictionary<string, AttributeValue> ToItem(BehaviorProfile p) => new()
    {
        ["PK"] = new($"USER#{p.UserId}"),

        ["UserId"] = new(p.UserId.ToString()),
        ["PreventedPurchases"] = new() { N = p.PreventedPurchases.ToString() },
        ["Overrides"] = new() { N = p.Overrides.ToString() },
        ["Regrets"] = new() { N = p.Regrets.ToString() }
    };

    private static BehaviorProfile FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["UserId"].S),
        PreventedPurchases = int.Parse(item["PreventedPurchases"].N),
        Overrides = int.Parse(item["Overrides"].N),
        Regrets = int.Parse(item["Regrets"].N)
    };
}