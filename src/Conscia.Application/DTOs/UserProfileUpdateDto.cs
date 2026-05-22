namespace Conscia.Application.DTOs;

public class UserProfileUpdateDto
{
    public string? DisplayName { get; set; }
    public string? ProfilePictureKey { get; set; }
    public string? PreferredCurrency { get; set; }
    public string? Locale { get; set; }
    public string? SpendingPersonality { get; set; }
    public string? IncomeRange { get; set; }
    public string? OccupationType { get; set; }
    public string? HouseholdSize { get; set; }
    public bool? HasCompletedOnboarding { get; set; }
    public string? AiPersonalityIntensity { get; set; }
}

public class ProfilePictureUploadRequestDto
{
    public string ContentType { get; set; } = string.Empty;
}

public class ProfilePictureUploadResponseDto
{
    public string UploadUrl { get; set; } = string.Empty;
    public string? ProxyUploadUrl { get; set; }
    public string ProfilePictureKey { get; set; } = string.Empty;
}
