using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;

namespace Conscia.Infrastructure.Repositories;

public class SessionCacheRepository : ISessionCacheRepository
{
    private const string TableName = "SessionCache";
    private static readonly TimeSpan DefaultTtl = TimeSpan.FromMinutes(5);
    private readonly IAmazonDynamoDB _dynamo;

    public SessionCacheRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task SetAsync(string key, string value, TimeSpan? ttl = null, CancellationToken ct = default)
    {
        var expiry = DateTimeOffset.UtcNow.Add(ttl ?? DefaultTtl).ToUnixTimeSeconds();

        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"SESSION#{key}"),
                ["Value"] = new(value),
                ["TTL"] = new() { N = expiry.ToString() }
            }
        }, ct);
    }

    public async Task<string?> GetAsync(string key, CancellationToken ct = default)
    {
        var response = await _dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"SESSION#{key}")
            }
        }, ct);

        if (response.Item?.Count > 0 && response.Item.TryGetValue("Value", out var val))
        {
            if (response.Item.TryGetValue("TTL", out var ttl))
            {
                var expiryEpoch = long.Parse(ttl.N);
                if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > expiryEpoch)
                    return null;
            }
            return val.S;
        }

        return null;
    }
}
