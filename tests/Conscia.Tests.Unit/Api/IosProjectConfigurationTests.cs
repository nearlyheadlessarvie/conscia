namespace Conscia.Tests.Unit.Api;

public class IosProjectConfigurationTests
{
    [Fact]
    public void RunnerProject_SetsMinimumIosDeploymentTargetTo174()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var projectPath = Path.Combine(repoRoot, "app", "ios", "Runner.xcodeproj", "project.pbxproj");

        var source = File.ReadAllText(projectPath);

        Assert.DoesNotContain("IPHONEOS_DEPLOYMENT_TARGET = 15.0;", source);
        Assert.Contains("IPHONEOS_DEPLOYMENT_TARGET = 17.4;", source);
    }
}
