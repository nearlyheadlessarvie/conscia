using Conscia.Application.Interfaces;
using Conscia.Application.DTOs;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class BudgetServiceTests
{
    private readonly Mock<IBudgetRepository> _repoMock = new();
    private readonly Mock<ITransactionRepository> _transactionRepoMock = new();
    private readonly BudgetService _svc;

    public BudgetServiceTests() => _svc = new BudgetService(
        _repoMock.Object,
        _transactionRepoMock.Object,
        NullLogger<BudgetService>.Instance);

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
    public async Task CreateAsync_FamilyScope_AddsFamilyMetadataToBudget()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _repoMock.Setup(r => r.AddAsync(It.IsAny<Budget>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Budget b, CancellationToken _) => b);

        var result = await _svc.CreateAsync(userId, new CreateBudgetDto
        {
            Category = "Groceries",
            MonthlyLimit = 12000m,
            CurrencyCode = "PHP",
            Scope = RecordScope.Family,
            FamilySpaceId = familySpaceId
        });

        Assert.Equal(RecordScope.Family, result.Scope);
        Assert.Equal(familySpaceId, result.FamilySpaceId);
        Assert.Equal(userId, result.SharedByUserId);
        Assert.NotNull(result.SharedAt);
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

    [Fact]
    public async Task ListStatusesByUserAsync_ComputesCurrentMonthSpendByCategory()
    {
        var userId = Guid.NewGuid();
        var now = new DateTime(2026, 5, 7, 12, 0, 0, DateTimeKind.Utc);
        var budgets = new List<Budget>
        {
            new() { Id = Guid.NewGuid(), UserId = userId, Category = "Dining", MonthlyLimit = 500m, CurrencyCode = "USD" },
            new() { Id = Guid.NewGuid(), UserId = userId, Category = "Groceries", MonthlyLimit = 300m, CurrencyCode = "USD" }
        };

        _repoMock.Setup(r => r.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(budgets);
        _transactionRepoMock
            .Setup(r => r.GetByUserIdAndDateRangeAsync(
                userId,
                It.IsAny<DateTime>(),
                It.IsAny<DateTime>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Dining",
                    Type = TransactionType.Expense,
                    Amount = new Money(120m, "USD"),
                    Date = now.AddDays(-1),
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Dining",
                    Type = TransactionType.Income,
                    Amount = new Money(900m, "USD"),
                    Date = now.AddDays(-1),
                },
                new()
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Groceries",
                    Type = TransactionType.Expense,
                    Amount = new Money(80m, "USD"),
                    Date = now.AddMonths(-1),
                }
            });

        var result = await _svc.ListStatusesByUserAsync(userId, now);

        var dining = Assert.Single(result.Where(b => b.Category == "Dining"));
        var groceries = Assert.Single(result.Where(b => b.Category == "Groceries"));

        Assert.Equal(120m, dining.CurrentSpend);
        Assert.Equal(24m, dining.PercentUsed);
        Assert.Equal(0m, groceries.CurrentSpend);
    }
}
