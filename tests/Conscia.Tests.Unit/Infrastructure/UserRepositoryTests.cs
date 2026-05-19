using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class UserRepositoryTests
{
    [Fact]
    public async Task GetByEmailAsync_WhenLookupItemIsNull_ReturnsNull()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.GetItemAsync(It.IsAny<GetItemRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetItemResponse { Item = null });

        var result = await new UserRepository(dynamoMock.Object)
            .GetByEmailAsync("missing@example.com", CancellationToken.None);

        Assert.Null(result);
    }
}
