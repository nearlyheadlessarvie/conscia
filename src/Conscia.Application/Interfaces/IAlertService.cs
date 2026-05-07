using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IAlertService
{
    Task<IReadOnlyList<InAppAlert>> ListAlertsAsync(Guid userId, CancellationToken ct = default);
}
