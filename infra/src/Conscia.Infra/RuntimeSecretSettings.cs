namespace Conscia.Infra;

public sealed record RuntimeSecretSettings(
    string AuthAppJwtSigningKeySecretName,
    string ApplePrivateKeySecretName,
    string GooglePlayServiceAccountJsonSecretName,
    string FirebaseAdminServiceAccountJsonSecretName)
{
    public static RuntimeSecretSettings FromEnvironment() => new(
        AuthAppJwtSigningKeySecretName: Get("AUTH_APP_JWT_SIGNING_KEY_SECRET_NAME") ?? "conscia/prod/auth-app-jwt-signing-key",
        ApplePrivateKeySecretName: Get("APPLE_PRIVATE_KEY_SECRET_NAME") ?? "conscia/prod/apple-private-key",
        GooglePlayServiceAccountJsonSecretName: Get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_SECRET_NAME") ?? "conscia/prod/google-play-service-account-json",
        FirebaseAdminServiceAccountJsonSecretName: Get("FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON_SECRET_NAME") ?? "conscia/prod/firebase-admin-service-account-json");

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
