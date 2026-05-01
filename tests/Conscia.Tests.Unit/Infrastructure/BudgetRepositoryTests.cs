using Conscia.Domain.Entities;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tests.Unit.Infrastructure;

public class BudgetRepositoryTests : EfCoreTestBase
{
    private readonly BudgetRepository _repo;

    public BudgetRepositoryTests() => _repo = new BudgetRepository(Db);

    [Fact]
    public async Task Add_CreatesBudget()
    {
        var budget = new Budget
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Category = "Food",
            MonthlyLimit = 500m,
            CurrencyCode = "USD"
        };

        var result = await _repo.AddAsync(budget);

        Assert.Equal(budget.Id, result.Id);
        Assert.Equal("Food", result.Category);
    }

    [Fact]
    public async Task ListByUser_ReturnsOnlyUserBudgets()
    {
        var userId1 = Guid.NewGuid();
        var userId2 = Guid.NewGuid();

        await _repo.AddAsync(new Budget { Id = Guid.NewGuid(), UserId = userId1, Category = "Food", MonthlyLimit = 100m, CurrencyCode = "USD" });
        await _repo.AddAsync(new Budget { Id = Guid.NewGuid(), UserId = userId1, Category = "Transport", MonthlyLimit = 50m, CurrencyCode = "USD" });
        await _repo.AddAsync(new Budget { Id = Guid.NewGuid(), UserId = userId2, Category = "Food", MonthlyLimit = 200m, CurrencyCode = "EUR" });

        var budgets = await _repo.ListByUserAsync(userId1);

        Assert.Equal(2, budgets.Count);
        Assert.All(budgets, b => Assert.Equal(userId1, b.UserId));
    }

    [Fact]
    public async Task Update_ModifiesBudget()
    {
        var budget = new Budget { Id = Guid.NewGuid(), UserId = Guid.NewGuid(), Category = "Food", MonthlyLimit = 100m, CurrencyCode = "USD" };
        await _repo.AddAsync(budget);

        budget.MonthlyLimit = 200m;
        await _repo.UpdateAsync(budget);

        var found = await _repo.GetByIdAsync(budget.Id);
        Assert.Equal(200m, found!.MonthlyLimit);
    }

    [Fact]
    public async Task Delete_RemovesBudget()
    {
        var budget = new Budget { Id = Guid.NewGuid(), UserId = Guid.NewGuid(), Category = "Food", MonthlyLimit = 100m, CurrencyCode = "USD" };
        await _repo.AddAsync(budget);

        await _repo.DeleteAsync(budget.Id);

        var found = await _repo.GetByIdAsync(budget.Id);
        Assert.Null(found);
    }

    [Fact]
    public async Task IncrementCurrentSpend_IncrementsValue()
    {
        var budget = new Budget { Id = Guid.NewGuid(), UserId = Guid.NewGuid(), Category = "Food", MonthlyLimit = 100m, CurrentSpend = 20m, CurrencyCode = "USD" };
        await _repo.AddAsync(budget);

        budget.CurrentSpend += 30m;
        await _repo.UpdateAsync(budget);

        Db.ChangeTracker.Clear();
        var found = await _repo.GetByIdAsync(budget.Id);
        Assert.Equal(50m, found!.CurrentSpend);
    }

    [Fact]
    public async Task IncrementCurrentSpend_NegativeDelta_Decrements()
    {
        var budget = new Budget { Id = Guid.NewGuid(), UserId = Guid.NewGuid(), Category = "Food", MonthlyLimit = 100m, CurrentSpend = 50m, CurrencyCode = "USD" };
        await _repo.AddAsync(budget);

        budget.CurrentSpend -= 20m;
        await _repo.UpdateAsync(budget);

        Db.ChangeTracker.Clear();
        var found = await _repo.GetByIdAsync(budget.Id);
        Assert.Equal(30m, found!.CurrentSpend);
    }
}
