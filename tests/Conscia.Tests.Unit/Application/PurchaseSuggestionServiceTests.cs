using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchaseSuggestionServiceTests
{
    private readonly Mock<ITransactionRepository> _repoMock = new();
    private readonly PurchaseSuggestionService _service;

    public PurchaseSuggestionServiceTests()
    {
        _service = new PurchaseSuggestionService(_repoMock.Object);
    }

    private static Transaction MakeTx(string merchant, decimal amount, int daysAgo = 1) => new()
    {
        Id = Guid.NewGuid(),
        UserId = Guid.NewGuid(),
        Counterparty = merchant,
        Category = "Coffee",
        Amount = new Money(amount, "USD"),
        Date = DateTime.UtcNow.AddDays(-daysAgo),
    };

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsEmpty_WhenUnderThreshold()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 9).Select(i => MakeTx($"item{i}", 5m)).ToList();
        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Empty(result);
    }

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsSuggestions_WhenThresholdMet()
    {
        var userId = Guid.NewGuid();
        var txs = new List<Transaction>();
        // 10 total, 3 with same merchant
        for (int i = 0; i < 7; i++) txs.Add(MakeTx($"unique{i}", 10m));
        txs.Add(MakeTx("Starbucks", 6.50m, 1));
        txs.Add(MakeTx("Starbucks", 7.00m, 3));
        txs.Add(MakeTx("Starbucks", 6.50m, 5));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Single(result);
        Assert.Equal("Starbucks", result[0].Description);
    }

    [Fact]
    public async Task GetSuggestionsAsync_UsesMedianAmount()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Coffee Shop", 5m, 1));
        txs.Add(MakeTx("Coffee Shop", 7m, 2));
        txs.Add(MakeTx("Coffee Shop", 9m, 3));  // median = 7

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Equal(7m, result[0].Amount);
    }

    [Fact]
    public async Task GetSuggestionsAsync_SetsThisWeekLabel_WhenRecentTransaction()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Lunch Spot", 12m, 1));  // within 7 days
        txs.Add(MakeTx("Lunch Spot", 12m, 2));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Contains("this week", result[0].FrequencyLabel);
    }

    [Fact]
    public async Task GetSuggestionsAsync_SetsThisMonthLabel_WhenOlderTransaction()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Old Place", 10m, 20));  // older than 7 days
        txs.Add(MakeTx("Old Place", 10m, 25));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Contains("this month", result[0].FrequencyLabel);
    }

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsMaxFive()
    {
        var userId = Guid.NewGuid();
        var txs = new List<Transaction>();
        for (int i = 0; i < 8; i++) txs.Add(MakeTx($"pad{i}", 1m));
        for (int i = 0; i < 8; i++)
        {
            txs.Add(MakeTx($"Merchant{i}", 5m, 1));
            txs.Add(MakeTx($"Merchant{i}", 5m, 2));
        }

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Equal(5, result.Count);
    }
}
