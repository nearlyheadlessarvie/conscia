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
}
