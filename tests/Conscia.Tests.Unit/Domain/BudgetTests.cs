using Conscia.Domain.Entities;

namespace Conscia.Tests.Unit.Domain;

public class BudgetTests
{
    [Fact]
    public void PercentUsed_CalculatesCorrectly()
    {
        var budget = new Budget { MonthlyLimit = 200m, CurrentSpend = 160m };
        Assert.Equal(80m, budget.PercentUsed);
    }

    [Fact]
    public void PercentUsed_ZeroLimit_ReturnsZero()
    {
        var budget = new Budget { MonthlyLimit = 0m, CurrentSpend = 50m };
        Assert.Equal(0m, budget.PercentUsed);
    }

    [Fact]
    public void IsOverBudget_WhenOver_ReturnsTrue()
    {
        var budget = new Budget { MonthlyLimit = 100m, CurrentSpend = 150m };
        Assert.True(budget.IsOverBudget);
    }

    [Fact]
    public void IsOverBudget_WhenUnder_ReturnsFalse()
    {
        var budget = new Budget { MonthlyLimit = 100m, CurrentSpend = 50m };
        Assert.False(budget.IsOverBudget);
    }

    [Fact]
    public void IsOverBudget_WhenEqual_ReturnsFalse()
    {
        var budget = new Budget { MonthlyLimit = 100m, CurrentSpend = 100m };
        Assert.False(budget.IsOverBudget);
    }
}
