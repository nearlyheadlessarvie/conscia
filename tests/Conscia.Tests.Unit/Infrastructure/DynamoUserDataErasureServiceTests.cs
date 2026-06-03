using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class DynamoUserDataErasureServiceTests
{
    [Fact]
    public async Task EraseUserDataAsync_DeletesOwnedDynamoItemsAndStoragePrefixes()
    {
        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var occurrenceDate = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc);
        var receiptId = Guid.NewGuid();
        var budgetId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var subscriptionId = Guid.NewGuid();

        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var batchWrites = new List<BatchWriteItemRequest>();

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((QueryRequest request, CancellationToken _) =>
                request.TableName == "Transactions"
                    ? new QueryResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"USER#{userId}"),
                                ["SK"] = new($"DATE#{occurrenceDate:O}#TX#{transactionId}"),
                                ["RecurringScheduleId"] = new(scheduleId.ToString()),
                                ["RecurringOccurrenceDate"] = new(occurrenceDate.ToString("O"))
                            }
                        ]
                    }
                    : new QueryResponse { Items = [] });

        dynamoMock
            .Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ScanResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"RECEIPT#{receiptId}"),
                        ["SK"] = new("PROFILE"),
                        ["EntityType"] = new("Receipt"),
                        ["UserId"] = new(userId.ToString()),
                        ["S3Key"] = new("receipts/custom-scan.jpg")
                    },
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"BUDGET#{budgetId}"),
                        ["SK"] = new("PROFILE"),
                        ["EntityType"] = new("Budget"),
                        ["UserId"] = new(userId.ToString()),
                        ["Scope"] = new("Personal"),
                        ["Category"] = new("Groceries")
                    },
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"CATEGORY#{categoryId}"),
                        ["SK"] = new("PROFILE"),
                        ["EntityType"] = new("ManagedCategory"),
                        ["UserId"] = new(userId.ToString()),
                        ["Scope"] = new("Personal"),
                        ["Type"] = new(TransactionType.Expense.ToString()),
                        ["NormalizedName"] = new("Dining")
                    },
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new("FAMILY#family"),
                        ["SK"] = new("MEMBER#2026-01-01T00:00:00.0000000Z#member"),
                        ["EntityType"] = new("FamilyMember"),
                        ["UserId"] = new(userId.ToString())
                    },
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new($"SUBSCRIPTION#{subscriptionId}"),
                        ["EntityType"] = new("UserSubscription"),
                        ["UserId"] = new(userId.ToString()),
                        ["OriginalTransactionId"] = new("store-original-transaction")
                    }
                ]
            });

        dynamoMock
            .Setup(d => d.BatchWriteItemAsync(It.IsAny<BatchWriteItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<BatchWriteItemRequest, CancellationToken>((request, _) => batchWrites.Add(request))
            .ReturnsAsync(new BatchWriteItemResponse());

        var s3Mock = new Mock<IAmazonS3>();
        var deleteObjectsRequests = new List<DeleteObjectsRequest>();

        s3Mock
            .Setup(s => s.ListObjectsV2Async(It.IsAny<ListObjectsV2Request>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((ListObjectsV2Request request, CancellationToken _) => new ListObjectsV2Response
            {
                S3Objects =
                [
                    new S3Object { Key = $"{request.Prefix}object.jpg" }
                ]
            });

        s3Mock
            .Setup(s => s.DeleteObjectsAsync(It.IsAny<DeleteObjectsRequest>(), It.IsAny<CancellationToken>()))
            .Callback<DeleteObjectsRequest, CancellationToken>((request, _) => deleteObjectsRequests.Add(request))
            .ReturnsAsync(new DeleteObjectsResponse());

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS:S3:BucketName"] = "conscia-test-bucket"
            })
            .Build();

        var service = new DynamoUserDataErasureService(dynamoMock.Object, s3Mock.Object, config);

        await service.EraseUserDataAsync(userId);

        AssertDeleteQueued(batchWrites, "Transactions", $"USER#{userId}", $"DATE#{occurrenceDate:O}#TX#{transactionId}");
        AssertDeleteQueued(batchWrites, "Transactions", $"RECURRING#{scheduleId}", $"OCCURRENCE#{occurrenceDate:O}");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"RECEIPT#{receiptId}", "PROFILE");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"BUDGET_UNIQUE#Personal#{userId}#groceries", "BUDGET");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"CATEGORY_UNIQUE#Personal#{userId}#Expense#dining", "CATEGORY");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"MEMBER_USER#{userId}", "MEMBERSHIP");
        AssertDeleteQueued(batchWrites, "ControlPlane", "SUBSCRIPTION_TX#store-original-transaction", "SUBSCRIPTION");

        var deletedS3Keys = deleteObjectsRequests
            .SelectMany(request => request.Objects)
            .Select(o => o.Key)
            .ToList();

        Assert.Contains($"profile-pictures/{userId}/object.jpg", deletedS3Keys);
        Assert.Contains($"receipts/{userId}/object.jpg", deletedS3Keys);
        Assert.Contains("receipts/custom-scan.jpg", deletedS3Keys);
    }

    [Fact]
    public async Task EraseUserDataAsync_AllowsEmptyStoragePrefixes()
    {
        var userId = Guid.NewGuid();

        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new QueryResponse { Items = [] });
        dynamoMock
            .Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ScanResponse { Items = [] });
        dynamoMock
            .Setup(d => d.BatchWriteItemAsync(It.IsAny<BatchWriteItemRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new BatchWriteItemResponse());

        var s3Mock = new Mock<IAmazonS3>();
        s3Mock
            .Setup(s => s.ListObjectsV2Async(It.IsAny<ListObjectsV2Request>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListObjectsV2Response());
        s3Mock
            .Setup(s => s.DeleteObjectsAsync(It.IsAny<DeleteObjectsRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new DeleteObjectsResponse());

        var config = new ConfigurationBuilder().Build();
        var service = new DynamoUserDataErasureService(dynamoMock.Object, s3Mock.Object, config);

        await service.EraseUserDataAsync(userId);

        s3Mock.Verify(
            s => s.DeleteObjectsAsync(It.IsAny<DeleteObjectsRequest>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task EraseUserDataAsync_RetriesUnprocessedBatchWriteItems()
    {
        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var date = new DateTime(2026, 6, 3, 0, 0, 0, DateTimeKind.Utc);

        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var batchWrites = new List<BatchWriteItemRequest>();

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((QueryRequest request, CancellationToken _) =>
                request.TableName == "Transactions"
                    ? new QueryResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"USER#{userId}"),
                                ["SK"] = new($"DATE#{date:O}#TX#{transactionId}")
                            }
                        ]
                    }
                    : new QueryResponse { Items = [] });

        dynamoMock
            .Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ScanResponse { Items = [] });

        dynamoMock
            .Setup(d => d.BatchWriteItemAsync(It.IsAny<BatchWriteItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<BatchWriteItemRequest, CancellationToken>((request, _) => batchWrites.Add(request))
            .ReturnsAsync((BatchWriteItemRequest request, CancellationToken _) =>
                batchWrites.Count == 1
                    ? new BatchWriteItemResponse { UnprocessedItems = request.RequestItems }
                    : new BatchWriteItemResponse());

        var s3Mock = EmptyS3Mock();
        var service = new DynamoUserDataErasureService(
            dynamoMock.Object,
            s3Mock.Object,
            new ConfigurationBuilder().Build());

        await service.EraseUserDataAsync(userId);

        Assert.Equal(2, batchWrites.Count(request => request.RequestItems.ContainsKey("Transactions")));
        AssertDeleteQueued(batchWrites, "Transactions", $"USER#{userId}", $"DATE#{date:O}#TX#{transactionId}");
    }

    [Fact]
    public async Task EraseUserDataAsync_DeletesOwnedFamilySpaceAndSharedRecords()
    {
        var ownerId = Guid.NewGuid();
        var memberId = Guid.NewGuid();
        var memberUserId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var budgetId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 6, 3, 0, 0, 0, DateTimeKind.Utc);

        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var batchWrites = new List<BatchWriteItemRequest>();

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((QueryRequest request, CancellationToken _) =>
            {
                var pk = request.ExpressionAttributeValues.TryGetValue(":pk", out var value)
                    ? value.S
                    : null;

                if (request.TableName == "ControlPlane" && pk == $"FAMILY#{familySpaceId}")
                {
                    return new QueryResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"FAMILY#{familySpaceId}"),
                                ["SK"] = new("PROFILE"),
                                ["EntityType"] = new("FamilySpace"),
                                ["Id"] = new(familySpaceId.ToString()),
                                ["CreatedByUserId"] = new(ownerId.ToString())
                            },
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"FAMILY#{familySpaceId}"),
                                ["SK"] = new($"MEMBER#2026-01-01T00:00:00.0000000Z#{memberId}"),
                                ["EntityType"] = new("FamilyMember"),
                                ["Id"] = new(memberId.ToString()),
                                ["FamilySpaceId"] = new(familySpaceId.ToString()),
                                ["UserId"] = new(memberUserId.ToString())
                            }
                        ]
                    };
                }

                return new QueryResponse { Items = [] };
            });

        dynamoMock
            .Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((ScanRequest request, CancellationToken _) =>
            {
                if (request.TableName == "ControlPlane" &&
                    request.FilterExpression.Contains("CreatedByUserId", StringComparison.Ordinal))
                {
                    return new ScanResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"FAMILY#{familySpaceId}"),
                                ["SK"] = new("PROFILE"),
                                ["EntityType"] = new("FamilySpace"),
                                ["Id"] = new(familySpaceId.ToString()),
                                ["CreatedByUserId"] = new(ownerId.ToString())
                            }
                        ]
                    };
                }

                if (request.TableName == "ControlPlane" &&
                    request.FilterExpression.Contains("FamilySpaceId", StringComparison.Ordinal))
                {
                    return new ScanResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"BUDGET#{budgetId}"),
                                ["SK"] = new("PROFILE"),
                                ["EntityType"] = new("Budget"),
                                ["UserId"] = new(memberUserId.ToString()),
                                ["Scope"] = new("Family"),
                                ["FamilySpaceId"] = new(familySpaceId.ToString()),
                                ["Category"] = new("Groceries")
                            }
                        ]
                    };
                }

                if (request.TableName == "Transactions" &&
                    request.FilterExpression.Contains("FamilySpaceId", StringComparison.Ordinal))
                {
                    return new ScanResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"USER#{memberUserId}"),
                                ["SK"] = new($"DATE#{transactionDate:O}#TX#{transactionId}"),
                                ["FamilySpaceId"] = new(familySpaceId.ToString())
                            }
                        ]
                    };
                }

                return new ScanResponse { Items = [] };
            });

        dynamoMock
            .Setup(d => d.BatchWriteItemAsync(It.IsAny<BatchWriteItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<BatchWriteItemRequest, CancellationToken>((request, _) => batchWrites.Add(request))
            .ReturnsAsync(new BatchWriteItemResponse());

        var service = new DynamoUserDataErasureService(
            dynamoMock.Object,
            EmptyS3Mock().Object,
            new ConfigurationBuilder().Build());

        await service.EraseUserDataAsync(ownerId);

        AssertDeleteQueued(batchWrites, "ControlPlane", $"FAMILY#{familySpaceId}", "PROFILE");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"MEMBER_USER#{memberUserId}", "MEMBERSHIP");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"BUDGET#{budgetId}", "PROFILE");
        AssertDeleteQueued(batchWrites, "ControlPlane", $"BUDGET_UNIQUE#Family#{familySpaceId}#groceries", "BUDGET");
        AssertDeleteQueued(batchWrites, "Transactions", $"USER#{memberUserId}", $"DATE#{transactionDate:O}#TX#{transactionId}");
    }

    private static void AssertDeleteQueued(
        IEnumerable<BatchWriteItemRequest> batchWrites,
        string tableName,
        string pk,
        string sk)
    {
        Assert.Contains(batchWrites, request =>
            request.RequestItems.TryGetValue(tableName, out var writes) &&
            writes.Any(write =>
                write.DeleteRequest?.Key["PK"].S == pk &&
                write.DeleteRequest.Key["SK"].S == sk));
    }

    private static Mock<IAmazonS3> EmptyS3Mock()
    {
        var s3Mock = new Mock<IAmazonS3>();
        s3Mock
            .Setup(s => s.ListObjectsV2Async(It.IsAny<ListObjectsV2Request>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListObjectsV2Response());
        s3Mock
            .Setup(s => s.DeleteObjectsAsync(It.IsAny<DeleteObjectsRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new DeleteObjectsResponse());
        return s3Mock;
    }
}
