using System.Text.Json;
using Conscia.Api.Configuration;

namespace Conscia.Tests.Unit.Api;

public class ApiLoggingConfigurationTests
{
    [Fact]
    public void LogEnrichment_UsesVersionMetadata()
    {
        var metadata = new VersionMetadata(
            Service: "conscia-api",
            Version: "2.3.4",
            CommitSha: "abc123",
            DeployedAt: "2026-05-29T12:00:00Z");

        var properties = ApiLogEnrichment.BuildProperties(metadata, "Production");

        Assert.Equal("conscia-api", properties["ServiceName"]);
        Assert.Equal("Production", properties["Environment"]);
        Assert.Equal("2.3.4", properties["ServiceVersion"]);
        Assert.Equal("abc123", properties["CommitSha"]);
        Assert.Equal("2026-05-29T12:00:00Z", properties["DeployedAt"]);
    }

    [Fact]
    public void ProductionSerilogConsoleSink_UsesCompactJsonFormatter()
    {
        var settingsPath = Path.Combine(FindRepoRoot(), "src", "Conscia.Api", "appsettings.json");
        using var document = JsonDocument.Parse(File.ReadAllText(settingsPath));

        var writeTo = document.RootElement
            .GetProperty("Serilog")
            .GetProperty("WriteTo")
            .EnumerateArray()
            .ToList();

        var consoleSink = Assert.Single(writeTo, sink => sink.GetProperty("Name").GetString() == "Console");
        var formatter = consoleSink
            .GetProperty("Args")
            .GetProperty("formatter")
            .GetString();

        Assert.Contains("CompactJsonFormatter", formatter);
    }

    [Fact]
    public void ApiProject_DoesNotReferenceOpenTelemetryExporters()
    {
        var repoRoot = FindRepoRoot();
        var projectPath = Path.Combine(repoRoot, "src", "Conscia.Api", "Conscia.Api.csproj");
        var programPath = Path.Combine(repoRoot, "src", "Conscia.Api", "Program.cs");

        var project = File.ReadAllText(projectPath);
        var program = File.ReadAllText(programPath);

        Assert.DoesNotContain("OpenTelemetry", project);
        Assert.DoesNotContain("AWS.Distro.OpenTelemetry", project);
        Assert.DoesNotContain("AddOpenTelemetry", program);
        Assert.DoesNotContain("AddOtlpExporter", program);
    }

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !Directory.Exists(Path.Combine(directory.FullName, ".git")))
        {
            directory = directory.Parent;
        }

        return directory?.FullName ?? throw new DirectoryNotFoundException("Could not locate repository root.");
    }
}
