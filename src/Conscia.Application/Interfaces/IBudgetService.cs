using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IBudgetService
{
    Task<Budget> CreateAsync(Guid userId, string category, decimal monthlyLimit, string currencyCode, CancellationToken ct = default);
    Task<Budget?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default);
    Task<Budget> UpdateAsync(Guid userId, Guid id, decimal? monthlyLimit, string? category, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task UpdateCurrentSpendAsync(Guid budgetId, decimal delta, CancellationToken ct = default);
}
