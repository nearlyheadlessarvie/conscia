using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IInAppAlertRepository
{
    Task AddAsync(InAppAlert alert, CancellationToken ct = default);
    Task<IReadOnlyList<InAppAlert>> GetByUserAsync(Guid userId, CancellationToken ct = default);
}
