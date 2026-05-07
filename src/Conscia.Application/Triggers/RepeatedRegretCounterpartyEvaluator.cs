using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Triggers;

public class RepeatedRegretCounterpartyEvaluator : ITriggerEvaluator
{
    private const int MinVisits = 2;
    private const int MinRegrets = 2;
    private const double MinRegretRate = 0.5;
    public string TriggerName => "RepeatedRegretCounterparty";

    private readonly IPurchasePatternRepository _patterns;

    public RepeatedRegretCounterpartyEvaluator(IPurchasePatternRepository patterns)
    {
        _patterns = patterns;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var patterns = await _patterns.GetMerchantsAsync(userId, ct);
        var counterparty = patterns
            .Where(pattern =>
                pattern.VisitCount >= MinVisits &&
                pattern.RegretCount >= MinRegrets &&
                pattern.RegretRate >= MinRegretRate)
            .OrderByDescending(pattern => pattern.RegretRate)
            .ThenByDescending(pattern => pattern.RegretCount)
            .FirstOrDefault();

        if (counterparty is null)
            return [];

        return
        [
            new InAppAlert
            {
                UserId = userId,
                AlertKey = $"repeated-regret-counterparty-{NormalizeKey(counterparty.Merchant)}",
                TriggerName = TriggerName,
                Title = $"{counterparty.Merchant} is becoming a regret pattern",
                Message = $"You have regretted {counterparty.RegretCount} of your last {counterparty.VisitCount} purchases with {counterparty.Merchant}.",
                Priority = 80,
                ActionLabel = "See merchant trend",
                ActionRoute = $"/insights/merchants/{Uri.EscapeDataString(counterparty.Merchant)}",
                Counterparty = counterparty.Merchant,
                CreatedAt = counterparty.UpdatedAt,
            }
        ];
    }

    private static string NormalizeKey(string value) =>
        value.Trim().ToLowerInvariant().Replace(' ', '-');
}
