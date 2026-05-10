namespace Conscia.Application.Models;

public class BudgetTrendInsight
{
    public string Category { get; set; } = string.Empty;
    public bool HasBudget { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public IReadOnlyList<decimal> Months { get; set; } = [];
    public decimal CurrentMonthSpend { get; set; }
    public decimal? CurrentMonthPercentUsed { get; set; }
    public string InsightLabel { get; set; } = string.Empty;
    public string? Nudge { get; set; }
}
