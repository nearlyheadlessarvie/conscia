using Conscia.Domain.Constants;

namespace Conscia.Tests.Unit.Domain;

public class SupportedCurrenciesTests
{
    [Fact]
    public void Codes_IsNotEmpty() =>
        Assert.NotEmpty(SupportedCurrencies.Codes);

    [Fact]
    public void Codes_AllAreThreeCharacters() =>
        Assert.All(SupportedCurrencies.Codes, c => Assert.Equal(3, c.Length));

    [Fact]
    public void Codes_AllAreUpperCase() =>
        Assert.All(SupportedCurrencies.Codes, c => Assert.Equal(c, c.ToUpperInvariant()));

    [Fact]
    public void Codes_ContainsCommonCurrencies()
    {
        Assert.Contains("USD", SupportedCurrencies.Codes);
        Assert.Contains("EUR", SupportedCurrencies.Codes);
        Assert.Contains("GBP", SupportedCurrencies.Codes);
        Assert.Contains("JPY", SupportedCurrencies.Codes);
    }

    [Fact]
    public void Codes_NoDuplicates() =>
        Assert.Equal(SupportedCurrencies.Codes.Count, SupportedCurrencies.Codes.Distinct().Count());
}
