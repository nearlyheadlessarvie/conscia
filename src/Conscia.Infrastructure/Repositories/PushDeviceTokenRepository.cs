using System.Security.Cryptography;
using System.Text;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Infrastructure.Repositories;

public class PushDeviceTokenRepository : DynamoRepository, IPushDeviceTokenRepository
{
    private const string TableName = "PushDeviceTokens";

    public PushDeviceTokenRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    { }

    public async Task UpsertAsync(PushDeviceToken token, CancellationToken ct = default)
    {
        var existing = await GetExistingTokenAsync(token.UserId, token.Token, ct);
        var createdAt = existing?.CreatedAt ?? token.CreatedAt;

        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(token, createdAt)
        }, ct);
    }

    public async Task<IReadOnlyList<PushDeviceToken>> GetActiveByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            FilterExpression = "IsActive = :active",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":active"] = new() { BOOL = true }
            }
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    private async Task<PushDeviceToken?> GetExistingTokenAsync(Guid userId, string token, CancellationToken ct)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.User(userId), TokenSortKey(token))
        }, ct);

        return response.Item is null || response.Item.Count == 0 ? null : FromItem(response.Item);
    }

    private static Dictionary<string, AttributeValue> ToItem(PushDeviceToken token, DateTime createdAt)
    {
        var updatedAt = token.UpdatedAt == default ? DateTime.UtcNow : token.UpdatedAt;
        var lastSeenAt = token.LastSeenAt == default ? updatedAt : token.LastSeenAt;

        return new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(token.UserId)),
            ["SK"] = new(TokenSortKey(token.Token)),
            ["UserId"] = new(token.UserId.ToString()),
            ["Token"] = new(token.Token),
            ["Platform"] = new(token.Platform),
            ["CreatedAt"] = new(createdAt.ToString("O")),
            ["UpdatedAt"] = new(updatedAt.ToString("O")),
            ["LastSeenAt"] = new(lastSeenAt.ToString("O")),
            ["IsActive"] = new() { BOOL = token.IsActive }
        };
    }

    private static PushDeviceToken FromItem(Dictionary<string, AttributeValue> item)
    {
        return new PushDeviceToken
        {
            UserId = Guid.Parse(item["UserId"].S),
            Token = item["Token"].S,
            Platform = item.TryGetValue("Platform", out var platform) ? platform.S : "unknown",
            CreatedAt = DateTime.Parse(item["CreatedAt"].S),
            UpdatedAt = DateTime.Parse(item["UpdatedAt"].S),
            LastSeenAt = DateTime.Parse(item["LastSeenAt"].S),
            IsActive = !item.TryGetValue("IsActive", out var active) || active.BOOL == true
        };
    }

    private static string TokenSortKey(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return $"PUSH_TOKEN#{Convert.ToHexString(bytes)}";
    }
}
