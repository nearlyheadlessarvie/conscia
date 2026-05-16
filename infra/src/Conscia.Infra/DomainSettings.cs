namespace Conscia.Infra;

public sealed record DomainSettings(
    string RootDomainName,
    string WwwDomainName,
    string ApiDomainName,
    string HostedZoneId)
{
    public string[] WebDomainNames => [RootDomainName, WwwDomainName];

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
            hostedZoneId);
    }

    private static string? Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
