using System.Reflection;
using System.Text.Json;

namespace Conscia.Api.Configuration;

public sealed record VersionMetadata(
    string Service,
    string Version,
    string CommitSha,
    string DeployedAt);

public static class VersionMetadataResolver
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static VersionMetadata Resolve()
    {
        var metadataPath = Path.Combine(AppContext.BaseDirectory, "version.json");
        if (File.Exists(metadataPath))
        {
            try
            {
                using var stream = File.OpenRead(metadataPath);
                var metadata = JsonSerializer.Deserialize<VersionMetadata>(stream, JsonOptions);
                if (metadata is not null)
                {
                    return metadata;
                }
            }
            catch (Exception ex) when (ex is IOException or JsonException)
            {
            }
        }

        return BuildFallbackMetadata();
    }

    private static VersionMetadata BuildFallbackMetadata()
    {
        var assembly = typeof(Program).Assembly;
        var version = assembly.GetName().Version?.ToString(3) ?? "unknown";
        var informationalVersion = assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
            ?.InformationalVersion;
        var commitSha = informationalVersion?.Split('+', 2).Skip(1).FirstOrDefault() ?? string.Empty;
        var deployedAt = string.Empty;

        if (!string.IsNullOrWhiteSpace(assembly.Location))
        {
            var timestamp = File.GetLastWriteTimeUtc(assembly.Location);
            if (timestamp != DateTime.MinValue)
            {
                deployedAt = timestamp.ToString("O");
            }
        }

        return new VersionMetadata(
            Service: "conscia-api",
            Version: version,
            CommitSha: commitSha,
            DeployedAt: deployedAt);
    }
}
