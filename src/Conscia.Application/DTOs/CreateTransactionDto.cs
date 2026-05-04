using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class CreateTransactionDto
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Merchant { get; set; }
    public DateTime Date { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? MerchantName { get; set; }
    public decimal? ExchangeRateToBase { get; set; }
    /// <summary>User's preferred currency. Used to auto-fetch exchange rate when CurrencyCode differs.</summary>
    public string? BaseCurrencyCode { get; set; }
    /// <summary>Client-provided rate override. When set, skips API fetch.</summary>
    public decimal? ExchangeRateOverride { get; set; }
}
