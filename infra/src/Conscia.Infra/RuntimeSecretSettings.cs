namespace Conscia.Infra;

public sealed record RuntimeSecretSettings(
    string ApplePrivateKeySecretName,
    string GooglePlayServiceAccountJsonSecretName,
    string FirebaseAdminServiceAccountJsonSecretName,
    string RecaptchaApiKeySecretName = "conscia/prod/recaptcha-api-key")
{
    public static RuntimeSecretSettings FromEnvironment() => new(
        ApplePrivateKeySecretName: Get("APPLE_PRIVATE_KEY_SECRET_NAME") ?? "conscia/prod/apple-private-key",
        GooglePlayServiceAccountJsonSecretName: Get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_SECRET_NAME") ?? "conscia/prod/google-play-service-account-json",
        FirebaseAdminServiceAccountJsonSecretName: Get("FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON_SECRET_NAME") ?? "conscia/prod/firebase-admin-service-account-json",
        RecaptchaApiKeySecretName: Get("RECAPTCHA_API_KEY_SECRET_NAME") ?? "conscia/prod/recaptcha-api-key");

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
