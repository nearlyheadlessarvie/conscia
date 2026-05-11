using Amazon.DynamoDBv2;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Conscia.Api.Health;

public class DynamoDbHealthCheck(IAmazonDynamoDB dynamoDb) : IHealthCheck
{
    private static readonly (string TableName, string[] RequiredIndexes)[] RequiredTables =
    [
        ("Transactions", ["GSI-UserId-Category-Date"]),
        ("RecurringSchedules", []),
        ("AIInteractions", ["GSI-TransactionId-Date"]),
        ("WeeklyInsights", []),
        ("PurchasePatterns", []),
        ("InAppAlerts", ["GSI-Trigger-Date"]),
        ("MonthlyCategorySpends", []),
        ("PushDeviceTokens", []),
        ("ConscienceJourney", [])
    ];

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(5));

            var response = await dynamoDb.ListTablesAsync(cts.Token);
            var tableNames = response.TableNames.ToHashSet(StringComparer.Ordinal);

            var missingTables = RequiredTables
                .Where(required => !tableNames.Contains(required.TableName))
                .Select(required => required.TableName)
                .ToArray();

            if (missingTables.Length > 0)
            {
                return HealthCheckResult.Unhealthy(
                    $"DynamoDB is missing required tables: {string.Join(", ", missingTables)}.");
            }

            foreach (var (tableName, requiredIndexes) in RequiredTables.Where(t => t.RequiredIndexes.Length > 0))
            {
                var table = await dynamoDb.DescribeTableAsync(tableName, cts.Token);
                var existingIndexes = table.Table.GlobalSecondaryIndexes?
                    .Select(index => index.IndexName)
                    .Where(indexName => !string.IsNullOrWhiteSpace(indexName))
                    .ToHashSet(StringComparer.Ordinal)
                    ?? [];

                var missingIndexes = requiredIndexes
                    .Where(requiredIndex => !existingIndexes.Contains(requiredIndex))
                    .ToArray();

                if (missingIndexes.Length > 0)
                {
                    return HealthCheckResult.Unhealthy(
                        $"DynamoDB table '{tableName}' is missing required indexes: {string.Join(", ", missingIndexes)}.");
                }
            }

            return HealthCheckResult.Healthy();
        }
        catch (OperationCanceledException)
        {
            return HealthCheckResult.Unhealthy("DynamoDB health check timed out.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("DynamoDB schema check failed.", ex);
        }
    }
}
