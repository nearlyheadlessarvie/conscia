using System.Globalization;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class MonthlyCategorySpendRepository : IMonthlyCategorySpendRepository
{
    private const string TableName = "MonthlyCategorySpends";
    private readonly IAmazonDynamoDB _dynamo;

    public MonthlyCategorySpendRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task UpsertAsync(MonthlyCategorySpend projection, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(projection),
        }, ct);
    }

    public Task<IReadOnlyList<MonthlyCategorySpend>> ListRecentMonthsAsync(
        Guid userId,
        IReadOnlyList<string> monthKeys,
        CancellationToken ct = default) =>
        throw new NotImplementedException();

    private static Dictionary<string, AttributeValue> ToItem(MonthlyCategorySpend projection) =>
        new()
        {
            ["PK"] = new($"USER#{projection.UserId}"),
            ["SK"] = new($"MONTH#{projection.MonthKey}#CAT#{projection.NormalizedCategory}"),
            ["UserId"] = new(projection.UserId.ToString()),
            ["MonthKey"] = new(projection.MonthKey),
            ["Category"] = new(projection.Category),
            ["NormalizedCategory"] = new(projection.NormalizedCategory),
            ["CurrencyCode"] = new(projection.CurrencyCode),
            ["TotalExpenseAmount"] = new() { N = projection.TotalExpenseAmount.ToString("G", CultureInfo.InvariantCulture) },
            ["TransactionCount"] = new() { N = projection.TransactionCount.ToString(CultureInfo.InvariantCulture) },
            ["LastUpdatedAt"] = new(projection.LastUpdatedAt.ToString("O")),
        };
}
