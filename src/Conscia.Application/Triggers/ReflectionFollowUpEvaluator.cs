using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Enums;

namespace Conscia.Application.Triggers;

public class ReflectionFollowUpEvaluator : ITriggerEvaluator
{
    public string TriggerName => "ReflectionFollowUp";

    private readonly ITransactionRepository _transactions;
    private readonly IAIInteractionRepository _aiInteractions;

    public ReflectionFollowUpEvaluator(
        ITransactionRepository transactions,
        IAIInteractionRepository aiInteractions)
    {
        _transactions = transactions;
        _aiInteractions = aiInteractions;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var candidates = await _transactions.GetByUserIdAndDateRangeAsync(
            userId,
            DateTime.UtcNow.AddDays(-7),
            DateTime.UtcNow,
            ct);

        var recentCandidate = candidates
            .Where(tx =>
                tx.Type == TransactionType.Expense &&
                (tx.RegretLevel is RegretLevel.Regret or RegretLevel.NotSure))
            .OrderByDescending(tx => tx.Date)
            .FirstOrDefault();

        if (recentCandidate is null)
            return [];

        var existingReflection = await _aiInteractions.GetByTransactionIdAsync(recentCandidate.Id, ct);
        if (existingReflection is not null && string.Equals(existingReflection.InteractionType, "Reflection", StringComparison.OrdinalIgnoreCase))
            return [];

        return
        [
            new InAppAlert
            {
                UserId = userId,
                AlertKey = $"reflection-follow-up-{recentCandidate.Id:D}",
                TriggerName = TriggerName,
                Title = "This purchase still deserves a second look",
                Message = "You marked a recent expense with doubt or regret. A reflection can help you spot what was really going on.",
                Priority = 40,
                ActionLabel = "Reflect now",
                ActionRoute = $"/transactions/{recentCandidate.Id}",
                TransactionId = recentCandidate.Id,
                Category = recentCandidate.Category,
                Counterparty = recentCandidate.Counterparty,
                CreatedAt = recentCandidate.Date,
            }
        ];
    }
}
