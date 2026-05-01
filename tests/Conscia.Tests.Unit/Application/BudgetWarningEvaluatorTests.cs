using Conscia.Application.Interfaces;
using Conscia.Application.Triggers;
using Conscia.Domain.Entities;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class BudgetWarningEvaluatorTests
{
    private readonly Mock<IBudgetService> _budgetServiceMock = new();
    private readonly BudgetWarningEvaluator _evaluator;

    public BudgetWarningEvaluatorTests()
    {
        _evaluator = new BudgetWarningEvaluator(_budgetServiceMock.Object);
    }

    [Fact]
    public void TriggerName_IsBudgetWarning()
    {
        Assert.Equal("BudgetWarning", _evaluator.TriggerName);
    }

    [Fact]
    public async Task Evaluate_At80Percent_ReturnsSingleAlert()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Food", MonthlyLimit = 100m, CurrentSpend = 80m, CurrencyCode = "USD" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Single(alerts);
        Assert.Equal("BudgetWarning", alerts[0].TriggerName);
        Assert.Contains("Food", alerts[0].Title);
        Assert.Contains("80%", alerts[0].Message);
    }

    [Fact]
    public async Task Evaluate_Above80Percent_ReturnsAlert()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Entertainment", MonthlyLimit = 200m, CurrentSpend = 190m, CurrencyCode = "EUR" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Single(alerts);
        Assert.Contains("95%", alerts[0].Message);
    }

    [Fact]
    public async Task Evaluate_Below80Percent_ReturnsEmpty()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Food", MonthlyLimit = 100m, CurrentSpend = 50m, CurrencyCode = "USD" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Empty(alerts);
    }

    [Fact]
    public async Task Evaluate_ZeroLimit_ReturnsEmpty()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Food", MonthlyLimit = 0m, CurrentSpend = 50m, CurrencyCode = "USD" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Empty(alerts);
    }

    [Fact]
    public async Task Evaluate_NoBudgets_ReturnsEmpty()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>());

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Empty(alerts);
    }

    [Fact]
    public async Task Evaluate_MultipleBudgetsTriggered_ReturnsAll()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Food", MonthlyLimit = 100m, CurrentSpend = 90m, CurrencyCode = "USD" },
                new() { Category = "Transport", MonthlyLimit = 50m, CurrentSpend = 45m, CurrencyCode = "USD" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Equal(2, alerts.Count);
        Assert.Contains(alerts, a => a.Title.Contains("Food"));
        Assert.Contains(alerts, a => a.Title.Contains("Transport"));
    }

    [Fact]
    public async Task Evaluate_MixedBudgets_ReturnsOnlyTriggered()
    {
        var userId = Guid.NewGuid();
        _budgetServiceMock.Setup(x => x.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Category = "Food", MonthlyLimit = 100m, CurrentSpend = 50m, CurrencyCode = "USD" },
                new() { Category = "Transport", MonthlyLimit = 50m, CurrentSpend = 45m, CurrencyCode = "USD" }
            });

        var alerts = await _evaluator.EvaluateAsync(userId);

        Assert.Single(alerts);
        Assert.Contains("Transport", alerts[0].Title);
    }
}
