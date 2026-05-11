using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoDynamoSeeder
{
    private static readonly string[] UserScopedTables =
    [
        "Transactions",
        "RecurringSchedules",
        "WeeklyInsights",
        "PurchasePatterns",
        "InAppAlerts",
        "MonthlyCategorySpends",
        "ConscienceJourney"
    ];

    public static async Task SeedAsync(
        IAmazonDynamoDB dynamo,
        StoryDemoScenario scenario,
        CancellationToken ct)
    {
        await EnsureRequiredTablesAsync(dynamo, ct);

        var userPk = DynamoKeys.User(scenario.User.Id);

        foreach (var tableName in UserScopedTables)
            await DeleteUserSliceAsync(dynamo, tableName, userPk, ct);

        var transactionRepository = new TransactionRepository(dynamo);
        foreach (var transaction in scenario.Transactions)
            await transactionRepository.AddAsync(transaction, ct);

        var recurringScheduleRepository = new RecurringScheduleRepository(dynamo);
        foreach (var schedule in scenario.RecurringSchedules)
            await recurringScheduleRepository.AddAsync(schedule, ct);

        var weeklyInsightsRepository = new WeeklyInsightsRepository(dynamo);
        foreach (var insights in scenario.WeeklyInsights)
            await weeklyInsightsRepository.UpsertAsync(insights, ct);

        var purchasePatternRepository = new PurchasePatternRepository(dynamo);
        await purchasePatternRepository.UpsertManyAsync(
            scenario.User.Id,
            scenario.PurchaseSummary,
            scenario.CategoryPatterns,
            scenario.MerchantPatterns,
            ct);

        var inAppAlertRepository = new InAppAlertRepository(dynamo);
        foreach (var alert in scenario.Alerts)
            await inAppAlertRepository.AddAsync(alert, ct);

        var monthlyCategorySpendRepository = new MonthlyCategorySpendRepository(dynamo);
        foreach (var projection in scenario.MonthlyCategorySpends)
            await monthlyCategorySpendRepository.UpsertAsync(projection, ct);

        var conscienceJourneyRepository = new ConscienceJourneyRepository(dynamo);
        await conscienceJourneyRepository.UpsertProgressAsync(scenario.ConscienceProgress, ct);

        foreach (var journeyEvent in scenario.ConscienceEvents)
            await conscienceJourneyRepository.TryInsertEventAsync(journeyEvent, ct);

        foreach (var badgeProgress in scenario.ConscienceBadgeProgress)
            await conscienceJourneyRepository.UpsertBadgeProgressAsync(badgeProgress, ct);

        foreach (var questProgress in scenario.ConscienceQuestProgress)
            await conscienceJourneyRepository.UpsertQuestProgressAsync(questProgress, ct);

        foreach (var mascotMoment in scenario.ConscienceMascotMoments)
            await conscienceJourneyRepository.AddMascotMomentAsync(mascotMoment, ct);
    }

    private static async Task DeleteUserSliceAsync(
        IAmazonDynamoDB dynamo,
        string tableName,
        string userPk,
        CancellationToken ct)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await dynamo.QueryAsync(new QueryRequest
            {
                TableName = tableName,
                KeyConditionExpression = "PK = :pk",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(userPk)
                },
                ProjectionExpression = "PK, SK",
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            foreach (var batch in response.Items.Chunk(25))
            {
                await dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
                {
                    RequestItems = new Dictionary<string, List<WriteRequest>>
                    {
                        [tableName] =
                        [
                            .. batch.Select(item => new WriteRequest
                            {
                                DeleteRequest = new DeleteRequest
                                {
                                    Key = new Dictionary<string, AttributeValue>
                                    {
                                        ["PK"] = item["PK"],
                                        ["SK"] = item["SK"]
                                    }
                                }
                            })
                        ]
                    }
                }, ct);
            }

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });
    }

    private static async Task EnsureRequiredTablesAsync(
        IAmazonDynamoDB dynamo,
        CancellationToken ct)
    {
        var response = await dynamo.ListTablesAsync(new ListTablesRequest(), ct);
        var existingTables = response.TableNames.ToHashSet(StringComparer.Ordinal);
        var missingTables = UserScopedTables
            .Where(tableName => !existingTables.Contains(tableName))
            .ToList();

        if (missingTables.Count == 0)
            return;

        throw new InvalidOperationException(
            "Story demo seed requires local Dynamo tables to exist first. Missing tables: "
            + string.Join(", ", missingTables)
            + ". Run `dotnet run --project tools/DynamoSetup` and try again.");
    }
}
