using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class BudgetRepositoryTests
{
    [Fact]
    public async Task AddAsync_WhenUniqueBudgetWriteFails_ThrowsFriendlyConflict()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.TransactWriteItemsAsync(
                It.IsAny<TransactWriteItemsRequest>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TransactionCanceledException(
                "Transaction cancelled, please refer cancellation reasons for specific reasons [None, ConditionalCheckFailed]"));

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            new BudgetRepository(dynamoMock.Object).AddAsync(new Budget
            {
                Id = Guid.NewGuid(),
                UserId = Guid.NewGuid(),
                Category = "Dining",
                MonthlyLimit = 4000m,
                CurrencyCode = "PHP"
            }));

        Assert.Equal("A budget for that category already exists.", error.Message);
    }
}
