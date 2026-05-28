namespace Conscia.Tests.Unit.Api;

public class ReleaseApiWorkflowTests
{
    [Fact]
    public void ReleaseApiWorkflow_DoesNotReferenceLegacyAppJwtSecret()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.DoesNotContain("AUTH_APP_JWT_SIGNING_KEY", source);
    }
}
