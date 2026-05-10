using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class BehavioralInsightsServiceTests
{
    private readonly Mock<IWeeklyInsightsRepository> _insightsRepositoryMock = new();
    private readonly Mock<ITransactionRepository> _transactionRepositoryMock = new();
    private readonly Mock<IBudgetRepository> _budgetRepositoryMock = new();
    private readonly Mock<IMonthlyCategorySpendRepository> _monthlyCategorySpendRepositoryMock = new();
    private readonly BehavioralInsightsService _service;

    public BehavioralInsightsServiceTests()
    {
        _service = new BehavioralInsightsService(
            _insightsRepositoryMock.Object,
            _transactionRepositoryMock.Object,
            _budgetRepositoryMock.Object,
            _monthlyCategorySpendRepositoryMock.Object);
        _budgetRepositoryMock
            .Setup(x => x.ListByUserAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<Budget>());
        _monthlyCategorySpendRepositoryMock
            .Setup(x => x.ListRecentMonthsAsync(It.IsAny<Guid>(), It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<MonthlyCategorySpend>());
    }

    [Fact]
    public async Task GetBehavioralInsightsAsync_ReturnsNull_WhenNoInsights()
    {
        var userId = Guid.NewGuid();
        _insightsRepositoryMock
            .Setup(x => x.GetLatestByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((WeeklyInsights?)null);

        var result = await _service.GetBehavioralInsightsAsync(userId);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetBehavioralInsightsAsync_ReturnsInsights_WhenAvailable()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var insights = new WeeklyInsights
        {
            UserId = userId,
            WeekStartDate = DateTime.UtcNow.AddDays(-7),
            Mood = FinancialMood.Confident,
            WorthItPercentage = 80.0,
            WorthItCount = 8,
            TotalTransactionCount = 10,
            ImpulseTrends = new List<CategoryTrend>
            {
                new() { Category = "Coffee", RegretRate = 0.3, TransactionCount = 5, Trend = TrendDirection.Worsening }
            }
        };

        _insightsRepositoryMock
            .Setup(x => x.GetLatestByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(insights);

        // Act
        var result = await _service.GetBehavioralInsightsAsync(userId);

        // Assert
        Assert.Equal(FinancialMood.Confident, result.Mood);
        Assert.Equal(80.0, result.WorthItPercentage);
        Assert.Equal(8, result.WorthItCount);
        Assert.Single(result.ImpulseeTrends);
        Assert.Equal("Coffee", result.ImpulseeTrends[0].Category);
    }

    [Fact]
    public async Task GetBehavioralInsightsAsync_AppendsBudgetTrends_ForBudgetedAndUnbudgetedCategories()
    {
        var userId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var latestInsights = new WeeklyInsights
        {
            UserId = userId,
            WeekStartDate = now.AddDays(-7),
            Mood = FinancialMood.Balanced,
            WorthItPercentage = 72.0,
            WorthItCount = 9,
            TotalTransactionCount = 12,
            ImpulseTrends = []
        };

        _insightsRepositoryMock
            .Setup(x => x.GetLatestByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(latestInsights);
        _insightsRepositoryMock
            .Setup(x => x.GetByUserIdAndWeekAsync(userId, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((WeeklyInsights?)null);
        _budgetRepositoryMock
            .Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(
            [
                new Budget
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Dining",
                    MonthlyLimit = 1000m,
                    CurrencyCode = "PHP"
                }
            ]);
        _monthlyCategorySpendRepositoryMock
            .Setup(x => x.ListRecentMonthsAsync(userId, It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(
            [
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-03",
                    Category = "Dining",
                    NormalizedCategory = "dining",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 500m,
                    TransactionCount = 2,
                    LastUpdatedAt = now
                },
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-04",
                    Category = "Dining",
                    NormalizedCategory = "dining",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 600m,
                    TransactionCount = 3,
                    LastUpdatedAt = now
                },
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-05",
                    Category = "Dining",
                    NormalizedCategory = "dining",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 750m,
                    TransactionCount = 4,
                    LastUpdatedAt = now
                },
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-03",
                    Category = "Subscriptions",
                    NormalizedCategory = "subscriptions",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 100m,
                    TransactionCount = 1,
                    LastUpdatedAt = now
                },
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-04",
                    Category = "Subscriptions",
                    NormalizedCategory = "subscriptions",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 120m,
                    TransactionCount = 1,
                    LastUpdatedAt = now
                },
                new MonthlyCategorySpend
                {
                    UserId = userId,
                    MonthKey = "2026-05",
                    Category = "Subscriptions",
                    NormalizedCategory = "subscriptions",
                    CurrencyCode = "PHP",
                    TotalExpenseAmount = 140m,
                    TransactionCount = 1,
                    LastUpdatedAt = now
                }
            ]);

        var result = await _service.GetBehavioralInsightsAsync(userId);

        Assert.NotNull(result);
        Assert.Equal(2, result!.BudgetTrends.Count);

        var dining = result.BudgetTrends.Single(trend => trend.Category == "Dining");
        Assert.True(dining.HasBudget);
        Assert.Equal([50m, 60m, 75m], dining.Months);
        Assert.Equal(75m, dining.CurrentMonthPercentUsed);

        var subscriptions = result.BudgetTrends.Single(trend => trend.Category == "Subscriptions");
        Assert.False(subscriptions.HasBudget);
        Assert.Equal([100m, 120m, 140m], subscriptions.Months);
        Assert.Equal("Add a budget for sharper insights", subscriptions.Nudge);
    }

    [Fact]
    public async Task CalculateAndStoreWeeklyInsightsAsync_CalculatesMoodCorrectly()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var weekStart = new DateTime(2024, 1, 1); // Monday
        var transactions = new List<Transaction>
        {
            new() { Id = Guid.NewGuid(), UserId = userId, Date = weekStart.AddDays(1), Amount = new Money(10, "USD"), Category = "Coffee", RegretLevel = RegretLevel.WorthIt },
            new() { Id = Guid.NewGuid(), UserId = userId, Date = weekStart.AddDays(2), Amount = new Money(20, "USD"), Category = "Coffee", RegretLevel = RegretLevel.Regret },
            new() { Id = Guid.NewGuid(), UserId = userId, Date = weekStart.AddDays(3), Amount = new Money(30, "USD"), Category = "Dining", RegretLevel = RegretLevel.WorthIt },
            new() { Id = Guid.NewGuid(), UserId = userId, Date = weekStart.AddDays(4), Amount = new Money(40, "USD"), Category = "Dining", RegretLevel = RegretLevel.Regret },
        };

        _transactionRepositoryMock
            .Setup(x => x.GetByUserIdAndDateRangeAsync(userId, weekStart, weekStart.AddDays(7), It.IsAny<CancellationToken>()))
            .ReturnsAsync(transactions);

        // Act
        await _service.CalculateAndStoreWeeklyInsightsAsync(userId, weekStart);

        // Assert
        _insightsRepositoryMock.Verify(x => x.UpsertAsync(It.Is<WeeklyInsights>(insights =>
            insights.UserId == userId &&
            insights.WeekStartDate == weekStart &&
            insights.Mood == FinancialMood.Cautious && // 50% worth it (2/4) -> Cautious (40-59%)
            insights.WorthItPercentage == 50.0 &&
            insights.WorthItCount == 2 &&
            insights.TotalTransactionCount == 4 &&
            insights.ImpulseTrends.Count == 2), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CalculateAndStoreWeeklyInsightsAsync_Skips_WhenNoTransactions()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var weekStart = new DateTime(2024, 1, 1);

        _transactionRepositoryMock
            .Setup(x => x.GetByUserIdAndDateRangeAsync(userId, weekStart, weekStart.AddDays(7), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction>());

        // Act
        await _service.CalculateAndStoreWeeklyInsightsAsync(userId, weekStart);

        // Assert
        _insightsRepositoryMock.Verify(x => x.UpsertAsync(It.IsAny<WeeklyInsights>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}
