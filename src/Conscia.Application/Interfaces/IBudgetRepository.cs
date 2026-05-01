using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IBudgetRepository
{
    Task<Budget?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default);
    Task<Budget> AddAsync(Budget budget, CancellationToken ct = default);
    Task<Budget> UpdateAsync(Budget budget, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
    Task IncrementCurrentSpendAsync(Guid id, decimal delta, CancellationToken ct = default);
}
