using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class ReceiptRepositoryTests
{
    [Fact]
    public async Task ListByUserAsync_ReturnsEveryOwnedReceiptPage()
    {
        var userId = Guid.NewGuid();
        var firstReceiptId = Guid.NewGuid();
        var secondReceiptId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var now = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc);
        var cursor = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"RECEIPT#{firstReceiptId}"),
            ["SK"] = new("PROFILE")
        };

        var dynamo = new Mock<IAmazonDynamoDB>();
        var scanRequests = new List<ScanRequest>();

        dynamo.Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .Callback<ScanRequest, CancellationToken>((request, _) => scanRequests.Add(request))
            .ReturnsAsync((ScanRequest _, CancellationToken _) =>
                scanRequests.Count == 1
                    ? new ScanResponse
                    {
                        Items = [ReceiptItem(firstReceiptId, userId, transactionId, now)],
                        LastEvaluatedKey = cursor
                    }
                    : new ScanResponse
                    {
                        Items = [ReceiptItem(secondReceiptId, userId, transactionId, now.AddMinutes(1))]
                    });

        var repository = new ReceiptRepository(dynamo.Object);

        var receipts = await repository.ListByUserAsync(userId, CancellationToken.None);

        Assert.Equal([firstReceiptId, secondReceiptId], receipts.Select(receipt => receipt.Id));
        Assert.Equal(2, scanRequests.Count);
        Assert.Equal("ControlPlane", scanRequests[0].TableName);
        Assert.Equal("EntityType = :type AND UserId = :userId", scanRequests[0].FilterExpression);
        Assert.Equal("Receipt", scanRequests[0].ExpressionAttributeValues[":type"].S);
        Assert.Equal(userId.ToString(), scanRequests[0].ExpressionAttributeValues[":userId"].S);
        Assert.Same(cursor, scanRequests[1].ExclusiveStartKey);
    }

    private static Dictionary<string, AttributeValue> ReceiptItem(
        Guid receiptId,
        Guid userId,
        Guid transactionId,
        DateTime createdAt) =>
        new()
        {
            ["PK"] = new($"RECEIPT#{receiptId}"),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("Receipt"),
            ["Id"] = new(receiptId.ToString()),
            ["UserId"] = new(userId.ToString()),
            ["TransactionId"] = new(transactionId.ToString()),
            ["S3Key"] = new($"receipts/{userId}/{receiptId}.jpg"),
            ["OcrConfidence"] = new() { N = "0.91" },
            ["NeedsReview"] = new() { BOOL = false },
            ["Status"] = new(ReceiptStatus.Confirmed.ToString()),
            ["CreatedAt"] = new(createdAt.ToString("O"))
        };
}
