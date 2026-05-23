using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public class UserSubscriptionRepository : DynamoRepository, IUserSubscriptionRepository
{
    private const string TableName = "ControlPlane";

    public UserSubscriptionRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<UserSubscription?> GetLatestByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(UserRepository.UserPk(userId)),
                [":prefix"] = new("SUBSCRIPTION#")
            }
        }, ct);

        return Items(response)
            .Select(FromItem)
            .OrderByDescending(subscription => subscription.ExpiresAt ?? DateTime.MaxValue)
            .FirstOrDefault();
    }

    public async Task<UserSubscription?> GetByOriginalTransactionIdAsync(string originalTransactionId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.SubscriptionOriginalPk(originalTransactionId), "SUBSCRIPTION")
        }, ct);

        if (IsMissingItem(response.Item) ||
            !response.Item.TryGetValue("UserId", out var userId) ||
            !response.Item.TryGetValue("SubscriptionId", out var subscriptionId))
        {
            return null;
        }

        return Guid.TryParse(userId.S, out var parsedUserId) && Guid.TryParse(subscriptionId.S, out var parsedSubscriptionId)
            ? await GetByIdAsync(parsedUserId, parsedSubscriptionId, ct)
            : null;
    }

    public async Task<UserSubscription> AddAsync(UserSubscription subscription, CancellationToken ct = default)
    {
        var writes = new List<TransactWriteItem>
        {
            new()
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = ToItem(subscription),
                    ConditionExpression = "attribute_not_exists(PK) AND attribute_not_exists(SK)"
                }
            }
        };

        if (!string.IsNullOrWhiteSpace(subscription.OriginalTransactionId))
        {
            writes.Add(new TransactWriteItem
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = OriginalTransactionSentinel(subscription),
                    ConditionExpression = "attribute_not_exists(PK)"
                }
            });
        }

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest { TransactItems = writes }, ct);
        return subscription;
    }

    public async Task<UserSubscription> UpdateAsync(UserSubscription subscription, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(subscription)
        }, ct);

        return subscription;
    }

    private async Task<UserSubscription?> GetByIdAsync(Guid userId, Guid subscriptionId, CancellationToken ct)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.UserPk(userId), SubscriptionSk(subscriptionId))
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    private static string SubscriptionSk(Guid id) => $"SUBSCRIPTION#{id}";

    private static Dictionary<string, AttributeValue> ToItem(UserSubscription subscription)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(UserRepository.UserPk(subscription.UserId)),
            ["SK"] = new(SubscriptionSk(subscription.Id)),
            ["EntityType"] = new("UserSubscription"),
            ["Id"] = new(subscription.Id.ToString()),
            ["UserId"] = new(subscription.UserId.ToString()),
            ["Tier"] = new(subscription.Tier.ToString()),
            ["Status"] = new(subscription.Status.ToString()),
            ["Platform"] = new(subscription.Platform.ToString())
        };

        AddIfNotNull(item, "ExpiresAt", subscription.ExpiresAt);
        AddIfNotNull(item, "OriginalTransactionId", subscription.OriginalTransactionId);
        return item;
    }

    private static UserSubscription FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        UserId = Guid.Parse(item["UserId"].S),
        Tier = Enum.Parse<SubscriptionTier>(item["Tier"].S),
        Status = item.TryGetValue("Status", out var status)
            ? Enum.Parse<SubscriptionStatus>(status.S)
            : SubscriptionStatus.Unknown,
        Platform = Enum.Parse<Platform>(item["Platform"].S),
        ExpiresAt = GetOptionalDateTime(item, "ExpiresAt"),
        OriginalTransactionId = GetOptionalString(item, "OriginalTransactionId")
    };

    private static Dictionary<string, AttributeValue> OriginalTransactionSentinel(UserSubscription subscription) => new()
    {
        ["PK"] = new(UserRepository.SubscriptionOriginalPk(subscription.OriginalTransactionId!)),
        ["SK"] = new("SUBSCRIPTION"),
        ["EntityType"] = new("UserSubscriptionLookup"),
        ["UserId"] = new(subscription.UserId.ToString()),
        ["SubscriptionId"] = new(subscription.Id.ToString())
    };
}
