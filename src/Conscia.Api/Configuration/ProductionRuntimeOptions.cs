namespace Conscia.Api.Configuration;

public sealed class ProductionRuntimeOptions
{
    public const string SectionName = "ProductionRuntime";

    public bool RequireSubscriptionValidation { get; set; } = true;
    public bool RequirePushNotifications { get; set; } = true;
    public bool RequireInviteEmail { get; set; } = true;
    public bool RequireAppCompatibility { get; set; } = true;
}
