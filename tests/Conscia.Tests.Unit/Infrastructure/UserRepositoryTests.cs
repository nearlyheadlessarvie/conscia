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

    [Fact]
    public async Task DeleteAsync_RetriesUnprocessedBatchWriteItems()
    {
        var userId = Guid.NewGuid();
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var batchWrites = new List<BatchWriteItemRequest>();

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new("PROFILE"),
                        ["Email"] = new("delete@example.com")
                    }
                ]
            });

        dynamoMock
            .Setup(d => d.BatchWriteItemAsync(It.IsAny<BatchWriteItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<BatchWriteItemRequest, CancellationToken>((request, _) => batchWrites.Add(request))
            .ReturnsAsync((BatchWriteItemRequest request, CancellationToken _) =>
                batchWrites.Count == 1
                    ? new BatchWriteItemResponse { UnprocessedItems = request.RequestItems }
                    : new BatchWriteItemResponse());

        await new UserRepository(dynamoMock.Object).DeleteAsync(userId, CancellationToken.None);

        Assert.Equal(2, batchWrites.Count);
    }
}
