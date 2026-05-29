namespace Conscia.Tests.Unit;

public class ReleaseWorkflowTests
{
    [Theory]
    [InlineData("release-api.yml", "refs/tags/api/v*")]
    [InlineData("release-app.yml", "refs/tags/app/v*")]
    [InlineData("release-infra.yml", "refs/tags/infra/v*")]
    [InlineData("release-web.yml", "refs/tags/web/v*")]
    public void ReleaseWorkflow_ValidatesDispatchRef(string workflowFile, string tagPattern)
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", workflowFile);

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("Validate release ref", source);
        Assert.Contains("refs/heads/main", source);
        Assert.Contains(tagPattern, source);
    }
}
