using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public sealed class UserEntitlementOverrideRepository : DynamoRepository, IUserEntitlementOverrideRepository
{
    private const string TableName = "ControlPlane";

    public UserEntitlementOverrideRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<UserEntitlementOverride?> GetPremiumLifetimeAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.UserPk(userId), PremiumLifetimeSk)
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    public async Task<UserEntitlementOverride> UpsertPremiumLifetimeAsync(UserEntitlementOverride entitlement, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(entitlement)
        }, ct);

        return entitlement;
    }

    public async Task RevokePremiumLifetimeAsync(Guid userId, CancellationToken ct = default)
    {
        await Dynamo.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.UserPk(userId), PremiumLifetimeSk)
        }, ct);
    }

    private static string PremiumLifetimeSk => $"ENTITLEMENT#{UserEntitlementOverride.PremiumLifetimeKey}";

    private static Dictionary<string, AttributeValue> ToItem(UserEntitlementOverride entitlement)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(UserRepository.UserPk(entitlement.UserId)),
            ["SK"] = new(PremiumLifetimeSk),
            ["EntityType"] = new("UserEntitlementOverride"),
            ["UserId"] = new(entitlement.UserId.ToString()),
            ["EntitlementKey"] = new(entitlement.EntitlementKey),
            ["GrantedAt"] = new(entitlement.GrantedAt.ToString("O", CultureInfo.InvariantCulture))
        };

        AddIfNotNull(item, "GrantedBy", entitlement.GrantedBy);
        AddIfNotNull(item, "Note", entitlement.Note);
        return item;
    }

    private static UserEntitlementOverride FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["UserId"].S),
        EntitlementKey = item["EntitlementKey"].S,
        GrantedAt = DateTime.Parse(item["GrantedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
        GrantedBy = GetOptionalString(item, "GrantedBy"),
        Note = GetOptionalString(item, "Note")
    };
}
