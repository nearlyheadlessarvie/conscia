using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Enums;

namespace Conscia.Application.Triggers;

public class CoolingOffSuggestionEvaluator : ITriggerEvaluator
{
    private const int MinRecentRegrets = 2;
    public string TriggerName => "CoolingOffSuggestion";

    private readonly ITransactionRepository _transactions;

    public CoolingOffSuggestionEvaluator(ITransactionRepository transactions)
    {
        _transactions = transactions;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var recentTransactions = await _transactions.GetByUserIdAndDateRangeAsync(
            userId,
            DateTime.UtcNow.AddDays(-7),
            DateTime.UtcNow,
            ct);

        var recentRegrets = recentTransactions
            .Where(tx => tx.Type == TransactionType.Expense && tx.RegretLevel == RegretLevel.Regret)
            .OrderByDescending(tx => tx.Date)
            .ToList();

        if (recentRegrets.Count < MinRecentRegrets)
            return [];

        var latest = recentRegrets.First();
        return
        [
            new InAppAlert
            {
                UserId = userId,
                AlertKey = "cooling-off-suggestion",
                TriggerName = TriggerName,
                Title = "Your regret pattern is heating up",
                Message = $"You have logged {recentRegrets.Count} regrets in the last 7 days. A quick cooling-off pause could help before the next purchase.",
                Priority = 100,
                ActionLabel = "Review recent purchases",
                ActionRoute = $"/transactions/{latest.Id}",
                TransactionId = latest.Id,
                Category = latest.Category,
                Counterparty = latest.Counterparty,
                CreatedAt = latest.Date,
            }
        ];
    }
}
