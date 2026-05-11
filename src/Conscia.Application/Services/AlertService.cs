using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Services;

public class AlertService : IAlertService
{
    private readonly IReadOnlyList<ITriggerEvaluator> _evaluators;
    private readonly IInAppAlertRepository _alertRepository;

    public AlertService(
        IEnumerable<ITriggerEvaluator> evaluators,
        IInAppAlertRepository alertRepository)
    {
        _evaluators = evaluators.ToList();
        _alertRepository = alertRepository;
    }

    public async Task<IReadOnlyList<InAppAlert>> ListAlertsAsync(Guid userId, CancellationToken ct = default)
    {
        var alerts = new List<InAppAlert>(await _alertRepository.GetByUserAsync(userId, ct));
        foreach (var evaluator in _evaluators)
        {
            var result = await evaluator.EvaluateAsync(userId, ct);
            alerts.AddRange(result);
        }

        return alerts
            .Where(alert => !string.IsNullOrWhiteSpace(alert.AlertKey))
            .GroupBy(alert => alert.AlertKey, StringComparer.OrdinalIgnoreCase)
            .Select(group => group
                .OrderByDescending(alert => alert.Priority)
                .ThenByDescending(alert => alert.CreatedAt)
                .First())
            .OrderByDescending(alert => alert.Priority)
            .ThenByDescending(alert => alert.CreatedAt)
            .ToList();
    }
}
