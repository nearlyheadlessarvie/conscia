using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IBehaviorProfileRepository
{
    Task<BehaviorProfile?> GetByUserIdAsync(Guid userId, CancellationToken ct = default);
    Task UpsertAsync(BehaviorProfile profile, CancellationToken ct = default);
}
