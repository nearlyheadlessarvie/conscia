namespace Conscia.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public bool EmailConfirmed { get; set; } = true;
    public string PreferredCurrency { get; set; } = "USD";
    public string Locale { get; set; } = "en-US";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? SpendingPersonality { get; set; }   // "saver" | "balanced" | "free_spender"
    public string? IncomeRange { get; set; }            // "low" | "mid" | "high" | "very_high" | "prefer_not_to_say"
    public string? OccupationType { get; set; }         // "employed" | "self_employed" | "student" | "retired" | "other"
    public string? HouseholdSize { get; set; }          // "solo" | "couple" | "family" | "shared"
    public bool HasCompletedOnboarding { get; set; }
    public bool LocationSuggestionsEnabled { get; set; }
    public string AiPersonalityIntensity { get; set; } = "balanced";
}
