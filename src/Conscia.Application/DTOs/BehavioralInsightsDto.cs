using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class BehavioralInsights
{
    public FinancialMood Mood { get; set; }
    public double WorthItPercentage { get; set; }
    public int WorthItCount { get; set; }
    public int PreviousMonthWorthItCount { get; set; }
    public List<CategoryTrend> ImpulseeTrends { get; set; } = new();
    public List<BudgetTrendInsight> BudgetTrends { get; set; } = new();
}
