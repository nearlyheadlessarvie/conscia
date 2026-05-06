using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchasePatternServiceTests
{
    private readonly Mock<IPurchasePatternRepository> _repoMock = new();
    private readonly Mock<ITransactionRepository> _txRepoMock = new();
    private readonly PurchasePatternService _svc;

    public PurchasePatternServiceTests()
        => _svc = new PurchasePatternService(_repoMock.Object, _txRepoMock.Object);

    [Fact]
    public async Task GetSummaryAsync_ReturnsNull_WhenNoPatterns()
    {
        _repoMock.Setup(r => r.GetSummaryAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((PurchasePatternSummary?)null);

        var result = await _svc.GetSummaryAsync(Guid.NewGuid());

        Assert.Null(result);
    }

    [Fact]
    public async Task GetSummaryAsync_ReturnsMappedDto_WhenPatternExists()
    {
        var userId = Guid.NewGuid();
        _repoMock.Setup(r => r.GetSummaryAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PurchasePatternSummary
            {
                UserId = userId,
                RegrettedAmount = 120m,
                RegrettedCategory = "Gaming",
                AvgRegretRate = 0.65,
                PatternCount = 3,
                UpdatedAt = DateTime.UtcNow
            });

        var result = await _svc.GetSummaryAsync(userId);

        Assert.NotNull(result);
        Assert.Equal(120m, result!.RegrettedAmount);
        Assert.Equal("Gaming", result.RegrettedCategory);
        Assert.Equal(3, result.PatternCount);
    }

    [Fact]
    public async Task GetCategoryDetailAsync_ReturnsNull_WhenNotFound()
    {
        _repoMock.Setup(r => r.GetCategoriesAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryPattern>());

        var result = await _svc.GetCategoryDetailAsync(Guid.NewGuid(), "Gaming");

        Assert.Null(result);
    }

    [Fact]
    public async Task GetCategoryDetailAsync_ReturnsStatsAndTransactions_WhenFound()
    {
        var userId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        _repoMock.Setup(r => r.GetCategoriesAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryPattern>
            {
                new() { UserId = userId, Category = "Gaming", TotalSpend = 200m,
                        RegrettedSpend = 140m, RegretRate = 0.70, TransactionCount = 5,
                        ProjectedAnnual = 1706m, UpdatedAt = now }
            });

        _txRepoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction>
            {
                new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(50m, "USD"),
                        Category = "Gaming", Date = now, RegretLevel = RegretLevel.Regret },
                new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(30m, "USD"),
                        Category = "Food", Date = now }
            });

        var result = await _svc.GetCategoryDetailAsync(userId, "Gaming");

        Assert.NotNull(result);
        Assert.Equal("Gaming", result!.Stats.Category);
        Assert.Single(result.RecentTransactions); // only "Gaming" transactions
    }
}
