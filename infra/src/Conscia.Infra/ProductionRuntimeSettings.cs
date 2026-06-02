namespace Conscia.Infra;

public sealed record ProductionRuntimeSettings(
    string? AuthGoogleClientId,
    string? AuthAppleClientId,
    string? AppleKeyId,
    string? AppleIssuerId,
    string? AppleBundleId,
    string? ApplePrivateKey,
    string? GooglePlayPackageName,
    string? GooglePlayServiceAccountJson,
    string? FirebaseAdminServiceAccountJson,
    string? FirebaseProjectId,
    string? InviteEmailFromEmail,
    string? InviteEmailConfigurationSetName,
    string InviteEmailDeepLinkBaseUri,
    string? BrevoApiKey = null,
    string? BrevoSenderEmail = null,
    string BrevoSenderName = "Conscia")
{
    public static ProductionRuntimeSettings FromEnvironment() => new(
        AuthGoogleClientId: Get("AUTH_GOOGLE_CLIENT_ID"),
        AuthAppleClientId: Get("AUTH_APPLE_CLIENT_ID"),
        AppleKeyId: Get("APPLE_KEY_ID"),
        AppleIssuerId: Get("APPLE_ISSUER_ID"),
        AppleBundleId: Get("AUTH_APPLE_CLIENT_ID"),
        ApplePrivateKey: Get("APPLE_PRIVATE_KEY"),
        GooglePlayPackageName: Get("GOOGLE_PLAY_PACKAGE_NAME"),
        GooglePlayServiceAccountJson: Get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"),
        FirebaseAdminServiceAccountJson: Get("FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON"),
        FirebaseProjectId: Get("FIREBASE_PROJECT_ID"),
        InviteEmailFromEmail: Get("SES_FROM_EMAIL"),
        InviteEmailConfigurationSetName: Get("SES_CONFIGURATION_SET"),
        InviteEmailDeepLinkBaseUri: Get("INVITE_EMAIL_DEEP_LINK_BASE_URI") ?? "https://getconscia.com/open/family-invite",
        BrevoApiKey: Get("BREVO_API_KEY"),
        BrevoSenderEmail: Get("BREVO_SENDER_EMAIL") ?? Get("SES_FROM_EMAIL"),
        BrevoSenderName: Get("BREVO_SENDER_NAME") ?? "Conscia");

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
