using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class OutboxEventRepositoryTests
{
    [Fact]
    public async Task MarkProcessedAsync_UsesStoredOutboxPrimaryKey()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        UpdateItemRequest? capturedRequest = null;

        dynamoMock
            .Setup(d => d.UpdateItemAsync(It.IsAny<UpdateItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<UpdateItemRequest, CancellationToken>((request, _) => capturedRequest = request)
            .ReturnsAsync(new UpdateItemResponse());

        var repository = new OutboxEventRepository(dynamoMock.Object);
        var aggregateId = Guid.NewGuid();
        var createdAt = new DateTime(2026, 5, 7, 12, 34, 56, DateTimeKind.Utc);

        await repository.MarkProcessedAsync(
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = aggregateId,
                EventType = OutboxEventType.TransactionCreated,
                Payload = "{}",
                CreatedAt = createdAt,
            });

        Assert.NotNull(capturedRequest);
        Assert.Equal($"AGG#{aggregateId}", capturedRequest!.Key["PK"].S);
        Assert.Equal($"EVENT#{createdAt:O}", capturedRequest.Key["SK"].S);
    }
}
