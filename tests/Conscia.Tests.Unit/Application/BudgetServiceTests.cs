using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class BudgetServiceTests
{
    private readonly Mock<IBudgetRepository> _repoMock = new();
    private readonly BudgetService _svc;

    public BudgetServiceTests() => _svc = new BudgetService(_repoMock.Object, NullLogger<BudgetService>.Instance);

    [Fact]
    public async Task CreateAsync_ReturnsBudgetWithCorrectFields()
    {
        var userId = Guid.NewGuid();
        _repoMock.Setup(r => r.AddAsync(It.IsAny<Budget>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Budget b, CancellationToken _) => b);

        var result = await _svc.CreateAsync(userId, "Food", 500m, "USD");

        Assert.Equal(userId, result.UserId);
        Assert.Equal("Food", result.Category);
        Assert.Equal(500m, result.MonthlyLimit);
        Assert.Equal("USD", result.CurrencyCode);
        Assert.NotEqual(Guid.Empty, result.Id);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsNull_WhenBudgetBelongsToDifferentUser()
    {
        var budgetId = Guid.NewGuid();
        var ownerId = Guid.NewGuid();
        var requesterId = Guid.NewGuid();

        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget { Id = budgetId, UserId = ownerId });

        var result = await _svc.GetByIdAsync(requesterId, budgetId);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsBudget_WhenOwnerMatches()
    {
        var budgetId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget { Id = budgetId, UserId = userId });

        var result = await _svc.GetByIdAsync(userId, budgetId);

        Assert.NotNull(result);
        Assert.Equal(budgetId, result!.Id);
    }

    [Fact]
    public async Task UpdateAsync_UpdatesFields()
    {
        var budgetId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var budget = new Budget { Id = budgetId, UserId = userId, Category = "Food", MonthlyLimit = 500 };

        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>())).ReturnsAsync(budget);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<Budget>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Budget b, CancellationToken _) => b);

        var result = await _svc.UpdateAsync(userId, budgetId, 800m, "Groceries");

        Assert.Equal(800m, result.MonthlyLimit);
        Assert.Equal("Groceries", result.Category);
    }

    [Fact]
    public async Task UpdateAsync_ThrowsUnauthorized_WhenUserDoesNotOwnBudget()
    {
        var budgetId = Guid.NewGuid();
        var ownerId = Guid.NewGuid();
        var budget = new Budget { Id = budgetId, UserId = ownerId };

        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>())).ReturnsAsync(budget);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => _svc.UpdateAsync(Guid.NewGuid(), budgetId, 100m, null));
    }

    [Fact]
    public async Task DeleteAsync_ThrowsKeyNotFound_WhenMissing()
    {
        _repoMock.Setup(r => r.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Budget?)null);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => _svc.DeleteAsync(Guid.NewGuid(), Guid.NewGuid()));
    }

    [Fact]
    public async Task DeleteAsync_ThrowsUnauthorized_WhenDifferentOwner()
    {
        var budgetId = Guid.NewGuid();
        var ownerId = Guid.NewGuid();
        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget { Id = budgetId, UserId = ownerId });

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => _svc.DeleteAsync(Guid.NewGuid(), budgetId));
    }

    [Fact]
    public async Task DeleteAsync_Succeeds_WhenOwnerMatches()
    {
        var budgetId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        _repoMock.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget { Id = budgetId, UserId = userId });

        await _svc.DeleteAsync(userId, budgetId);

        _repoMock.Verify(r => r.DeleteAsync(budgetId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ListByUserAsync_DelegatesToRepo()
    {
        var userId = Guid.NewGuid();
        var budgets = new List<Budget>
        {
            new() { Id = Guid.NewGuid(), UserId = userId, Category = "Food" },
            new() { Id = Guid.NewGuid(), UserId = userId, Category = "Transport" }
        };
        _repoMock.Setup(r => r.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(budgets);

        var result = await _svc.ListByUserAsync(userId);

        Assert.Equal(2, result.Count);
    }
}
