using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IOutboxEventRepository
{
    Task<OutboxEvent> AddAsync(OutboxEvent outboxEvent, CancellationToken ct = default);
    Task<IReadOnlyList<OutboxEvent>> GetPendingAsync(int limit = 50, CancellationToken ct = default);
    Task<bool> TryStartProcessingAsync(OutboxEvent outboxEvent, CancellationToken ct = default);
    Task MarkPendingAsync(OutboxEvent outboxEvent, CancellationToken ct = default);
    Task MarkProcessedAsync(OutboxEvent outboxEvent, CancellationToken ct = default);
}
