using System.Text.Json;

namespace Conscia.Tests.Unit;

public class ReleasePleaseConfigTests
{
    [Fact]
    public void ApiReleasePackage_CoversDeployedRuntimePaths()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var configPath = Path.Combine(repoRoot, ".release-please-config.json");
        var manifestPath = Path.Combine(repoRoot, ".release-please-manifest.json");

        using var config = JsonDocument.Parse(File.ReadAllText(configPath));
        using var manifest = JsonDocument.Parse(File.ReadAllText(manifestPath));

        var packages = config.RootElement.GetProperty("packages");
        Assert.True(packages.TryGetProperty("src", out var apiPackage));
        Assert.False(packages.TryGetProperty("src/Conscia.Api", out _));
        Assert.True(manifest.RootElement.TryGetProperty("src", out _));
        Assert.False(manifest.RootElement.TryGetProperty("src/Conscia.Api", out _));

        Assert.Equal("api", apiPackage.GetProperty("component").GetString());
        Assert.Equal("api", apiPackage.GetProperty("package-name").GetString());
        Assert.Equal("src/Conscia.Api/Conscia.Api.csproj", apiPackage.GetProperty("version-file").GetString());
        Assert.Equal("Conscia.Api/CHANGELOG.md", apiPackage.GetProperty("changelog-path").GetString());

        const string apiReleasePath = "src";
        var runtimePaths = new[]
        {
            "src/Conscia.Api",
            "src/Conscia.Application",
            "src/Conscia.Infrastructure",
            "src/Conscia.AI",
            "src/Conscia.Domain",
            "src/Conscia.CognitoPreSignupLinker",
            "src/Conscia.OutboxProcessor",
            "src/Conscia.RecurringProcessor",
            "src/Conscia.PatternAggregator"
        };

        foreach (var path in runtimePaths)
            Assert.StartsWith($"{apiReleasePath}/", $"{path}/", StringComparison.Ordinal);
    }
}
