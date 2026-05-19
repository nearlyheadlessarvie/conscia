using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CategoryRepositoryTests
{
    [Fact]
    public async Task GetByNormalizedNameAsync_WhenLookupItemIsNull_ReturnsNull()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.GetItemAsync(It.IsAny<GetItemRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetItemResponse { Item = null });

        var result = await new CategoryRepository(dynamoMock.Object)
            .GetByNormalizedNameAsync(
                Guid.NewGuid(),
                null,
                RecordScope.Personal,
                TransactionType.Expense,
                "pet-care",
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task ListPersonalAsync_WhenQueryItemsIsNull_ReturnsEmptyList()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new QueryResponse { Items = null });

        var result = await new CategoryRepository(dynamoMock.Object)
            .ListPersonalAsync(Guid.NewGuid(), CancellationToken.None);

        Assert.Empty(result);
    }
}
