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

    [Fact]
    public void ReleaseApiWorkflow_PublishesCognitoPreSignupLinkerAsset()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains(
            "dotnet publish src/Conscia.CognitoPreSignupLinker -c Release -r linux-arm64 --self-contained -o publish/cognito-pre-signup-linker",
            source);
    }
}
