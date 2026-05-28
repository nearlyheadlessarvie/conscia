namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityOptions
{
    public const string SectionName = "AppCompatibility";

    public string CurrentSupportedAppVersion { get; set; } = "2.0.1+13";
    public string PreviousSupportedAppVersion { get; set; } = "1.2.0+11";
}



