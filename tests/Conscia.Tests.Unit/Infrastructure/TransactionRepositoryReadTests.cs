using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Enums;
using Conscia.Domain.Entities;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class TransactionRepositoryReadTests
{
    [Fact]
    public async Task UpdateWithOutboxAsync_DeletesPreviousDateKeyWhenSortKeyChanges()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        TransactWriteItemsRequest? capturedWrite = null;

        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var oldDate = new DateTime(2026, 5, 6, 9, 30, 0, DateTimeKind.Utc);
        var newDate = new DateTime(2026, 5, 6, 0, 0, 0, DateTimeKind.Utc);

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    CreateTransactionItem(userId, transactionId, oldDate)
                ]
            });
        dynamoMock
            .Setup(d => d.TransactWriteItemsAsync(It.IsAny<TransactWriteItemsRequest>(), It.IsAny<CancellationToken>()))
            .Callback<TransactWriteItemsRequest, CancellationToken>((request, _) => capturedWrite = request)
            .ReturnsAsync(new TransactWriteItemsResponse());

        var repository = new TransactionRepository(dynamoMock.Object);

        await repository.UpdateWithOutboxAsync(
            new Transaction
            {
                Id = transactionId,
                UserId = userId,
                Type = TransactionType.Expense,
                Amount = new Money(3840m, "PHP"),
                Category = "Groceries",
                Counterparty = "Landers",
                Date = newDate,
                CreatedAt = oldDate,
                Scope = RecordScope.Family,
                FamilySpaceId = Guid.NewGuid()
            },
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = transactionId,
                EventType = OutboxEventType.TransactionUpdated,
                Payload = "{}",
                CreatedAt = DateTime.UtcNow
            });

        Assert.NotNull(capturedWrite);
        Assert.Contains(capturedWrite!.TransactItems, item =>
            item.Delete is not null &&
            item.Delete.Key["PK"].S == $"USER#{userId}" &&
            item.Delete.Key["SK"].S == $"DATE#{oldDate:O}#TX#{transactionId}");
        Assert.Contains(capturedWrite.TransactItems, item =>
            item.Put?.TableName == "Transactions" &&
            item.Put.Item["SK"].S == $"DATE#{newDate:O}#TX#{transactionId}");
    }

    [Fact]
    public async Task AddWithOutboxAsync_RecurringTransactionWritesOccurrenceSentinelWithCondition()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        TransactWriteItemsRequest? capturedWrite = null;

        var userId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var occurrenceDate = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc);

        dynamoMock
            .Setup(d => d.TransactWriteItemsAsync(It.IsAny<TransactWriteItemsRequest>(), It.IsAny<CancellationToken>()))
            .Callback<TransactWriteItemsRequest, CancellationToken>((request, _) => capturedWrite = request)
            .ReturnsAsync(new TransactWriteItemsResponse());

        var repository = new TransactionRepository(dynamoMock.Object);

        await repository.AddWithOutboxAsync(
            new Transaction
            {
                Id = transactionId,
                UserId = userId,
                Type = TransactionType.Expense,
                Amount = new Money(800m, "PHP"),
                Category = "Bills",
                Date = occurrenceDate,
                CreatedAt = occurrenceDate,
                RecurringScheduleId = scheduleId,
                RecurringOccurrenceDate = occurrenceDate
            },
            new OutboxEvent
            {
                Id = Guid.NewGuid(),
                AggregateId = transactionId,
                EventType = OutboxEventType.TransactionCreated,
                Payload = "{}",
                CreatedAt = occurrenceDate
            });

        Assert.NotNull(capturedWrite);
        Assert.Contains(capturedWrite!.TransactItems, item =>
            item.Put?.TableName == "Transactions" &&
            item.Put.ConditionExpression == "attribute_not_exists(PK)" &&
            item.Put.Item["PK"].S == $"RECURRING#{scheduleId}" &&
            item.Put.Item["SK"].S == $"OCCURRENCE#{occurrenceDate:O}");
    }

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

    [Fact]
    public async Task ExistsRecurringOccurrenceAsync_PaginatesUntilMatchingOccurrenceIsFound()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var userId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var occurrenceDate = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc);
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
                            ["SK"] = new("DATE#2026-05-01T00:00:00.0000000Z#TX#first-page")
                        }
                    }
                    : new QueryResponse
                    {
                        Items =
                        [
                            CreateTransactionItem(userId, transactionId, occurrenceDate, scheduleId, occurrenceDate)
                        ]
                    };
            });

        var exists = await new TransactionRepository(dynamoMock.Object)
            .ExistsRecurringOccurrenceAsync(userId, scheduleId, occurrenceDate, CancellationToken.None);

        Assert.True(exists);
        Assert.Equal(2, requests.Count);
        Assert.Null(requests[0].ExclusiveStartKey);
        Assert.NotNull(requests[1].ExclusiveStartKey);
    }

    [Fact]
    public async Task QueryByUserAsync_WithCategoryContinuesUntilPageContainsMatches()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        var userId = Guid.NewGuid();
        var diningTransactionId = Guid.NewGuid();
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
                        Items =
                        [
                            CreateTransactionItem(
                                userId,
                                Guid.NewGuid(),
                                new DateTime(2026, 5, 10, 0, 0, 0, DateTimeKind.Utc),
                                category: "Groceries")
                        ],
                        LastEvaluatedKey = new Dictionary<string, AttributeValue>
                        {
                            ["PK"] = new($"USER#{userId}"),
                            ["SK"] = new("DATE#2026-05-10T00:00:00.0000000Z#TX#first-page")
                        }
                    }
                    : new QueryResponse
                    {
                        Items =
                        [
                            CreateTransactionItem(
                                userId,
                                diningTransactionId,
                                new DateTime(2026, 5, 9, 0, 0, 0, DateTimeKind.Utc),
                                category: "Dining")
                        ]
                    };
            });

        var (transactions, nextToken) = await new TransactionRepository(dynamoMock.Object)
            .QueryByUserAsync(userId, null, null, "Dining", 1, null, CancellationToken.None);

        var transaction = Assert.Single(transactions);
        Assert.Equal(diningTransactionId, transaction.Id);
        Assert.Equal("Dining", transaction.Category);
        Assert.Null(nextToken);
        Assert.Equal(2, requests.Count);
        Assert.NotNull(requests[1].ExclusiveStartKey);
    }

    [Fact]
    public async Task GetByFamilySpaceAndDateRangeAsync_ScansFamilyTransactionsForTheSpaceAndRange()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        ScanRequest? scanRequest = null;
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 5, 8, 9, 30, 0, DateTimeKind.Utc);
        var from = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc);
        var to = new DateTime(2026, 5, 31, 23, 59, 59, DateTimeKind.Utc);

        dynamoMock
            .Setup(d => d.ScanAsync(It.IsAny<ScanRequest>(), It.IsAny<CancellationToken>()))
            .Callback<ScanRequest, CancellationToken>((request, _) => scanRequest = request)
            .ReturnsAsync(new ScanResponse
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
                        ["Amount"] = new() { N = "280" },
                        ["CurrencyCode"] = new("PHP"),
                        ["Category"] = new("Dining"),
                        ["Counterparty"] = new("Starbucks"),
                        ["Date"] = new(transactionDate.ToString("O")),
                        ["CreatedAt"] = new(transactionDate.ToString("O")),
                        ["Scope"] = new(RecordScope.Family.ToString()),
                        ["FamilySpaceId"] = new(familySpaceId.ToString())
                    }
                ]
            });

        var transactions = await new TransactionRepository(dynamoMock.Object)
            .GetByFamilySpaceAndDateRangeAsync(familySpaceId, from, to, CancellationToken.None);

        var transaction = Assert.Single(transactions);
        Assert.Equal(familySpaceId, transaction.FamilySpaceId);
        Assert.NotNull(scanRequest);
        Assert.Equal("Transactions", scanRequest!.TableName);
        Assert.Contains("#scope = :scope", scanRequest.FilterExpression);
        Assert.Contains("FamilySpaceId = :familySpaceId", scanRequest.FilterExpression);
        Assert.Contains("#date BETWEEN :from AND :to", scanRequest.FilterExpression);
        Assert.Equal("Scope", scanRequest.ExpressionAttributeNames["#scope"]);
        Assert.Equal("Date", scanRequest.ExpressionAttributeNames["#date"]);
        Assert.Equal(RecordScope.Family.ToString(), scanRequest.ExpressionAttributeValues[":scope"].S);
        Assert.Equal(familySpaceId.ToString(), scanRequest.ExpressionAttributeValues[":familySpaceId"].S);
        Assert.Equal(from.ToString("O"), scanRequest.ExpressionAttributeValues[":from"].S);
        Assert.Equal(to.ToString("O"), scanRequest.ExpressionAttributeValues[":to"].S);
    }

    private static Dictionary<string, AttributeValue> CreateTransactionItem(
        Guid userId,
        Guid transactionId,
        DateTime date,
        Guid? recurringScheduleId = null,
        DateTime? recurringOccurrenceDate = null,
        string category = "Groceries")
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new($"DATE#{date:O}#TX#{transactionId}"),
            ["Id"] = new(transactionId.ToString()),
            ["UserId"] = new(userId.ToString()),
            ["Type"] = new("Expense"),
            ["Amount"] = new() { N = "3840" },
            ["CurrencyCode"] = new("PHP"),
            ["Category"] = new(category),
            ["Counterparty"] = new("Landers"),
            ["Date"] = new(date.ToString("O")),
            ["CreatedAt"] = new(date.ToString("O"))
        };

        if (recurringScheduleId.HasValue)
            item["RecurringScheduleId"] = new(recurringScheduleId.Value.ToString());

        if (recurringOccurrenceDate.HasValue)
            item["RecurringOccurrenceDate"] = new(recurringOccurrenceDate.Value.ToString("O"));

        return item;
    }
}
