using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Enums;

namespace Conscia.Application.Triggers;

public class NotSureStreakEvaluator : ITriggerEvaluator
{
    private const int LookbackCount = 5;
    private const int MinNotSureCount = 3;
    public string TriggerName => "NotSureStreak";

    private readonly ITransactionRepository _transactions;

    public NotSureStreakEvaluator(ITransactionRepository transactions)
    {
        _transactions = transactions;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var recentTransactions = await _transactions.GetByUserIdAndDateRangeAsync(
            userId,
            DateTime.UtcNow.AddDays(-30),
            DateTime.UtcNow,
            ct);

        var recentRatedExpenses = recentTransactions
            .Where(tx => tx.Type == TransactionType.Expense && tx.RegretLevel.HasValue)
            .OrderByDescending(tx => tx.Date)
            .Take(LookbackCount)
            .ToList();

        var notSureCount = recentRatedExpenses.Count(tx => tx.RegretLevel == RegretLevel.NotSure);
        if (recentRatedExpenses.Count < MinNotSureCount || notSureCount < MinNotSureCount)
            return [];

        return
        [
            new InAppAlert
            {
                UserId = userId,
                AlertKey = "not-sure-streak",
                TriggerName = TriggerName,
                Title = "You keep landing on not sure",
                Message = $"Three of your last five rated purchases ended in \"Not sure\". It may be time to slow down and check the pattern.",
                Priority = 50,
                ActionLabel = "Open insights",
                ActionRoute = "/insights",
                CreatedAt = recentRatedExpenses.First().Date,
            }
        ];
    }
}
