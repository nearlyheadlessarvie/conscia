using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ITransactionRepository
{
    Task<Transaction> AddAsync(Transaction transaction, CancellationToken ct = default);
    Task<Transaction?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<bool> ExistsRecurringOccurrenceAsync(Guid userId, Guid recurringScheduleId, DateTime occurrenceDate, CancellationToken ct = default);
    Task<(IReadOnlyList<Transaction> Items, string? NextToken)> QueryByUserAsync(Guid userId, DateTime? from, DateTime? to, string? category, int limit, string? paginationToken, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetByUserIdAndDateRangeAsync(Guid userId, DateTime from, DateTime to, CancellationToken ct = default);
    Task UpdateAsync(Transaction transaction, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task UpdateRegretLevelAsync(Guid userId, Guid id, RegretLevel level, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetUserPendingRegretPromptsAsync(Guid userId, DateTime from, DateTime to, CancellationToken ct = default);
}
