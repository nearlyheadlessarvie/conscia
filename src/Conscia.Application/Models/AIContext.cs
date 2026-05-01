namespace Conscia.Application.Models;

public class AIContext
{
    public Guid UserId { get; set; }
    public decimal? BudgetPercentUsed { get; set; }
    public string? Category { get; set; }
    public decimal? Amount { get; set; }
    public string? CurrencyCode { get; set; }
    public string? Merchant { get; set; }
    public int RecentRegrets { get; set; }
    public int SpendingFrequencyThisWeek { get; set; }
}
