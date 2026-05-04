using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class WeeklyInsights
{
    public Guid UserId { get; set; }
    public DateTime WeekStartDate { get; set; }
    public FinancialMood Mood { get; set; }
    public double WorthItPercentage { get; set; }
    public int WorthItCount { get; set; }
    public int TotalTransactionCount { get; set; }
    public List<CategoryTrend> ImpulseTrends { get; set; } = new();
}

public class CategoryTrend
{
    public string Category { get; set; } = string.Empty;
    public double RegretRate { get; set; }
    public int TransactionCount { get; set; }
    public TrendDirection Trend { get; set; }
}