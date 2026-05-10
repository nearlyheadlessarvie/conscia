using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Api.Health;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class DynamoDbHealthCheckTests
{
    private readonly Mock<IAmazonDynamoDB> _dynamoMock = new();

    [Fact]
    public async Task CheckHealthAsync_ReturnsHealthy_WhenRequiredTablesAndIndexesExist()
    {
        _dynamoMock.Setup(d => d.ListTablesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListTablesResponse
            {
                TableNames =
                [
                    "Transactions",
                    "RecurringSchedules",
                    "AIInteractions",
                    "WeeklyInsights",
                    "PurchasePatterns",
                    "InAppAlerts",
                    "MonthlyCategorySpends"
                ]
            });

        _dynamoMock.Setup(d => d.DescribeTableAsync("Transactions", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("Transactions", "GSI-UserId-Category-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("AIInteractions", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("AIInteractions", "GSI-TransactionId-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("InAppAlerts", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("InAppAlerts", "GSI-Trigger-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("RecurringSchedules", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("RecurringSchedules"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("WeeklyInsights", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("WeeklyInsights"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("PurchasePatterns", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("PurchasePatterns"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("MonthlyCategorySpends", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("MonthlyCategorySpends"));

        var healthCheck = new DynamoDbHealthCheck(_dynamoMock.Object);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Healthy, result.Status);
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsUnhealthy_WhenRequiredTableIsMissing()
    {
        _dynamoMock.Setup(d => d.ListTablesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListTablesResponse
            {
                TableNames =
                [
                    "Transactions",
                    "RecurringSchedules",
                    "AIInteractions",
                    "WeeklyInsights",
                    "PurchasePatterns",
                    "MonthlyCategorySpends"
                ]
            });

        var healthCheck = new DynamoDbHealthCheck(_dynamoMock.Object);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
        Assert.Contains("InAppAlerts", result.Description);
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsUnhealthy_WhenRequiredIndexIsMissing()
    {
        _dynamoMock.Setup(d => d.ListTablesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListTablesResponse
            {
                TableNames =
                [
                    "Transactions",
                    "RecurringSchedules",
                    "AIInteractions",
                    "WeeklyInsights",
                    "PurchasePatterns",
                    "InAppAlerts",
                    "MonthlyCategorySpends"
                ]
            });

        _dynamoMock.Setup(d => d.DescribeTableAsync("Transactions", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("Transactions", "GSI-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("AIInteractions", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("AIInteractions", "GSI-TransactionId-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("InAppAlerts", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("InAppAlerts", "GSI-Trigger-Date"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("RecurringSchedules", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("RecurringSchedules"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("WeeklyInsights", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("WeeklyInsights"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("PurchasePatterns", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("PurchasePatterns"));
        _dynamoMock.Setup(d => d.DescribeTableAsync("MonthlyCategorySpends", It.IsAny<CancellationToken>()))
            .ReturnsAsync(DescribeTableResponseFor("MonthlyCategorySpends"));

        var healthCheck = new DynamoDbHealthCheck(_dynamoMock.Object);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
        Assert.Contains("GSI-UserId-Category-Date", result.Description);
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsUnhealthy_WhenMonthlyCategorySpendsTableIsMissing()
    {
        _dynamoMock.Setup(d => d.ListTablesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListTablesResponse
            {
                TableNames =
                [
                    "Transactions",
                    "RecurringSchedules",
                    "AIInteractions",
                    "WeeklyInsights",
                    "PurchasePatterns",
                    "InAppAlerts"
                ]
            });

        var healthCheck = new DynamoDbHealthCheck(_dynamoMock.Object);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
        Assert.Contains("MonthlyCategorySpends", result.Description);
    }

    private static DescribeTableResponse DescribeTableResponseFor(string tableName, params string[] globalSecondaryIndexes)
    {
        return new DescribeTableResponse
        {
            Table = new TableDescription
            {
                TableName = tableName,
                GlobalSecondaryIndexes = globalSecondaryIndexes
                    .Select(indexName => new GlobalSecondaryIndexDescription { IndexName = indexName })
                    .ToList()
            }
        };
    }
}
