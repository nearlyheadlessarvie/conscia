using System.Globalization;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Infrastructure.Repositories;

public class RecurringScheduleRepository : DynamoRepository, IRecurringScheduleRepository
{
    private const string TableName = "RecurringSchedules";

    public RecurringScheduleRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<RecurringSchedule> AddAsync(RecurringSchedule schedule, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(schedule)
        }, ct);

        return schedule;
    }

    public async Task<RecurringSchedule?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            FilterExpression = "Id = :id",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":id"] = new(id.ToString())
            }
        }, ct);

        return response.Items.Count > 0 ? FromItem(response.Items[0]) : null;
    }

    public async Task<IReadOnlyList<RecurringSchedule>> ListAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId))
            }
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    public async Task UpdateAsync(RecurringSchedule schedule, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(schedule)
        }, ct);
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        await Dynamo.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.User(userId), DynamoKeys.RecurringSchedule(id))
        }, ct);
    }

    public async Task<IReadOnlyList<RecurringSchedule>> ListDueAsync(DateTime nowUtc, CancellationToken ct = default)
    {
        var response = await Dynamo.ScanAsync(new ScanRequest
        {
            TableName = TableName,
            FilterExpression = "IsActive = :isActive AND NextRunAt <= :nowUtc",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":isActive"] = new() { BOOL = true },
                [":nowUtc"] = new(nowUtc.ToString("O"))
            }
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    private static Dictionary<string, AttributeValue> ToItem(RecurringSchedule schedule)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(schedule.UserId)),
            ["SK"] = new(DynamoKeys.RecurringSchedule(schedule.Id)),
            ["Id"] = new(schedule.Id.ToString()),
            ["UserId"] = new(schedule.UserId.ToString()),
            ["Type"] = new(schedule.Type.ToString()),
            ["Amount"] = new() { N = schedule.Amount.Amount.ToString("G") },
            ["CurrencyCode"] = new(schedule.Amount.CurrencyCode),
            ["Category"] = new(schedule.Category),
            ["StartDate"] = new(schedule.StartDate.ToString("O")),
            ["Cadence"] = new(schedule.Cadence.ToString()),
            ["NextRunAt"] = new(schedule.NextRunAt.ToString("O")),
            ["IsActive"] = new() { BOOL = schedule.IsActive },
            ["CreatedAt"] = new(schedule.CreatedAt.ToString("O")),
            ["UpdatedAt"] = new(schedule.UpdatedAt.ToString("O")),
            ["Scope"] = new(schedule.Scope.ToString()),
        };

        if (schedule.Counterparty is not null)
            item["Counterparty"] = new(schedule.Counterparty);

        if (schedule.EndDate.HasValue)
            item["EndDate"] = new(schedule.EndDate.Value.ToString("O"));

        if (schedule.LastGeneratedAt.HasValue)
            item["LastGeneratedAt"] = new(schedule.LastGeneratedAt.Value.ToString("O"));

        if (schedule.FamilySpaceId.HasValue)
            item["FamilySpaceId"] = new(schedule.FamilySpaceId.Value.ToString());

        if (schedule.SharedAt.HasValue)
            item["SharedAt"] = new(schedule.SharedAt.Value.ToString("O"));

        if (schedule.SharedByUserId.HasValue)
            item["SharedByUserId"] = new(schedule.SharedByUserId.Value.ToString());

        if (schedule.Amount.ExchangeRateToBase.HasValue)
            item["ExchangeRateToBase"] = new()
            {
                N = schedule.Amount.ExchangeRateToBase.Value.ToString("G")
            };

        return item;
    }

    private static RecurringSchedule FromItem(Dictionary<string, AttributeValue> item)
    {
        decimal? exchangeRate = item.TryGetValue("ExchangeRateToBase", out var exchangeRateValue)
            ? decimal.Parse(exchangeRateValue.N, CultureInfo.InvariantCulture)
            : null;

        return new RecurringSchedule
        {
            Id = Guid.Parse(item["Id"].S),
            UserId = Guid.Parse(item["UserId"].S),
            Type = Enum.Parse<TransactionType>(item["Type"].S),
            Amount = new Money(decimal.Parse(item["Amount"].N, CultureInfo.InvariantCulture), item["CurrencyCode"].S, exchangeRate),
            Category = item["Category"].S,
            Counterparty = item.TryGetValue("Counterparty", out var counterparty) ? counterparty.S : null,
            StartDate = DateTime.Parse(item["StartDate"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
            Cadence = Enum.Parse<RecurringCadence>(item["Cadence"].S),
            NextRunAt = DateTime.Parse(item["NextRunAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
            EndDate = item.TryGetValue("EndDate", out var endDate)
                ? DateTime.Parse(endDate.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
                : null,
            IsActive = item.TryGetValue("IsActive", out var isActive) ? isActive.BOOL == true : true,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
            UpdatedAt = DateTime.Parse(item["UpdatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
            LastGeneratedAt = item.TryGetValue("LastGeneratedAt", out var lastGeneratedAt)
                ? DateTime.Parse(lastGeneratedAt.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
                : null,
            Scope = item.TryGetValue("Scope", out var scope)
                ? Enum.Parse<RecordScope>(scope.S)
                : RecordScope.Personal,
            FamilySpaceId = item.TryGetValue("FamilySpaceId", out var familySpaceId)
                && Guid.TryParse(familySpaceId.S, out var parsedFamilySpaceId)
                    ? parsedFamilySpaceId
                    : null,
            SharedAt = item.TryGetValue("SharedAt", out var sharedAt)
                && DateTime.TryParse(sharedAt.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsedSharedAt)
                    ? parsedSharedAt
                    : null,
            SharedByUserId = item.TryGetValue("SharedByUserId", out var sharedByUserId)
                && Guid.TryParse(sharedByUserId.S, out var parsedSharedByUserId)
                    ? parsedSharedByUserId
                    : null,
        };
    }
}
