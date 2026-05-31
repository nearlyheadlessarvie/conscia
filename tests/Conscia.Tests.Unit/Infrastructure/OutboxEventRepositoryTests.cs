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
    public async Task GetPendingAsync_IncludesStaleProcessingEvents()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var capturedRequests = new List<QueryRequest>();
        var aggregateId = Guid.NewGuid();
        var createdAt = new DateTime(2026, 5, 7, 12, 34, 56, DateTimeKind.Utc);
        var responses = new Queue<QueryResponse>([
            new QueryResponse { Items = [] },
            new QueryResponse
            {
                Items =
                [
                    OutboxItem(
                        aggregateId,
                        createdAt,
                        "PROCESSING",
                        DateTime.UtcNow.AddMinutes(-30))
                ]
            }
        ]);

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => capturedRequests.Add(request))
            .ReturnsAsync(() => responses.Dequeue());

        var repository = new OutboxEventRepository(dynamoMock.Object);

        var events = await repository.GetPendingAsync();

        Assert.Single(events);
        Assert.Equal(aggregateId, events[0].AggregateId);
        Assert.Equal(2, capturedRequests.Count);
        Assert.Equal("PENDING", capturedRequests[0].ExpressionAttributeValues[":status"].S);
        Assert.Equal("PROCESSING", capturedRequests[1].ExpressionAttributeValues[":status"].S);
        Assert.Contains("ProcessingStartedAt", capturedRequests[1].FilterExpression);
    }

    [Fact]
    public async Task TryStartProcessingAsync_ClaimsOnlyPendingEvents()
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

        var claimed = await repository.TryStartProcessingAsync(
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = aggregateId,
                EventType = OutboxEventType.TransactionCreated,
                Payload = "{}",
                CreatedAt = createdAt,
            });

        Assert.True(claimed);
        Assert.NotNull(capturedRequest);
        Assert.Equal($"AGG#{aggregateId}", capturedRequest!.Key["PK"].S);
        Assert.Equal($"EVENT#{createdAt:O}", capturedRequest.Key["SK"].S);
        Assert.Contains("#s = :pending", capturedRequest.ConditionExpression);
        Assert.Equal("SET #s = :processing, ProcessingStartedAt = :now", capturedRequest.UpdateExpression);
    }

    [Fact]
    public async Task TryStartProcessingAsync_ReclaimsStaleProcessingEvents()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        UpdateItemRequest? capturedRequest = null;

        dynamoMock
            .Setup(d => d.UpdateItemAsync(It.IsAny<UpdateItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<UpdateItemRequest, CancellationToken>((request, _) => capturedRequest = request)
            .ReturnsAsync(new UpdateItemResponse());

        var repository = new OutboxEventRepository(dynamoMock.Object);

        var claimed = await repository.TryStartProcessingAsync(
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = Guid.NewGuid(),
                EventType = OutboxEventType.TransactionCreated,
                Payload = "{}",
                CreatedAt = new DateTime(2026, 5, 7, 12, 34, 56, DateTimeKind.Utc),
            });

        Assert.True(claimed);
        Assert.NotNull(capturedRequest);
        Assert.Contains("#s = :pending", capturedRequest!.ConditionExpression);
        Assert.Contains("#s = :processing", capturedRequest.ConditionExpression);
        Assert.Contains("ProcessingStartedAt", capturedRequest.ConditionExpression);
        Assert.True(capturedRequest.ExpressionAttributeValues.ContainsKey(":leaseExpiredBefore"));
    }

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
        Assert.Equal("#s = :processing", capturedRequest.ConditionExpression);
    }

    [Fact]
    public async Task TryStartProcessingAsync_ReturnsFalseWhenEventWasAlreadyClaimed()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();

        dynamoMock
            .Setup(d => d.UpdateItemAsync(It.IsAny<UpdateItemRequest>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new ConditionalCheckFailedException("already claimed"));

        var repository = new OutboxEventRepository(dynamoMock.Object);

        var claimed = await repository.TryStartProcessingAsync(
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = Guid.NewGuid(),
                EventType = OutboxEventType.TransactionCreated,
                Payload = "{}",
                CreatedAt = new DateTime(2026, 5, 7, 12, 34, 56, DateTimeKind.Utc),
            });

        Assert.False(claimed);
    }

    private static Dictionary<string, AttributeValue> OutboxItem(
        Guid aggregateId,
        DateTime createdAt,
        string status,
        DateTime? processingStartedAt = null)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"AGG#{aggregateId}"),
            ["SK"] = new($"EVENT#{createdAt:O}"),
            ["Id"] = new(Guid.NewGuid().ToString()),
            ["AggregateId"] = new(aggregateId.ToString()),
            ["EventType"] = new(OutboxEventType.TransactionCreated.ToString()),
            ["Payload"] = new("{}"),
            ["CreatedAt"] = new(createdAt.ToString("O")),
            ["Status"] = new(status)
        };

        if (processingStartedAt.HasValue)
            item["ProcessingStartedAt"] = new(processingStartedAt.Value.ToString("O"));

        return item;
    }
}
