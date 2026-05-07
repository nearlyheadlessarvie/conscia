using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Triggers;

public class RepeatedRegretCategoryEvaluator : ITriggerEvaluator
{
    private const int MinTransactions = 3;
    private const double MinRegretRate = 0.6;
    public string TriggerName => "RepeatedRegretCategory";

    private readonly IPurchasePatternRepository _patterns;

    public RepeatedRegretCategoryEvaluator(IPurchasePatternRepository patterns)
    {
        _patterns = patterns;
    }

    public async Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default)
    {
        var patterns = await _patterns.GetCategoriesAsync(userId, ct);
        var category = patterns
            .Where(pattern => pattern.TransactionCount >= MinTransactions && pattern.RegretRate >= MinRegretRate)
            .OrderByDescending(pattern => pattern.RegretRate)
            .ThenByDescending(pattern => pattern.TransactionCount)
            .FirstOrDefault();

        if (category is null)
            return [];

        return
        [
            new InAppAlert
            {
                UserId = userId,
                AlertKey = $"repeated-regret-category-{NormalizeKey(category.Category)}",
                TriggerName = TriggerName,
                Title = $"{category.Category} keeps turning into regret",
                Message = $"You have marked {category.RegretRate:P0} of your recent {category.Category} purchases as not worth it.",
                Priority = 70,
                ActionLabel = "See category trend",
                ActionRoute = $"/insights/categories/{Uri.EscapeDataString(category.Category)}",
                Category = category.Category,
                CreatedAt = category.UpdatedAt,
            }
        ];
    }

    private static string NormalizeKey(string value) =>
        value.Trim().ToLowerInvariant().Replace(' ', '-');
}
