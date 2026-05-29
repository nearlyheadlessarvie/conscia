namespace Conscia.Api.Configuration;

public static class ApiLogEnrichment
{
    public static IReadOnlyDictionary<string, string> BuildProperties(
        VersionMetadata metadata,
        string environmentName)
    {
        return new Dictionary<string, string>
        {
            ["ServiceName"] = metadata.Service,
            ["Environment"] = environmentName,
            ["ServiceVersion"] = metadata.Version,
            ["CommitSha"] = metadata.CommitSha,
            ["DeployedAt"] = metadata.DeployedAt
        };
    }
}
