namespace Conscia.Infra;

public sealed record ManagedLoginProviderSettings(
    string? GoogleClientId,
    string? AppleServicesId,
    string? AppleTeamId,
    string? AppleKeyId)
{
    public bool HasGoogle => !string.IsNullOrWhiteSpace(GoogleClientId);

    public bool HasApple =>
        !string.IsNullOrWhiteSpace(AppleServicesId)
        && !string.IsNullOrWhiteSpace(AppleTeamId)
        && !string.IsNullOrWhiteSpace(AppleKeyId);

    public static ManagedLoginProviderSettings? FromEnvironment()
    {
        var googleClientId = Get("AUTH_GOOGLE_CLIENT_ID");
        var appleServicesId = Get("COGNITO_APPLE_SERVICES_ID") ?? Get("COGNITO_APPLE_CLIENT_ID");
        var appleTeamId = Get("APPLE_TEAM_ID");
        var appleKeyId = Get("COGNITO_APPLE_KEY_ID");

        if (string.IsNullOrWhiteSpace(googleClientId)
            && string.IsNullOrWhiteSpace(appleServicesId)
            && string.IsNullOrWhiteSpace(appleTeamId)
            && string.IsNullOrWhiteSpace(appleKeyId))
        {
            return null;
        }

        if (!string.IsNullOrWhiteSpace(appleServicesId)
            || !string.IsNullOrWhiteSpace(appleTeamId)
            || !string.IsNullOrWhiteSpace(appleKeyId))
        {
            if (string.IsNullOrWhiteSpace(appleServicesId)
                || string.IsNullOrWhiteSpace(appleTeamId)
                || string.IsNullOrWhiteSpace(appleKeyId))
            {
                throw new InvalidOperationException(
                    "COGNITO_APPLE_SERVICES_ID, APPLE_TEAM_ID, and COGNITO_APPLE_KEY_ID must all be set together.");
            }
        }

        return new ManagedLoginProviderSettings(
            googleClientId,
            appleServicesId,
            appleTeamId,
            appleKeyId);
    }

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
