namespace Conscia.Domain.Entities;

public class MonthlyCategorySpend
{
    public Guid UserId { get; set; }
    public string MonthKey { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string NormalizedCategory { get; set; } = string.Empty;
    public string CurrencyCode { get; set; } = "USD";
    public decimal TotalExpenseAmount { get; set; }
    public int TransactionCount { get; set; }
    public DateTime LastUpdatedAt { get; set; }
}
