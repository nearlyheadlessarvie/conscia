using System.Reflection;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tests.Unit.Infrastructure;

public class TransactionRepositoryMappingTests
{
    [Fact]
    public void FromItem_PrefersTimestampFromSortKey_WhenDateFieldIsDateOnly()
    {
        var transactionId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var originalDate = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc);
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new($"DATE#{originalDate:O}#TX#{transactionId}"),
            ["Id"] = new(transactionId.ToString()),
            ["UserId"] = new(userId.ToString()),
            ["Type"] = new(TransactionType.Expense.ToString()),
            ["Amount"] = new() { N = "42.5" },
            ["CurrencyCode"] = new("USD"),
            ["Category"] = new("Coffee"),
            ["Date"] = new("2026-05-07"),
            ["CreatedAt"] = new(originalDate.ToString("O")),
        };

        var transaction = InvokeFromItem(item);

        Assert.Equal(originalDate, transaction.Date);
    }

    [Fact]
    public void ToItem_PreservesOriginalTimestampInSortKey_AfterMerchantUpdate()
    {
        var transactionId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var originalDate = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc);
        var transaction = new Transaction
        {
            Id = transactionId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(42.5m, "USD"),
            Category = "Coffee",
            Merchant = "Cafe",
            Date = originalDate,
            CreatedAt = originalDate,
        };

        var item = InvokeToItem(transaction);

        Assert.Equal($"DATE#{originalDate:O}#TX#{transactionId}", item["SK"].S);
    }

    private static Transaction InvokeFromItem(Dictionary<string, AttributeValue> item)
    {
        var method = typeof(TransactionRepository).GetMethod(
            "FromItem",
            BindingFlags.NonPublic | BindingFlags.Static);

        Assert.NotNull(method);
        return (Transaction)method!.Invoke(null, [item])!;
    }

    private static Dictionary<string, AttributeValue> InvokeToItem(Transaction transaction)
    {
        var method = typeof(TransactionRepository).GetMethod(
            "ToItem",
            BindingFlags.NonPublic | BindingFlags.Static);

        Assert.NotNull(method);
        return (Dictionary<string, AttributeValue>)method!.Invoke(null, [transaction])!;
    }
}
