namespace Conscia.Tests.Unit.Api;

public class ReleaseAppWorkflowTests
{
    [Fact]
    public void ReleaseAppWorkflow_SearchesBothProvisioningProfileDirectories()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-app.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles", source);
        Assert.Contains("$HOME/Library/MobileDevice/Provisioning Profiles", source);
    }
}
