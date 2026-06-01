namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityOptions
{
    public const string SectionName = "AppCompatibility";

    public string CurrentSupportedAppVersion { get; set; } = "2.3.0+24";
    public string PreviousSupportedAppVersion { get; set; } = "2.2.3+21";
}







