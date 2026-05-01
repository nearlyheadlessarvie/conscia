using Conscia.Domain.ValueObjects;
using System.Globalization;

namespace Conscia.Tests.Unit.Domain;

public class MoneyTests
{
    [Fact]
    public void Constructor_ValidInput_CreatesMoney()
    {
        var money = new Money(100.50m, "USD");

        Assert.Equal(100.50m, money.Amount);
        Assert.Equal("USD", money.CurrencyCode);
        Assert.Null(money.ExchangeRateToBase);
    }

    [Fact]
    public void Constructor_WithExchangeRate_SetsRate()
    {
        var money = new Money(1000m, "MXN", 0.058m);

        Assert.Equal(0.058m, money.ExchangeRateToBase);
        Assert.Equal(58.0m, money.ConvertedAmount);
    }

    [Fact]
    public void Constructor_NormalizesToUpperCase()
    {
        var money = new Money(50m, "usd");
        Assert.Equal("USD", money.CurrencyCode);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("  ")]
    public void Constructor_NullOrEmptyCurrency_Throws(string? currency)
    {
        Assert.Throws<ArgumentException>(() => new Money(100m, currency!));
    }

    [Theory]
    [InlineData("US")]
    [InlineData("USDD")]
    public void Constructor_InvalidLengthCurrency_Throws(string currency)
    {
        Assert.Throws<ArgumentException>(() => new Money(100m, currency));
    }

    [Fact]
    public void Constructor_UnknownCurrency_Throws()
    {
        Assert.Throws<ArgumentException>(() => new Money(100m, "ZZZ"));
    }

    [Fact]
    public void Constructor_NegativeExchangeRate_Throws()
    {
        Assert.Throws<ArgumentException>(() => new Money(100m, "USD", -1.0m));
    }

    [Fact]
    public void Constructor_ZeroExchangeRate_Throws()
    {
        Assert.Throws<ArgumentException>(() => new Money(100m, "USD", 0m));
    }

    [Fact]
    public void Equality_SameAmountAndCurrency_AreEqual()
    {
        var a = new Money(100m, "USD");
        var b = new Money(100m, "USD");

        Assert.Equal(a, b);
        Assert.True(a == b);
        Assert.False(a != b);
        Assert.Equal(a.GetHashCode(), b.GetHashCode());
    }

    [Fact]
    public void Equality_DifferentAmount_AreNotEqual()
    {
        var a = new Money(100m, "USD");
        var b = new Money(200m, "USD");

        Assert.NotEqual(a, b);
    }

    [Fact]
    public void Equality_DifferentCurrency_AreNotEqual()
    {
        var a = new Money(100m, "USD");
        var b = new Money(100m, "EUR");

        Assert.NotEqual(a, b);
    }

    [Fact]
    public void Addition_SameCurrency_AddsAmounts()
    {
        var a = new Money(100m, "USD");
        var b = new Money(50m, "USD");

        var result = a + b;

        Assert.Equal(150m, result.Amount);
        Assert.Equal("USD", result.CurrencyCode);
    }

    [Fact]
    public void Addition_DifferentCurrency_Throws()
    {
        var a = new Money(100m, "USD");
        var b = new Money(50m, "EUR");

        Assert.Throws<InvalidOperationException>(() => a + b);
    }

    [Fact]
    public void Subtraction_SameCurrency_SubtractsAmounts()
    {
        var a = new Money(100m, "USD");
        var b = new Money(30m, "USD");

        var result = a - b;

        Assert.Equal(70m, result.Amount);
    }

    [Fact]
    public void Subtraction_DifferentCurrency_Throws()
    {
        var a = new Money(100m, "USD");
        var b = new Money(30m, "EUR");

        Assert.Throws<InvalidOperationException>(() => a - b);
    }

    [Fact]
    public void ToString_ReturnsAmountAndCurrency()
    {
        var money = new Money(99.99m, "EUR");
        Assert.Equal("99.99 EUR", money.ToString());
    }

    [Fact]
    public void ConvertedAmount_WithoutRate_ReturnsNull()
    {
        var money = new Money(100m, "USD");
        Assert.Null(money.ConvertedAmount);
    }

    [Fact]
    public void NegativeAmount_IsAllowed()
    {
        var money = new Money(-50m, "USD");
        Assert.Equal(-50m, money.Amount);
    }

    [Fact]
    public void ZeroAmount_IsAllowed()
    {
        var money = new Money(0m, "USD");
        Assert.Equal(0m, money.Amount);
    }
}
