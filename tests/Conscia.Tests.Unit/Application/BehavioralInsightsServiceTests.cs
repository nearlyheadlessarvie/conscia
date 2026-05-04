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
    private readonly BehavioralInsightsService _service;

    public BehavioralInsightsServiceTests()
    {
        _service = new BehavioralInsightsService(
            _insightsRepositoryMock.Object,
            _transactionRepositoryMock.Object);
    }

    [Fact]
    public async Task GetBehavioralInsightsAsync_ReturnsDefault_WhenNoInsights()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _insightsRepositoryMock
            .Setup(x => x.GetLatestByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((WeeklyInsights?)null);

        // Act
        var result = await _service.GetBehavioralInsightsAsync(userId);

        // Assert
        Assert.Equal(FinancialMood.Balanced, result.Mood);
        Assert.Equal(50.0, result.WorthItPercentage);
        Assert.Equal(0, result.WorthItCount);
        Assert.Equal(0, result.PreviousMonthWorthItCount);
        Assert.Empty(result.ImpulseeTrends);
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