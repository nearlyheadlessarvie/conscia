namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityOptions
{
    public const string SectionName = "AppCompatibility";

    public string CurrentSupportedAppVersion { get; set; } = "1.0.0+1";
    public string PreviousSupportedAppVersion { get; set; } = "1.0.0+1";
}

