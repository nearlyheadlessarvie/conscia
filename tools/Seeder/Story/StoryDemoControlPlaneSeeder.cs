using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoControlPlaneSeeder
{
    private const string TableName = "ControlPlane";

    public static async Task SeedAsync(
        IAmazonDynamoDB dynamo,
        StoryDemoScenario scenario,
        CancellationToken ct)
    {
        await EnsureControlPlaneTableAsync(dynamo, ct);
        await ClearKnownStoryDemoRecordsAsync(dynamo, scenario, ct);

        var users = new UserRepository(dynamo);
        var subscriptions = new UserSubscriptionRepository(dynamo);
        var entitlements = new UserEntitlementOverrideRepository(dynamo);
        var familySpaces = new FamilySpaceRepository(dynamo);
        var budgets = new BudgetRepository(dynamo);

        await users.AddAsync(scenario.User, ct);
        foreach (var user in scenario.AdditionalUsers)
            await users.AddAsync(user, ct);

        await users.AddIdentityAsync(scenario.Identity, ct);
        foreach (var identity in scenario.AdditionalIdentities)
            await users.AddIdentityAsync(identity, ct);

        await subscriptions.AddAsync(scenario.Subscription, ct);
        foreach (var entitlement in scenario.EntitlementOverrides)
            await entitlements.UpsertPremiumLifetimeAsync(entitlement, ct);

        var owner = scenario.FamilyMembers.First(member => member.UserId == scenario.User.Id);
        await familySpaces.CreateWithOwnerAsync(scenario.FamilySpace, owner, ct);

        foreach (var member in scenario.FamilyMembers.Where(member => member.Id != owner.Id))
            await familySpaces.AddMemberAsync(member, ct);

        foreach (var invite in scenario.FamilyInvites)
            await familySpaces.AddInviteAsync(invite, ct);

        foreach (var budget in scenario.Budgets)
            await budgets.AddAsync(budget, ct);
    }

    private static async Task EnsureControlPlaneTableAsync(IAmazonDynamoDB dynamo, CancellationToken ct)
    {
        var response = await dynamo.ListTablesAsync(new ListTablesRequest(), ct);
        if (response.TableNames.Contains(TableName))
            return;

        throw new InvalidOperationException(
            "Story demo seed requires the ControlPlane Dynamo table. Run `dotnet run --project tools/DynamoSetup` and try again.");
    }

    private static async Task ClearKnownStoryDemoRecordsAsync(
        IAmazonDynamoDB dynamo,
        StoryDemoScenario scenario,
        CancellationToken ct)
    {
        var keys = new List<Dictionary<string, AttributeValue>>();

        foreach (var user in new[] { scenario.User }.Concat(scenario.AdditionalUsers))
        {
            keys.AddRange(await QueryKeysAsync(dynamo, UserRepository.UserPk(user.Id), ct));
            keys.Add(Key(UserRepository.EmailPk(user.Email), "USER"));
        }

        foreach (var identity in new[] { scenario.Identity }.Concat(scenario.AdditionalIdentities))
            keys.Add(Key(UserRepository.IdentityPk(identity.Provider, identity.ProviderSub), "USER"));

        if (!string.IsNullOrWhiteSpace(scenario.Subscription.OriginalTransactionId))
            keys.Add(Key(UserRepository.SubscriptionOriginalPk(scenario.Subscription.OriginalTransactionId), "SUBSCRIPTION"));
        foreach (var entitlement in scenario.EntitlementOverrides)
            keys.Add(Key(UserRepository.UserPk(entitlement.UserId), $"ENTITLEMENT#{entitlement.EntitlementKey}"));

        keys.AddRange(await QueryKeysAsync(dynamo, FamilySpaceRepository.FamilyPk(scenario.FamilySpace.Id), ct));

        foreach (var member in scenario.FamilyMembers)
            keys.Add(Key($"MEMBER_USER#{member.UserId}", "MEMBERSHIP"));

        foreach (var invite in scenario.FamilyInvites)
            keys.Add(Key($"INVITE#{invite.Id}", "PROFILE"));

        foreach (var budget in scenario.Budgets)
        {
            keys.Add(Key(BudgetRepository.BudgetPk(budget.Id), "PROFILE"));
            keys.Add(Key(BudgetRepository.BudgetUniquePk(budget), "BUDGET"));
        }

        foreach (var batch in keys
            .DistinctBy(key => $"{key["PK"].S}|{key["SK"].S}")
            .Chunk(25))
        {
            await dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
            {
                RequestItems = new Dictionary<string, List<WriteRequest>>
                {
                    [TableName] = batch
                        .Select(key => new WriteRequest { DeleteRequest = new DeleteRequest { Key = key } })
                        .ToList()
                }
            }, ct);
        }
    }

    private static async Task<List<Dictionary<string, AttributeValue>>> QueryKeysAsync(
        IAmazonDynamoDB dynamo,
        string pk,
        CancellationToken ct)
    {
        var response = await dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(pk)
            },
            ProjectionExpression = "PK, SK"
        }, ct);

        return response.Items
            .Select(item => Key(item["PK"].S, item["SK"].S))
            .ToList();
    }

    private static Dictionary<string, AttributeValue> Key(string pk, string sk) => new()
    {
        ["PK"] = new(pk),
        ["SK"] = new(sk)
    };
}
