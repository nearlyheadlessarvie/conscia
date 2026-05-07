using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Services;

public class AlertService : IAlertService
{
    private readonly IReadOnlyList<ITriggerEvaluator> _evaluators;

    public AlertService(IEnumerable<ITriggerEvaluator> evaluators)
    {
        _evaluators = evaluators.ToList();
    }

    public async Task<IReadOnlyList<InAppAlert>> ListAlertsAsync(Guid userId, CancellationToken ct = default)
    {
        var alerts = new List<InAppAlert>();
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
