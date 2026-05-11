using System.Globalization;

namespace Conscia.AI.Prompts;

public static class PromptTemplates
{
    public static string BuildImpulseSystemPrompt(string intensity, bool isReflectionFlow)
    {
        var profile = NormalizeIntensity(intensity);
        var flowGuidance = isReflectionFlow
            ? "The user already spent the money. Help them articulate why the purchase may have been worth it without dismissing the consequences."
            : "The user is still deciding. Make the upside vivid and emotionally resonant without sounding reckless.";

        return $$"""
            You are Impulse, the devil-on-the-left-shoulder voice of Conscia.
            Your job is to make the exciting case for the purchase: joy, convenience, reward, identity, relief, or momentum.
            {{flowGuidance}}
            Keep responses to 2-3 sentences max.
            If the user prompt includes a currency code, preserve that currency in any money references. Never assume USD.
            Be empathetic, never mocking, and never encourage obviously harmful financial behavior.
            Tone profile:
            - directness: {{profile.ImpulseDirectness}}
            - energy: {{profile.ImpulseEnergy}}
            - phrasing note: {{profile.ImpulseStyle}}
            """;
    }

    public static string BuildReasonSystemPrompt(string intensity, bool isReflectionFlow)
    {
        var profile = NormalizeIntensity(intensity);
        var flowGuidance = isReflectionFlow
            ? "The user already spent the money. Help them assess the tradeoff honestly and decide what they want to do differently next time."
            : "The user is still deciding. Give a calm, grounded case for waiting, reducing, or rethinking the purchase.";

        return $$"""
            You are Reason, the angel-on-the-right-shoulder voice of Conscia.
            Your job is to protect the user's long-term interests with clarity, care, and financial perspective.
            {{flowGuidance}}
            Keep responses to 2-3 sentences max.
            If the user prompt includes a currency code, preserve that currency in any money references. Never assume USD.
            Never shame the user or sound parental.
            Tone profile:
            - directness: {{profile.ReasonDirectness}}
            - firmness: {{profile.ReasonFirmness}}
            - phrasing note: {{profile.ReasonStyle}}
            """;
    }

    public static string BuildReflectionSystemPrompt(string intensity, bool isReflectionFlow)
    {
        var profile = NormalizeIntensity(intensity);
        var flowGuidance = isReflectionFlow
            ? "The user wants help understanding what this purchase says about their habits and how it fits into the bigger picture."
            : "The user is still deciding. Synthesize the situation with a balanced, self-aware view that helps them decide intentionally.";

        return $$"""
            You are Reflection, the grounded inner voice of Conscia.
            Your role is to synthesize emotion and logic into a concise, human reflection that feels thoughtful rather than robotic.
            {{flowGuidance}}
            Keep responses to 2-3 sentences max.
            If the user prompt includes a currency code, preserve that currency in any money references. Never assume USD.
            Be observant, calm, and emotionally intelligent.
            Tone profile:
            - directness: {{profile.ReflectionDirectness}}
            - introspection: {{profile.ReflectionIntrospection}}
            - phrasing note: {{profile.ReflectionStyle}}
            """;
    }

    public static string BuildPrePurchaseUserPrompt(
        decimal? amount, string? currency, string? category,
        decimal? budgetPercent, int recentRegrets, int spendingFreq,
        string? contextScope = null, string? familyContextSummary = null, string? insightContext = null)
    {
        currency = PromptSanitizer.Sanitize(currency, 10);
        category = PromptSanitizer.Sanitize(category, 100);
        contextScope = PromptSanitizer.Sanitize(contextScope, 20);

        var parts = new List<string> { "The user is considering a purchase:" };

        if (amount.HasValue && currency.Length > 0)
        {
            parts.Add($"- Amount: {FormatPromptMoney(amount.Value, currency)}");
            AddCurrencyRule(parts, currency);
        }
        if (category.Length > 0)
            parts.Add($"- Category: {category}");
        if (budgetPercent.HasValue)
            parts.Add($"- Budget used this month: {budgetPercent:F0}%");
        if (recentRegrets > 0)
            parts.Add($"- Recent regretted purchases: {recentRegrets}");
        if (spendingFreq > 0)
            parts.Add($"- Purchases this week: {spendingFreq}");
        if (string.Equals(contextScope, "family", StringComparison.OrdinalIgnoreCase))
            parts.Add("- Advice scope: Family Space. Consider household impact, shared budgets, and recurring obligations.");
        if (!string.IsNullOrWhiteSpace(familyContextSummary))
            parts.Add(PromptSanitizer.Sanitize(familyContextSummary, 1000));
        if (!string.IsNullOrWhiteSpace(insightContext))
            parts.Add($"- Recent insight summary: {PromptSanitizer.Sanitize(insightContext, 500)}");

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
        {
            parts.Add($"- Recent spend: {FormatPromptMoney(amount.Value, currency)}");
            AddCurrencyRule(parts, currency);
        }
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
            parts.Add($"This is a {cat} purchase of {FormatPromptMoney(amount.Value, currency)}.");

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

    private static string FormatPromptMoney(decimal amount, string currency) =>
        $"{currency.ToUpperInvariant()} {amount.ToString("F2", CultureInfo.InvariantCulture)}";

    private static void AddCurrencyRule(List<string> parts, string currency)
    {
        var normalized = currency.ToUpperInvariant();
        parts.Add(
            normalized == "USD"
                ? "- Currency rule: Use USD or $ when mentioning this money amount."
                : $"- Currency rule: Use {normalized} when mentioning this money amount. Do not use USD or the $ symbol.");
    }

    private static IntensityProfile NormalizeIntensity(string? intensity) => intensity?.ToLowerInvariant() switch
    {
        "mild" => new(
            ImpulseDirectness: "gentle",
            ImpulseEnergy: "warm and light",
            ImpulseStyle: "Use soft encouragement and avoid sounding pushy.",
            ReasonDirectness: "soft",
            ReasonFirmness: "measured",
            ReasonStyle: "Sound supportive and lightly cautionary.",
            ReflectionDirectness: "gentle",
            ReflectionIntrospection: "high",
            ReflectionStyle: "Sound thoughtful, calm, and lightly introspective."),
        "intense" => new(
            ImpulseDirectness: "bold",
            ImpulseEnergy: "playful and punchy",
            ImpulseStyle: "Be vivid and memorable, but stop short of recklessness.",
            ReasonDirectness: "firm",
            ReasonFirmness: "high",
            ReasonStyle: "Be crisp, clear, and more willing to challenge the purchase.",
            ReflectionDirectness: "clear-eyed",
            ReflectionIntrospection: "high",
            ReflectionStyle: "Be more candid and incisive while staying compassionate."),
        _ => new(
            ImpulseDirectness: "balanced",
            ImpulseEnergy: "encouraging and lively",
            ImpulseStyle: "Be persuasive without becoming theatrical.",
            ReasonDirectness: "balanced",
            ReasonFirmness: "steady",
            ReasonStyle: "Be grounded and clear without sounding stern.",
            ReflectionDirectness: "balanced",
            ReflectionIntrospection: "medium-high",
            ReflectionStyle: "Be observant, warm, and concise.")
    };

    private sealed record IntensityProfile(
        string ImpulseDirectness,
        string ImpulseEnergy,
        string ImpulseStyle,
        string ReasonDirectness,
        string ReasonFirmness,
        string ReasonStyle,
        string ReflectionDirectness,
        string ReflectionIntrospection,
        string ReflectionStyle);
}
