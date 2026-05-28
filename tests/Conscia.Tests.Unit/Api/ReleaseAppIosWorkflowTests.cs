namespace Conscia.Tests.Unit.Api;

public class ReleaseAppIosWorkflowTests
{
    [Fact]
    public void ReleaseAppWorkflow_PreparesIosConfigurationWithoutCodesigning()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-app.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("flutter build ios --release --config-only \\", source);
        Assert.Contains("--no-codesign \\", source);
    }

    [Fact]
    public void ReleaseAppWorkflow_DelegatesSigningWithoutProvisioningProfileOverride()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-app.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("Build and upload iOS release with Fastlane", source);
        Assert.Contains("run: fastlane ios release", source);
        Assert.DoesNotContain("PROVISIONING_PROFILE_SPECIFIER=", source);
    }
}
