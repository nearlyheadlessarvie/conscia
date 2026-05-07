using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Triggers;

public class BudgetWarningEvaluator : ITriggerEvaluator
{
    private const decimal WarningThresholdPercent = 80m;
    private readonly IBudgetService _budgetService;

    public string TriggerName => "BudgetWarning";

    public BudgetWarningEvaluator(IBudgetService budgetService)
    {
        _budgetService = budgetService;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var budgets = await _budgetService.ListStatusesByUserAsync(userId, ct: ct);
        var alerts = new List<InAppAlert>();

        foreach (var budget in budgets)
        {
            if (budget.MonthlyLimit <= 0) continue;

            var percentUsed = (budget.CurrentSpend / budget.MonthlyLimit) * 100;
            if (percentUsed >= WarningThresholdPercent)
            {
                alerts.Add(new InAppAlert
                {
                    UserId = userId,
                    TriggerName = TriggerName,
                    Title = $"Budget Warning: {budget.Category}",
                    Message = $"You've spent {percentUsed:F0}% of your {budget.Category} budget " +
                              $"({budget.CurrentSpend:F2}/{budget.MonthlyLimit:F2} {budget.CurrencyCode}).",
                    TTL = new DateTimeOffset(DateTime.UtcNow.AddDays(7)).ToUnixTimeSeconds()
                });
            }
        }

        return alerts;
    }
}
