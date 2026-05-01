using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class BudgetService : IBudgetService
{
    private readonly IBudgetRepository _repo;
    private readonly ILogger<BudgetService> _logger;

    public BudgetService(IBudgetRepository repo, ILogger<BudgetService> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Budget> CreateAsync(Guid userId, string category, decimal monthlyLimit, string currencyCode, CancellationToken ct = default)
    {
        var budget = new Budget
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Category = category,
            MonthlyLimit = monthlyLimit,
            CurrencyCode = currencyCode
        };

        var result = await _repo.AddAsync(budget, ct);
        _logger.LogInformation("Creating budget {BudgetId} for user {UserId}, category {Category}",
            budget.Id, userId, category);
        return result;
    }

    public async Task<Budget?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct);
        if (budget is null || budget.UserId != userId) return null;
        return budget;
    }

    public Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default) =>
        _repo.ListByUserAsync(userId, ct);

    public async Task<Budget> UpdateAsync(Guid userId, Guid id, decimal? monthlyLimit, string? category, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"Budget {id} not found");

        if (budget.UserId != userId)
            throw new UnauthorizedAccessException("Budget does not belong to this user");

        if (monthlyLimit.HasValue)
            budget.MonthlyLimit = monthlyLimit.Value;
        if (category is not null)
            budget.Category = category;

        var updated = await _repo.UpdateAsync(budget, ct);

        if (updated.PercentUsed > 100)
            _logger.LogWarning("Budget {BudgetId} exceeded: {PercentUsed}% of {MonthlyLimit}",
                updated.Id, updated.PercentUsed, updated.MonthlyLimit);

        return updated;
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"Budget {id} not found");

        if (budget.UserId != userId)
            throw new UnauthorizedAccessException("Budget does not belong to this user");

        await _repo.DeleteAsync(id, ct);
    }

    public Task UpdateCurrentSpendAsync(Guid budgetId, decimal delta, CancellationToken ct = default) =>
        _repo.IncrementCurrentSpendAsync(budgetId, delta, ct);
}
