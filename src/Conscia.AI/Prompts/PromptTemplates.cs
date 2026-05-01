namespace Conscia.AI.Prompts;

public static class PromptTemplates
{
    public const string ImpulseSystemPrompt = """
        You are Impulse, a fun and persuasive financial personality. Your role is to play devil's advocate 
        and gently encourage the user to consider why this purchase might be worthwhile. Be witty, 
        supportive, and empathetic — but never reckless. Keep responses to 2-3 sentences max.
        Focus on emotional value, enjoyment, and life quality.
        """;

    public const string ReasonSystemPrompt = """
        You are Reason, a thoughtful and caring financial advisor. Your role is to help the user pause 
        and reflect before spending. Provide a calm, data-driven perspective on why they might want to 
        wait or reconsider. Never be judgmental or preachy. Keep responses to 2-3 sentences max.
        Focus on budget impact, savings goals, and long-term thinking.
        """;

    public static string BuildPrePurchaseUserPrompt(
        decimal? amount, string? currency, string? category,
        decimal? budgetPercent, int recentRegrets, int spendingFreq)
    {
        currency = PromptSanitizer.Sanitize(currency, 10);
        category = PromptSanitizer.Sanitize(category, 100);

        var parts = new List<string> { "The user is considering a purchase:" };

        if (amount.HasValue && currency.Length > 0)
            parts.Add($"- Amount: {amount:F2} {currency}");
        if (category.Length > 0)
            parts.Add($"- Category: {category}");
        if (budgetPercent.HasValue)
            parts.Add($"- Budget used this month: {budgetPercent:F0}%");
        if (recentRegrets > 0)
            parts.Add($"- Recent regretted purchases: {recentRegrets}");
        if (spendingFreq > 0)
            parts.Add($"- Purchases this week: {spendingFreq}");

        parts.Add("\nRespond in character with your perspective on this purchase.");
        return string.Join("\n", parts);
    }

    public static string BuildReflectionUserPrompt(
        decimal? amount, string? currency, string? category,
        decimal? budgetPercent, int recentRegrets)
    {
        currency = PromptSanitizer.Sanitize(currency, 10);
        category = PromptSanitizer.Sanitize(category, 100);

        var parts = new List<string> { "The user wants to reflect on their recent spending:" };

        if (amount.HasValue && currency.Length > 0)
            parts.Add($"- Recent spend: {amount:F2} {currency}");
        if (category.Length > 0)
            parts.Add($"- Category: {category}");
        if (budgetPercent.HasValue)
            parts.Add($"- Budget used this month: {budgetPercent:F0}%");
        if (recentRegrets > 0)
            parts.Add($"- Recent regretted purchases: {recentRegrets}");

        parts.Add("\nRespond in character with your reflection on their spending patterns.");
        return string.Join("\n", parts);
    }

    public static string BuildNeutralSummary(
        decimal? amount, string? currency, string? category,
        decimal? budgetPercent)
    {
        var cat = category ?? "general";
        var parts = new List<string>();

        if (amount.HasValue && currency is not null)
            parts.Add($"This is a {cat} purchase of {amount:F2} {currency}.");

        if (budgetPercent.HasValue)
        {
            parts.Add(budgetPercent switch
            {
                >= 100 => $"You've exceeded your {cat} budget for this month ({budgetPercent:F0}% used).",
                >= 80 => $"You've used {budgetPercent:F0}% of your {cat} budget this month — approaching the limit.",
                >= 50 => $"You've used {budgetPercent:F0}% of your {cat} budget this month.",
                _ => $"You've used {budgetPercent:F0}% of your {cat} budget — plenty of room remaining."
            });
        }
        else
        {
            parts.Add($"No budget is set for {cat}.");
        }

        return string.Join(" ", parts);
    }
}
