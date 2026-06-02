using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class EmailSuppressionRepositoryTests
{
    [Fact]
    public async Task UpsertAsync_NormalizesEmailAndWritesSuppressionRecord()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        PutItemRequest? captured = null;
        dynamoMock
            .Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new PutItemResponse());

        var repository = new EmailSuppressionRepository(dynamoMock.Object);

        await repository.UpsertAsync(new EmailSuppression
        {
            Email = " Suppressed@Example.COM ",
            Reason = EmailSuppressionReason.HardBounce,
            Source = "SES",
            SuppressedAt = new DateTime(2026, 6, 1, 12, 0, 0, DateTimeKind.Utc),
            SourceEventId = "event-1",
            ProviderMessageId = "ses-message-1"
        });

        Assert.NotNull(captured);
        Assert.Equal("EmailSuppressions", captured!.TableName);
        Assert.Equal("EMAIL#suppressed@example.com", captured.Item["PK"].S);
        Assert.Equal("suppressed@example.com", captured.Item["Email"].S);
        Assert.Equal("HardBounce", captured.Item["Reason"].S);
        Assert.Equal("SES", captured.Item["Source"].S);
        Assert.Equal("event-1", captured.Item["SourceEventId"].S);
        Assert.Equal("ses-message-1", captured.Item["ProviderMessageId"].S);
    }

    [Fact]
    public async Task IsSuppressedAsync_ReturnsTrueWhenRecordExists()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        GetItemRequest? captured = null;
        dynamoMock
            .Setup(d => d.GetItemAsync(It.IsAny<GetItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<GetItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new GetItemResponse
            {
                Item = new Dictionary<string, AttributeValue>
                {
                    ["PK"] = new("EMAIL#suppressed@example.com")
                }
            });

        var repository = new EmailSuppressionRepository(dynamoMock.Object);

        var suppressed = await repository.IsSuppressedAsync(" Suppressed@Example.COM ");

        Assert.True(suppressed);
        Assert.NotNull(captured);
        Assert.Equal("EMAIL#suppressed@example.com", captured!.Key["PK"].S);
    }
}
