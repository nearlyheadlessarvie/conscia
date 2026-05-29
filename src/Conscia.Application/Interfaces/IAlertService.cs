using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IAlertService
{
    Task<IReadOnlyList<InAppAlert>> ListAlertsAsync(Guid userId, CancellationToken ct = default);
    Task<InAppAlert> CreateAlertAsync(Guid userId, InAppAlert alert, CancellationToken ct = default);
    Task DismissAlertAsync(Guid userId, string alertId, CancellationToken ct = default);
}
