using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Services;

public class AlertService : IAlertService
{
    private const string DismissedTriggerName = "dismissed";
    private const string DismissedAlertPrefix = "dismissed:";
    private const int DefaultRetentionDays = 30;

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
        var persistedAlerts = await _alertRepository.GetByUserAsync(userId, ct);
        var dismissedKeys = persistedAlerts
            .Where(IsDismissalMarker)
            .Select(a => a.AlertKey[DismissedAlertPrefix.Length..])
            .Where(key => !string.IsNullOrWhiteSpace(key))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var alerts = persistedAlerts
            .Where(alert => !IsDismissalMarker(alert))
            .ToList();
        foreach (var evaluator in _evaluators)
        {
            var result = await evaluator.EvaluateAsync(userId, ct);
            alerts.AddRange(result);
        }

        return alerts
            .Where(alert => !string.IsNullOrWhiteSpace(alert.AlertKey))
            .Where(alert => !IsDismissed(alert, dismissedKeys))
            .GroupBy(alert => alert.AlertKey, StringComparer.OrdinalIgnoreCase)
            .Select(group => group
                .OrderByDescending(alert => alert.Priority)
                .ThenByDescending(alert => alert.CreatedAt)
                .First())
            .OrderByDescending(alert => alert.Priority)
            .ThenByDescending(alert => alert.CreatedAt)
            .ToList();
    }

    public async Task<InAppAlert> CreateAlertAsync(Guid userId, InAppAlert alert, CancellationToken ct = default)
    {
        alert.UserId = userId;
        alert.AlertKey = alert.AlertKey.Trim();
        alert.TriggerName = alert.TriggerName.Trim();
        if (alert.CreatedAt == default)
        {
            alert.CreatedAt = DateTime.UtcNow;
        }

        if (alert.TTL <= 0)
        {
            alert.TTL = DateTimeOffset.UtcNow.AddDays(DefaultRetentionDays).ToUnixTimeSeconds();
        }

        await _alertRepository.AddAsync(alert, ct);
        return alert;
    }

    public Task DismissAlertAsync(Guid userId, string alertId, CancellationToken ct = default)
    {
        var marker = new InAppAlert
        {
            UserId = userId,
            AlertKey = $"{DismissedAlertPrefix}{alertId.Trim()}",
            TriggerName = DismissedTriggerName,
            Title = "Dismissed",
            Message = alertId.Trim(),
            CreatedAt = DateTime.UtcNow,
            TTL = DateTimeOffset.UtcNow.AddDays(DefaultRetentionDays).ToUnixTimeSeconds()
        };

        return _alertRepository.AddAsync(marker, ct);
    }

    private static bool IsDismissalMarker(InAppAlert alert) =>
        alert.TriggerName.Equals(DismissedTriggerName, StringComparison.OrdinalIgnoreCase)
        && alert.AlertKey.StartsWith(DismissedAlertPrefix, StringComparison.OrdinalIgnoreCase);

    private static bool IsDismissed(InAppAlert alert, ISet<string> dismissedKeys) =>
        dismissedKeys.Contains(alert.AlertKey)
        || dismissedKeys.Contains(alert.Id.ToString("D"));
}
