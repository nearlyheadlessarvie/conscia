using Amazon.DynamoDBv2;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Conscia.Api.Health;

public class DynamoDbHealthCheck(IAmazonDynamoDB dynamoDb) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(5));

            await dynamoDb.ListTablesAsync(cts.Token);
            return HealthCheckResult.Healthy();
        }
        catch (OperationCanceledException)
        {
            return HealthCheckResult.Unhealthy("DynamoDB health check timed out.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("DynamoDB is unreachable.", ex);
        }
    }
}
