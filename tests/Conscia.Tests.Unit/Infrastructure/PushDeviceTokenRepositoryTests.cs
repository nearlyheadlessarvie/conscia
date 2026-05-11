using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Models;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class PushDeviceTokenRepositoryTests
{
    [Fact]
    public async Task UpsertAsync_WritesTokenUsingStableHashedSortKey()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        PutItemRequest? captured = null;
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        dynamo.Setup(d => d.GetItemAsync(It.IsAny<GetItemRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetItemResponse());
        dynamo.Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new PutItemResponse());

        var repository = new PushDeviceTokenRepository(dynamo.Object);

        await repository.UpsertAsync(new PushDeviceToken
        {
            UserId = userId,
            Token = "fcm-token-123",
            Platform = "android",
            CreatedAt = new DateTime(2026, 05, 11, 1, 0, 0, DateTimeKind.Utc),
            UpdatedAt = new DateTime(2026, 05, 11, 1, 5, 0, DateTimeKind.Utc),
            LastSeenAt = new DateTime(2026, 05, 11, 1, 5, 0, DateTimeKind.Utc),
            IsActive = true
        });

        Assert.NotNull(captured);
        Assert.Equal("PushDeviceTokens", captured!.TableName);
        Assert.Equal($"USER#{userId}", captured.Item["PK"].S);
        Assert.StartsWith("PUSH_TOKEN#", captured.Item["SK"].S);
        Assert.DoesNotContain("fcm-token-123", captured.Item["SK"].S);
        Assert.Equal("fcm-token-123", captured.Item["Token"].S);
        Assert.True(captured.Item["IsActive"].BOOL);
    }

    [Fact]
    public async Task GetActiveByUserAsync_QueriesActiveTokensForUser()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        QueryRequest? captured = null;
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var now = new DateTime(2026, 05, 11, 1, 0, 0, DateTimeKind.Utc);

        dynamo.Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new("PUSH_TOKEN#HASH"),
                        ["UserId"] = new(userId.ToString()),
                        ["Token"] = new("fcm-token-123"),
                        ["Platform"] = new("ios"),
                        ["CreatedAt"] = new(now.ToString("O")),
                        ["UpdatedAt"] = new(now.ToString("O")),
                        ["LastSeenAt"] = new(now.ToString("O")),
                        ["IsActive"] = new() { BOOL = true }
                    }
                ]
            });

        var repository = new PushDeviceTokenRepository(dynamo.Object);

        var tokens = await repository.GetActiveByUserAsync(userId);

        Assert.NotNull(captured);
        Assert.Equal("PushDeviceTokens", captured!.TableName);
        Assert.Equal("PK = :pk", captured.KeyConditionExpression);
        Assert.Equal("IsActive = :active", captured.FilterExpression);
        Assert.Single(tokens);
        Assert.Equal("fcm-token-123", tokens[0].Token);
    }
}
