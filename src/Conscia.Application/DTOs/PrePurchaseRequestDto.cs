namespace Conscia.Application.DTOs;

public class PrePurchaseRequestDto
{
    public string Description { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string ContextScope { get; set; } = "personal";
    public string? InsightContext { get; set; }
}
