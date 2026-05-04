using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Services;

public class BehavioralInsightsService : IBehavioralInsightsService
{
    private readonly IWeeklyInsightsRepository _insightsRepository;
    private readonly ITransactionRepository _transactionRepository;

    public BehavioralInsightsService(
        IWeeklyInsightsRepository insightsRepository,
        ITransactionRepository transactionRepository)
    {
        _insightsRepository = insightsRepository;
        _transactionRepository = transactionRepository;
    }

    public async Task<BehavioralInsights?> GetBehavioralInsightsAsync(Guid userId, CancellationToken ct = default)
    {
        // Get latest weekly insights
        var latestInsights = await _insightsRepository.GetLatestByUserIdAsync(userId, ct);

        if (latestInsights == null)
        {
            return null; // No insights available for user
        }

        // Get previous week's insights for comparison
        var previousWeek = latestInsights.WeekStartDate.AddDays(-7);
        var previousInsights = await _insightsRepository.GetByUserIdAndWeekAsync(userId, previousWeek, ct);

        return new BehavioralInsights
        {
            Mood = latestInsights.Mood,
            WorthItPercentage = latestInsights.WorthItPercentage,
            WorthItCount = latestInsights.WorthItCount,
            PreviousMonthWorthItCount = previousInsights?.WorthItCount ?? 0,
            ImpulseeTrends = latestInsights.ImpulseTrends
        };
    }

    public async Task CalculateAndStoreWeeklyInsightsAsync(Guid userId, DateTime weekStartDate, CancellationToken ct = default)
    {
        // Get transactions for the week
        var weekEndDate = weekStartDate.AddDays(7);
        var transactions = await _transactionRepository.GetByUserIdAndDateRangeAsync(
            userId, weekStartDate, weekEndDate, ct);

        if (!transactions.Any())
        {
            return; // No transactions to analyze
        }

        // Calculate worth-it percentage
        var worthItTransactions = transactions.Where(t => t.RegretLevel == RegretLevel.WorthIt).ToList();
        var worthItPercentage = transactions.Any()
            ? (double)worthItTransactions.Count / transactions.Count * 100.0
            : 0.0;

        // Determine mood based on worth-it percentage
        var mood = CalculateMood(worthItPercentage);

        // Calculate impulse trends by category
        var impulseTrends = CalculateImpulseTrends(transactions.ToList());

        var insights = new WeeklyInsights
        {
            UserId = userId,
            WeekStartDate = weekStartDate,
            Mood = mood,
            WorthItPercentage = worthItPercentage,
            WorthItCount = worthItTransactions.Count,
            TotalTransactionCount = transactions.Count,
            ImpulseTrends = impulseTrends
        };

        await _insightsRepository.UpsertAsync(insights, ct);
    }

    private static FinancialMood CalculateMood(double worthItPercentage)
    {
        return worthItPercentage switch
        {
            >= 80 => FinancialMood.Confident,
            >= 60 => FinancialMood.Balanced,
            >= 40 => FinancialMood.Cautious,
            _ => FinancialMood.Impulsive
        };
    }

    private static List<CategoryTrend> CalculateImpulseTrends(List<Transaction> transactions)
    {
        // Group transactions by category and calculate regret rates
        var categoryStats = transactions
            .Where(t => !string.IsNullOrEmpty(t.Category))
            .GroupBy(t => t.Category)
            .Select(g => new
            {
                Category = g.Key,
                TotalCount = g.Count(),
                RegretCount = g.Count(t => t.RegretLevel.HasValue && t.RegretLevel != RegretLevel.WorthIt),
                RegretRate = g.Any() ? (double)g.Count(t => t.RegretLevel.HasValue && t.RegretLevel != RegretLevel.WorthIt) / g.Count() : 0.0
            })
            .OrderByDescending(x => x.RegretRate)
            .Take(3) // Top 3 categories with highest regret rates
            .ToList();

        return categoryStats.Select(stat => new CategoryTrend
        {
            Category = stat.Category,
            RegretRate = stat.RegretRate,
            TransactionCount = stat.TotalCount,
            Trend = DetermineTrend(stat.RegretRate) // This would need historical data for real trend calculation
        }).ToList();
    }

    private static TrendDirection DetermineTrend(double currentRegretRate)
    {
        // For now, use a simple heuristic. In a real implementation,
        // this would compare with previous weeks' data
        return currentRegretRate switch
        {
            < 0.2 => TrendDirection.Improving,
            < 0.4 => TrendDirection.Steady,
            _ => TrendDirection.Worsening
        };
    }
}