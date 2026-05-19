namespace Conscia.Application.Constants;

public static class FreemiumCategoryPolicy
{
    public static readonly IReadOnlyList<string> FreeTransactionCategories = new[]
    {
        "Dining",
        "Groceries",
        "Salary"
    };

    private static readonly HashSet<string> FreeTransactionCategorySet =
        FreeTransactionCategories
            .Select(NormalizeCategory)
            .ToHashSet(StringComparer.Ordinal);

    public static bool IsFreeTransactionCategory(string? category)
    {
        if (string.IsNullOrWhiteSpace(category))
            return false;

        return FreeTransactionCategorySet.Contains(NormalizeCategory(category));
    }

    private static string NormalizeCategory(string category) =>
        category.Trim().ToLowerInvariant();
}
