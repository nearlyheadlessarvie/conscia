namespace Conscia.Application.Configuration;

public class AppleStoreOptions
{
    public const string SectionName = "Apple";

    public string? KeyId { get; set; }
    public string? IssuerId { get; set; }
    public string? BundleId { get; set; }

    /// <summary>
    /// Base64-encoded .p8 private key content (without headers).
    /// Set via environment variable or AWS Secrets Manager.
    /// </summary>
    public string? PrivateKey { get; set; }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(KeyId) &&
        !string.IsNullOrWhiteSpace(IssuerId) &&
        !string.IsNullOrWhiteSpace(BundleId) &&
        !string.IsNullOrWhiteSpace(PrivateKey);
}

public class GooglePlayOptions
{
    public const string SectionName = "GooglePlay";

    /// <summary>
    /// Android package name (e.g. "com.conscia.app").
    /// </summary>
    public string? PackageName { get; set; }

    /// <summary>
    /// Base64-encoded service account JSON.
    /// Set via environment variable or AWS Secrets Manager.
    /// </summary>
    public string? ServiceAccountJson { get; set; }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(PackageName) &&
        !string.IsNullOrWhiteSpace(ServiceAccountJson);
}
