using System.Text.Json;

namespace Conscia.Infra;

public sealed record DnsMxRecord(int Priority, string Host);

public sealed record DnsTxtRecord(string Name, string Value);

public sealed record DnsCnameRecord(string Name, string Value);

public sealed record DomainSettings(
    string RootDomainName,
    string WwwDomainName,
    string ApiDomainName,
    string HostedZoneId,
    string? CognitoDomainName = null,
    string? ManagedLoginRedirectUri = null,
    string? ManagedLoginLogoutUri = null,
    string DevManagedLoginRedirectUri = "conscia://auth/callback",
    string DevManagedLoginLogoutUri = "conscia://auth/logout",
    string SesMailFromSubdomain = "feedback",
    string DmarcRecordName = "_dmarc",
    string DmarcValue = "v=DMARC1; p=none",
    IReadOnlyList<DnsMxRecord>? IcloudInboxMxRecords = null,
    IReadOnlyList<DnsTxtRecord>? IcloudInboxTxtRecords = null,
    IReadOnlyList<DnsCnameRecord>? IcloudInboxCnameRecords = null)
{
    public string ResolvedCognitoDomainName => string.IsNullOrWhiteSpace(CognitoDomainName)
        ? $"login.{RootDomainName}"
        : CognitoDomainName;

    public string ResolvedManagedLoginRedirectUri => string.IsNullOrWhiteSpace(ManagedLoginRedirectUri)
        ? DevManagedLoginRedirectUri
        : ManagedLoginRedirectUri;

    public string ResolvedManagedLoginLogoutUri => string.IsNullOrWhiteSpace(ManagedLoginLogoutUri)
        ? DevManagedLoginLogoutUri
        : ManagedLoginLogoutUri;

    public string[] WebDomainNames => [RootDomainName, WwwDomainName];
    public string SesMailFromDomain => $"{SesMailFromSubdomain}.{RootDomainName}";

    public string[] AllowedCorsOrigins =>
    [
        $"https://{RootDomainName}",
        $"https://{WwwDomainName}"
    ];

    public static DomainSettings? FromEnvironment()
    {
        var rootDomain = Get("CONSCIA_DOMAIN_NAME");
        var hostedZoneId = Get("ROUTE53_HOSTED_ZONE_ID");

        if (string.IsNullOrWhiteSpace(rootDomain) || string.IsNullOrWhiteSpace(hostedZoneId))
            return null;

        return new DomainSettings(
            rootDomain,
            Get("CONSCIA_WWW_DOMAIN_NAME") ?? $"www.{rootDomain}",
            Get("CONSCIA_API_DOMAIN_NAME") ?? $"api.{rootDomain}",
            hostedZoneId,
            Get("CONSCIA_COGNITO_DOMAIN_NAME") ?? $"login.{rootDomain}",
            Get("COGNITO_REDIRECT_URI"),
            Get("COGNITO_LOGOUT_URI"),
            Get("COGNITO_DEV_REDIRECT_URI") ?? "conscia://auth/callback",
            Get("COGNITO_DEV_LOGOUT_URI") ?? "conscia://auth/logout",
            Get("CONSCIA_SES_MAIL_FROM_SUBDOMAIN") ?? "feedback",
            Get("CONSCIA_DMARC_RECORD_NAME") ?? "_dmarc",
            Get("CONSCIA_DMARC_VALUE") ?? "v=DMARC1; p=none",
            ParseJsonList<DnsMxRecord>("ICLOUD_INBOX_MX_RECORDS_JSON"),
            ParseJsonList<DnsTxtRecord>("ICLOUD_INBOX_TXT_RECORDS_JSON"),
            ParseJsonList<DnsCnameRecord>("ICLOUD_INBOX_CNAME_RECORDS_JSON"));
    }

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static IReadOnlyList<T>? ParseJsonList<T>(string name)
    {
        var value = Get(name);
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<List<T>>(value, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException(
                $"Environment variable '{name}' must be valid JSON for {typeof(T).Name}[]",
                ex);
        }
    }
}
