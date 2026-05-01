using System.Globalization;

namespace Conscia.Domain.ValueObjects;

public sealed class Money : IEquatable<Money>
{
    private static readonly HashSet<string> ValidCurrencyCodes = new(
        CultureInfo.GetCultures(CultureTypes.SpecificCultures)
            .Select(c => new RegionInfo(c.Name))
            .Select(r => r.ISOCurrencySymbol)
            .Distinct(),
        StringComparer.OrdinalIgnoreCase);

    public decimal Amount { get; }
    public string CurrencyCode { get; }
    public decimal? ExchangeRateToBase { get; }

    public Money(decimal amount, string currencyCode, decimal? exchangeRateToBase = null)
    {
        if (string.IsNullOrWhiteSpace(currencyCode))
            throw new ArgumentException("Currency code is required.", nameof(currencyCode));

        currencyCode = currencyCode.ToUpperInvariant();

        if (currencyCode.Length != 3)
            throw new ArgumentException("Currency code must be 3 characters (ISO 4217).", nameof(currencyCode));

        if (!ValidCurrencyCodes.Contains(currencyCode))
            throw new ArgumentException($"Unknown currency code: {currencyCode}", nameof(currencyCode));

        if (exchangeRateToBase.HasValue && exchangeRateToBase.Value <= 0)
            throw new ArgumentException("Exchange rate must be positive.", nameof(exchangeRateToBase));

        Amount = amount;
        CurrencyCode = currencyCode;
        ExchangeRateToBase = exchangeRateToBase;
    }

    public decimal? ConvertedAmount =>
        ExchangeRateToBase.HasValue ? Amount * ExchangeRateToBase.Value : null;

    public string ToString(CultureInfo culture)
    {
        var region = new RegionInfo(culture.Name);
        return Amount.ToString("C", culture);
    }

    public override string ToString() =>
        $"{Amount:F2} {CurrencyCode}";

    /// <summary>
    /// Equality is based on Amount + CurrencyCode only. ExchangeRateToBase is contextual
    /// metadata (varies by day, user's base currency) and does not define the monetary value.
    /// "100 MXN" is the same value regardless of its USD exchange rate.
    /// </summary>
    public bool Equals(Money? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return Amount == other.Amount && CurrencyCode == other.CurrencyCode;
    }

    public override bool Equals(object? obj) => Equals(obj as Money);

    public override int GetHashCode() => HashCode.Combine(Amount, CurrencyCode);

    public static bool operator ==(Money? left, Money? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(Money? left, Money? right) => !(left == right);

    public static Money operator +(Money left, Money right)
    {
        if (left.CurrencyCode != right.CurrencyCode)
            throw new InvalidOperationException(
                $"Cannot add {left.CurrencyCode} and {right.CurrencyCode}. Convert first.");

        return new Money(left.Amount + right.Amount, left.CurrencyCode);
    }

    public static Money operator -(Money left, Money right)
    {
        if (left.CurrencyCode != right.CurrencyCode)
            throw new InvalidOperationException(
                $"Cannot subtract {left.CurrencyCode} from {right.CurrencyCode}. Convert first.");

        return new Money(left.Amount - right.Amount, left.CurrencyCode);
    }
}
