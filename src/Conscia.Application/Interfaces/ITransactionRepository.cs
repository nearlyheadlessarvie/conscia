using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ITransactionRepository
{
    Task<Transaction> AddWithOutboxAsync(Transaction transaction, OutboxEvent outboxEvent, CancellationToken ct = default);
    Task<Transaction?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<(IReadOnlyList<Transaction> Items, string? NextToken)> QueryByUserAsync(Guid userId, DateTime? from, DateTime? to, string? category, int limit, string? paginationToken, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetByUserIdAndDateRangeAsync(Guid userId, DateTime from, DateTime to, CancellationToken ct = default);
    Task UpdateAsync(Transaction transaction, DateTime originalDate, CancellationToken ct = default);
    Task DeleteWithOutboxAsync(Guid id, OutboxEvent outboxEvent, CancellationToken ct = default);
    Task UpdateRegretLevelAsync(Guid id, RegretLevel level, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetUserPendingRegretPromptsAsync(Guid userId, DateTime from, DateTime to, CancellationToken ct = default);
}
