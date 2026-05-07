using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class TransactionRepositoryReadTests
{
    [Fact]
    public async Task GetByIdAsync_QueriesUserPartitionInsteadOfMissingTransactionIdIndex()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        QueryRequest? capturedRequest = null;

        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 5, 8, 9, 30, 0, DateTimeKind.Utc);

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => capturedRequest = request)
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new($"DATE#{transactionDate:O}#TX#{transactionId}"),
                        ["Id"] = new(transactionId.ToString()),
                        ["UserId"] = new(userId.ToString()),
                        ["Type"] = new("Expense"),
                        ["Amount"] = new() { N = "42.5" },
                        ["CurrencyCode"] = new("USD"),
                        ["Category"] = new("Dining"),
                        ["Counterparty"] = new("Cafe"),
                        ["Date"] = new(transactionDate.ToString("O")),
                        ["CreatedAt"] = new(transactionDate.ToString("O"))
                    }
                ]
            });

        var repository = new TransactionRepository(dynamoMock.Object);

        var transaction = await repository.GetByIdAsync(userId, transactionId);

        Assert.NotNull(transaction);
        Assert.NotNull(capturedRequest);
        Assert.Null(capturedRequest!.IndexName);
        Assert.Equal("PK = :pk", capturedRequest.KeyConditionExpression);
        Assert.Equal("Id = :id", capturedRequest.FilterExpression);
        Assert.Equal($"USER#{userId}", capturedRequest.ExpressionAttributeValues[":pk"].S);
        Assert.Equal(transactionId.ToString(), capturedRequest.ExpressionAttributeValues[":id"].S);
        Assert.Null(capturedRequest.Limit);
    }

    [Fact]
    public async Task GetByIdAsync_PaginatesUntilMatchingTransactionIsFound()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 5, 8, 9, 30, 0, DateTimeKind.Utc);
        var requests = new List<QueryRequest>();
        var callCount = 0;

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => requests.Add(request))
            .ReturnsAsync(() =>
            {
                callCount++;
                return callCount == 1
                    ? new QueryResponse
                    {
                        Items = [],
                        LastEvaluatedKey = new Dictionary<string, AttributeValue>
                        {
                            ["PK"] = new($"USER#{userId}"),
                            ["SK"] = new("DATE#2026-05-08T00:00:00.0000000Z#TX#first-page")
                        }
                    }
                    : new QueryResponse
                    {
                        Items =
                        [
                            new Dictionary<string, AttributeValue>
                            {
                                ["PK"] = new($"USER#{userId}"),
                                ["SK"] = new($"DATE#{transactionDate:O}#TX#{transactionId}"),
                                ["Id"] = new(transactionId.ToString()),
                                ["UserId"] = new(userId.ToString()),
                                ["Type"] = new("Expense"),
                                ["Amount"] = new() { N = "42.5" },
                                ["CurrencyCode"] = new("USD"),
                                ["Category"] = new("Dining"),
                                ["Counterparty"] = new("Cafe"),
                                ["Date"] = new(transactionDate.ToString("O")),
                                ["CreatedAt"] = new(transactionDate.ToString("O"))
                            }
                        ]
                    };
            });

        var repository = new TransactionRepository(dynamoMock.Object);

        var transaction = await repository.GetByIdAsync(userId, transactionId);

        Assert.NotNull(transaction);
        Assert.Equal(2, requests.Count);
        Assert.Null(requests[0].ExclusiveStartKey);
        Assert.NotNull(requests[1].ExclusiveStartKey);
    }
}
