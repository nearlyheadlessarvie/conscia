using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class RecurringScheduleRepositoryTests
{
    [Fact]
    public async Task AddAndGet_RecurringSchedule_RoundTripsAllCoreFields()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        PutItemRequest? putRequest = null;
        QueryRequest? queryRequest = null;

        var userId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var startDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);
        var endDate = startDate.AddMonths(6);

        dynamoMock
            .Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => putRequest = request)
            .ReturnsAsync(new PutItemResponse());

        dynamoMock
            .Setup(d => d.QueryAsync(It.IsAny<QueryRequest>(), It.IsAny<CancellationToken>()))
            .Callback<QueryRequest, CancellationToken>((request, _) => queryRequest = request)
            .ReturnsAsync(new QueryResponse
            {
                Items =
                [
                    new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{userId}"),
                        ["SK"] = new($"RECURRING#{scheduleId}"),
                        ["Id"] = new(scheduleId.ToString()),
                        ["UserId"] = new(userId.ToString()),
                        ["Type"] = new(TransactionType.Expense.ToString()),
                        ["Amount"] = new() { N = "2500" },
                        ["CurrencyCode"] = new("PHP"),
                        ["Category"] = new("Bills"),
                        ["Counterparty"] = new("Internet"),
                        ["StartDate"] = new(startDate.ToString("O")),
                        ["Cadence"] = new(RecurringCadence.Monthly.ToString()),
                        ["NextRunAt"] = new(startDate.ToString("O")),
                        ["EndDate"] = new(endDate.ToString("O")),
                        ["IsActive"] = new() { BOOL = true },
                        ["CreatedAt"] = new(startDate.ToString("O")),
                        ["UpdatedAt"] = new(startDate.ToString("O")),
                    }
                ]
            });

        var repository = new RecurringScheduleRepository(dynamoMock.Object);
        var schedule = new RecurringSchedule
        {
            Id = scheduleId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(2500m, "PHP"),
            Category = "Bills",
            Counterparty = "Internet",
            StartDate = startDate,
            Cadence = RecurringCadence.Monthly,
            NextRunAt = startDate,
            EndDate = endDate,
        };

        await repository.AddAsync(schedule, CancellationToken.None);
        var loaded = await repository.GetByIdAsync(userId, scheduleId, CancellationToken.None);

        Assert.NotNull(putRequest);
        Assert.Equal("RecurringSchedules", putRequest!.TableName);
        Assert.Equal($"USER#{userId}", putRequest.Item["PK"].S);
        Assert.Equal($"RECURRING#{scheduleId}", putRequest.Item["SK"].S);

        Assert.NotNull(queryRequest);
        Assert.Equal("RecurringSchedules", queryRequest!.TableName);
        Assert.Equal("PK = :pk", queryRequest.KeyConditionExpression);
        Assert.Equal("Id = :id", queryRequest.FilterExpression);

        Assert.NotNull(loaded);
        Assert.Equal(RecurringCadence.Monthly, loaded!.Cadence);
        Assert.Equal(startDate, loaded.NextRunAt);
        Assert.Equal(endDate, loaded.EndDate);
        Assert.Equal("Internet", loaded.Counterparty);
    }

    [Fact]
    public async Task ListByFamilySpaceAsync_ScansFamilySchedulesForTheSpace()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        ScanRequest? scanRequest = null;
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var startDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);

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
                        ["SK"] = new($"RECURRING#{scheduleId}"),
                        ["Id"] = new(scheduleId.ToString()),
                        ["UserId"] = new(userId.ToString()),
                        ["Type"] = new(TransactionType.Expense.ToString()),
                        ["Amount"] = new() { N = "2500" },
                        ["CurrencyCode"] = new("PHP"),
                        ["Category"] = new("Bills"),
                        ["Counterparty"] = new("Internet"),
                        ["StartDate"] = new(startDate.ToString("O")),
                        ["Cadence"] = new(RecurringCadence.Monthly.ToString()),
                        ["NextRunAt"] = new(startDate.ToString("O")),
                        ["IsActive"] = new() { BOOL = true },
                        ["CreatedAt"] = new(startDate.ToString("O")),
                        ["UpdatedAt"] = new(startDate.ToString("O")),
                        ["Scope"] = new(RecordScope.Family.ToString()),
                        ["FamilySpaceId"] = new(familySpaceId.ToString())
                    }
                ]
            });

        var schedules = await new RecurringScheduleRepository(dynamoMock.Object)
            .ListByFamilySpaceAsync(familySpaceId, CancellationToken.None);

        var schedule = Assert.Single(schedules);
        Assert.Equal(familySpaceId, schedule.FamilySpaceId);
        Assert.NotNull(scanRequest);
        Assert.Equal("RecurringSchedules", scanRequest!.TableName);
        Assert.Contains("#scope = :scope", scanRequest.FilterExpression);
        Assert.Contains("FamilySpaceId = :familySpaceId", scanRequest.FilterExpression);
        Assert.Equal("Scope", scanRequest.ExpressionAttributeNames["#scope"]);
        Assert.Equal(RecordScope.Family.ToString(), scanRequest.ExpressionAttributeValues[":scope"].S);
        Assert.Equal(familySpaceId.ToString(), scanRequest.ExpressionAttributeValues[":familySpaceId"].S);
    }
}
