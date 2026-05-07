namespace Conscia.Application.DTOs;

public class UserProfileUpdateDto
{
    public string? PreferredCurrency { get; set; }
    public string? Locale { get; set; }
    public string? SpendingPersonality { get; set; }
    public string? IncomeRange { get; set; }
    public string? OccupationType { get; set; }
    public string? HouseholdSize { get; set; }
    public bool? HasCompletedOnboarding { get; set; }
}
