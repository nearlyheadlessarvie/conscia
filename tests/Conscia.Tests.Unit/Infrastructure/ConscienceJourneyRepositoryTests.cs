using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Models;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class ConscienceJourneyRepositoryTests
{
    [Fact]
    public async Task TryInsertEventAsync_WritesIdempotentEventRecord()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        PutItemRequest? captured = null;
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        dynamo.Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new PutItemResponse());

        var repository = new ConscienceJourneyRepository(dynamo.Object);

        var inserted = await repository.TryInsertEventAsync(new ConscienceJourneyEventRecord
        {
            UserId = userId,
            EventType = "reflection_completed",
            SourceId = "tx-123",
            XpAwarded = 20,
            CreatedAt = new DateTime(2026, 05, 11, 1, 0, 0, DateTimeKind.Utc)
        });

        Assert.True(inserted);
        Assert.NotNull(captured);
        Assert.Equal("ConscienceJourney", captured!.TableName);
        Assert.Equal($"USER#{userId}", captured.Item["PK"].S);
        Assert.Equal("EVENT#reflection_completed#tx-123", captured.Item["SK"].S);
        Assert.Equal("attribute_not_exists(PK) AND attribute_not_exists(SK)", captured.ConditionExpression);
    }

    [Fact]
    public async Task TryInsertEventAsync_ReturnsFalse_WhenEventAlreadyExists()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        dynamo.Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new ConditionalCheckFailedException("duplicate"));

        var repository = new ConscienceJourneyRepository(dynamo.Object);

        var inserted = await repository.TryInsertEventAsync(new ConscienceJourneyEventRecord
        {
            UserId = userId,
            EventType = "reflection_completed",
            SourceId = "tx-123",
            XpAwarded = 20,
            CreatedAt = new DateTime(2026, 05, 11, 1, 0, 0, DateTimeKind.Utc)
        });

        Assert.False(inserted);
    }

    [Fact]
    public async Task GetQuestProgressAsync_QueriesUserWeekQuestSlice()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        QueryRequest? captured = null;
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var weekStart = new DateOnly(2026, 05, 10);

        dynamo.Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new("QUEST#2026-05-10#reflect_three_purchases"),
                        ["UserId"] = new(userId.ToString()),
                        ["WeekStart"] = new("2026-05-10"),
                        ["QuestKey"] = new("reflect_three_purchases"),
                        ["Progress"] = new() { N = "2" },
                        ["Target"] = new() { N = "3" },
                        ["XpAwarded"] = new() { N = "0" },
                        ["UpdatedAt"] = new(new DateTime(2026, 05, 11, 1, 0, 0, DateTimeKind.Utc).ToString("O"))
                    }
                ]
            });

        var repository = new ConscienceJourneyRepository(dynamo.Object);

        var quests = await repository.GetQuestProgressAsync(userId, weekStart);

        Assert.NotNull(captured);
        Assert.Equal("ConscienceJourney", captured!.TableName);
        Assert.Equal("PK = :pk AND begins_with(SK, :prefix)", captured.KeyConditionExpression);
        Assert.Equal($"USER#{userId}", captured.ExpressionAttributeValues[":pk"].S);
        Assert.Equal("QUEST#2026-05-10#", captured.ExpressionAttributeValues[":prefix"].S);
        Assert.Single(quests);
        Assert.Equal("reflect_three_purchases", quests[0].QuestKey);
        Assert.Equal(2, quests[0].Progress);
    }
}
