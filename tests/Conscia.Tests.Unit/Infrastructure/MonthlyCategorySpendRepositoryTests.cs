using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class MonthlyCategorySpendRepositoryTests
{
    [Fact]
    public async Task UpsertAsync_WritesExpectedProjectionKeyShape()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        PutItemRequest? captured = null;

        dynamo.Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new PutItemResponse());

        var repository = new MonthlyCategorySpendRepository(dynamo.Object);

        await repository.UpsertAsync(new MonthlyCategorySpend
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            MonthKey = "2026-05",
            Category = "Dining",
            NormalizedCategory = "dining",
            CurrencyCode = "PHP",
            TotalExpenseAmount = 1200m,
            TransactionCount = 3,
            LastUpdatedAt = DateTime.UtcNow,
        });

        Assert.NotNull(captured);
        Assert.Equal("MonthlyCategorySpends", captured!.TableName);
        Assert.Equal("USER#11111111-1111-1111-1111-111111111111", captured.Item["PK"].S);
        Assert.Equal("MONTH#2026-05#CAT#dining", captured.Item["SK"].S);
    }

    [Fact]
    public async Task ListRecentMonthsAsync_QueriesExpectedMonthPrefixes()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        var captured = new List<QueryRequest>();

        dynamo.Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => captured.Add(request))
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new("USER#11111111-1111-1111-1111-111111111111"),
                        ["SK"] = new("MONTH#2026-05#CAT#dining"),
                        ["UserId"] = new("11111111-1111-1111-1111-111111111111"),
                        ["MonthKey"] = new("2026-05"),
                        ["Category"] = new("Dining"),
                        ["NormalizedCategory"] = new("dining"),
                        ["CurrencyCode"] = new("PHP"),
                        ["TotalExpenseAmount"] = new() { N = "1200" },
                        ["TransactionCount"] = new() { N = "3" },
                        ["LastUpdatedAt"] = new(DateTime.UtcNow.ToString("O"))
                    }
                ]
            });

        var repository = new MonthlyCategorySpendRepository(dynamo.Object);

        var rows = await repository.ListRecentMonthsAsync(
            Guid.Parse("11111111-1111-1111-1111-111111111111"),
            ["2026-05", "2026-04"]);

        Assert.Equal(2, captured.Count);
        Assert.All(captured, request => Assert.Equal("MonthlyCategorySpends", request.TableName));
        Assert.Contains(captured, request => request.ExpressionAttributeValues[":prefix"].S == "MONTH#2026-05#CAT#");
        Assert.Contains(captured, request => request.ExpressionAttributeValues[":prefix"].S == "MONTH#2026-04#CAT#");
        Assert.NotEmpty(rows);
    }
}
