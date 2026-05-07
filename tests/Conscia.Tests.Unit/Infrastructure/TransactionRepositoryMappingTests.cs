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
            Counterparty = "Cafe",
            Date = originalDate,
            CreatedAt = originalDate,
        };

        var item = InvokeToItem(transaction);

        Assert.Equal($"DATE#{originalDate:O}#TX#{transactionId}", item["SK"].S);
    }

    [Fact]
    public void FromItem_ReadsNewCounterpartyAndPlaceNameKeys()
    {
        var transactionId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var date = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc);
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new($"DATE#{date:O}#TX#{transactionId}"),
            ["Id"] = new(transactionId.ToString()),
            ["UserId"] = new(userId.ToString()),
            ["Type"] = new(TransactionType.Expense.ToString()),
            ["Amount"] = new() { N = "42.5" },
            ["CurrencyCode"] = new("USD"),
            ["Category"] = new("Coffee"),
            ["Counterparty"] = new("Cafe"),
            ["Date"] = new(date.ToString("O")),
            ["CreatedAt"] = new(date.ToString("O")),
            ["Location"] = new(System.Text.Json.JsonSerializer.Serialize(new Location
            {
                Latitude = 14.55,
                Longitude = 121.02,
                PlaceName = "Coffee Shop"
            })),
        };

        var transaction = InvokeFromItem(item);

        Assert.Equal("Cafe", transaction.Counterparty);
        Assert.NotNull(transaction.Location);
        Assert.Equal("Coffee Shop", transaction.Location!.PlaceName);
    }

    [Fact]
    public void FromItem_FallsBackToLegacyMerchantAndMerchantNameKeys()
    {
        var transactionId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var date = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc);
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new($"DATE#{date:O}#TX#{transactionId}"),
            ["Id"] = new(transactionId.ToString()),
            ["UserId"] = new(userId.ToString()),
            ["Type"] = new(TransactionType.Expense.ToString()),
            ["Amount"] = new() { N = "42.5" },
            ["CurrencyCode"] = new("USD"),
            ["Category"] = new("Coffee"),
            ["Merchant"] = new("Legacy Cafe"),
            ["Date"] = new(date.ToString("O")),
            ["CreatedAt"] = new(date.ToString("O")),
            ["Location"] = new("{\"Latitude\":14.55,\"Longitude\":121.02,\"MerchantName\":\"Legacy Shop\"}"),
        };

        var transaction = InvokeFromItem(item);

        Assert.Equal("Legacy Cafe", transaction.Counterparty);
        Assert.NotNull(transaction.Location);
        Assert.Equal("Legacy Shop", transaction.Location!.PlaceName);
    }

    [Fact]
    public void ToItem_WritesOnlyCounterpartyAndPlaceNameKeys()
    {
        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Type = TransactionType.Expense,
            Amount = new Money(42.5m, "USD"),
            Category = "Coffee",
            Counterparty = "Cafe",
            Date = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc),
            CreatedAt = new DateTime(2026, 05, 07, 14, 23, 45, DateTimeKind.Utc),
            Location = new Location
            {
                Latitude = 14.55,
                Longitude = 121.02,
                PlaceName = "Coffee Shop"
            }
        };

        var item = InvokeToItem(transaction);

        Assert.True(item.ContainsKey("Counterparty"));
        Assert.False(item.ContainsKey("Merchant"));
        Assert.Contains("\"PlaceName\":\"Coffee Shop\"", item["Location"].S);
        Assert.DoesNotContain("\"MerchantName\":", item["Location"].S);
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
