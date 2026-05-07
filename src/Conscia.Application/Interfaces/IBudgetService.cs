using Conscia.Domain.Entities;
using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IBudgetService
{
    Task<Budget> CreateAsync(Guid userId, string category, decimal monthlyLimit, string currencyCode, CancellationToken ct = default);
    Task<Budget?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default);
    Task<BudgetStatus?> GetStatusByIdAsync(Guid userId, Guid id, DateTime? now = null, CancellationToken ct = default);
    Task<IReadOnlyList<BudgetStatus>> ListStatusesByUserAsync(Guid userId, DateTime? now = null, CancellationToken ct = default);
    Task<Budget> UpdateAsync(Guid userId, Guid id, decimal? monthlyLimit, string? category, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
}
