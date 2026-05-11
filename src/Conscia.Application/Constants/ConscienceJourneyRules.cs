namespace Conscia.Application.Constants;

public static class ConscienceEventTypes
{
    public const string ReflectionCompleted = "reflection_completed";
    public const string PrePurchaseChecked = "prepurchase_checked";
    public const string BudgetCreatedFromNudge = "budget_created_from_nudge";
    public const string InsightReviewed = "insight_reviewed";
    public const string RegretPatternReviewed = "regret_pattern_reviewed";
}

public static class ConscienceJourneyRules
{
    public static readonly IReadOnlyList<string> SupportedEventTypes =
    [
        ConscienceEventTypes.ReflectionCompleted,
        ConscienceEventTypes.PrePurchaseChecked,
        ConscienceEventTypes.BudgetCreatedFromNudge,
        ConscienceEventTypes.InsightReviewed,
        ConscienceEventTypes.RegretPatternReviewed
    ];

    public static readonly IReadOnlyDictionary<string, int> XpByEventType =
        new Dictionary<string, int>(StringComparer.Ordinal)
        {
            [ConscienceEventTypes.ReflectionCompleted] = 20,
            [ConscienceEventTypes.PrePurchaseChecked] = 20,
            [ConscienceEventTypes.BudgetCreatedFromNudge] = 35,
            [ConscienceEventTypes.InsightReviewed] = 10,
            [ConscienceEventTypes.RegretPatternReviewed] = 25
        };

    public static readonly IReadOnlyList<ConscienceLevelRule> Levels =
    [
        new("awakening", "Awakening", 0),
        new("impulse_spotter", "Impulse Spotter", 120),
        new("budget_guardian", "Budget Guardian", 400),
        new("conscience_captain", "Conscience Captain", 1000),
        new("money_monk", "Money Monk", 2200)
    ];

    public static readonly IReadOnlyList<ConscienceQuestRule> WeeklyQuests =
    [
        new(
            Key: "reflect_three_purchases",
            Title: "Reflect on 3 purchases",
            Description: "Turn recent decisions into useful signal.",
            EventType: ConscienceEventTypes.ReflectionCompleted,
            Target: 3,
            XpReward: 15),
        new(
            Key: "check_before_purchase",
            Title: "Check before 1 purchase",
            Description: "Pause with Conscia before spending.",
            EventType: ConscienceEventTypes.PrePurchaseChecked,
            Target: 1,
            XpReward: 10),
        new(
            Key: "review_regret_pattern",
            Title: "Review 1 regret pattern",
            Description: "Spot one repeat spending signal.",
            EventType: ConscienceEventTypes.RegretPatternReviewed,
            Target: 1,
            XpReward: 15)
    ];

    public static readonly IReadOnlyList<ConscienceBadgeRule> Badges =
    [
        new(
            Key: "first_reflection",
            Title: "First Reflection",
            Description: "Reflected on your first purchase.",
            EventType: ConscienceEventTypes.ReflectionCompleted,
            Target: 1),
        new(
            Key: "pause_before_purchase",
            Title: "Pause Before Purchase",
            Description: "Checked with Conscia before buying.",
            EventType: ConscienceEventTypes.PrePurchaseChecked,
            Target: 1),
        new(
            Key: "budget_rescuer",
            Title: "Budget Rescuer",
            Description: "Created a budget from a nudge.",
            EventType: ConscienceEventTypes.BudgetCreatedFromNudge,
            Target: 1),
        new(
            Key: "regret_pattern_spotted",
            Title: "Regret Pattern Spotted",
            Description: "Reviewed a regret pattern before it repeated.",
            EventType: ConscienceEventTypes.RegretPatternReviewed,
            Target: 1),
        new(
            Key: "worth_it_week",
            Title: "Worth-It Week",
            Description: "Built a week of reflective spending awareness.",
            EventType: ConscienceEventTypes.ReflectionCompleted,
            Target: 5)
    ];

    public static readonly IReadOnlyList<ConscienceMascotMomentRule> MascotMoments =
    [
        new(
            Key: "first_reflection",
            Persona: "angel",
            Title: "That is a real conscience rep.",
            Message: "One reflection logged. Tiny halo gains, big awareness energy."),
        new(
            Key: "pause_before_purchase",
            Persona: "both",
            Title: "You paused before buying.",
            Message: "Impulse and Reason both got a seat at the table."),
        new(
            Key: "regret_pattern_spotted",
            Persona: "devil",
            Title: "Pattern spotted.",
            Message: "The little devil has been detected. Suspiciously charming, still useful.")
    ];
}

public sealed record ConscienceLevelRule(string Key, string Title, int RequiredXp);

public sealed record ConscienceQuestRule(
    string Key,
    string Title,
    string Description,
    string EventType,
    int Target,
    int XpReward);

public sealed record ConscienceBadgeRule(
    string Key,
    string Title,
    string Description,
    string EventType,
    int Target);

public sealed record ConscienceMascotMomentRule(
    string Key,
    string Persona,
    string Title,
    string Message);
