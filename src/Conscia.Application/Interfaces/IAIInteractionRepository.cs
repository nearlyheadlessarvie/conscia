using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IAIInteractionRepository
{
    Task<AIInteraction> AddAsync(AIInteraction interaction, CancellationToken ct = default);
    Task<AIInteraction?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default);
    Task<IReadOnlyList<AIInteraction>> ListByUserAsync(Guid userId, DateTime? from, DateTime? to, int limit = 20, CancellationToken ct = default);
}
