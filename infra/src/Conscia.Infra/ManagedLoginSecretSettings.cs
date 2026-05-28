namespace Conscia.Infra;

public sealed record ManagedLoginSecretSettings(
    string GoogleClientSecretSecretName,
    string ApplePrivateKeySecretName)
{
    public static ManagedLoginSecretSettings FromEnvironment() => new(
        GoogleClientSecretSecretName: Get("COGNITO_GOOGLE_CLIENT_SECRET_SECRET_NAME")
            ?? "conscia/prod/cognito-google-client-secret",
        ApplePrivateKeySecretName: Get("COGNITO_APPLE_PRIVATE_KEY_SECRET_NAME")
            ?? "conscia/prod/cognito-apple-private-key");

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
