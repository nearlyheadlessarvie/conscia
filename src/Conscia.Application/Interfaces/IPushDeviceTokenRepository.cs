using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IPushDeviceTokenRepository
{
    Task UpsertAsync(PushDeviceToken token, CancellationToken ct = default);
    Task<IReadOnlyList<PushDeviceToken>> GetActiveByUserAsync(Guid userId, CancellationToken ct = default);
}
