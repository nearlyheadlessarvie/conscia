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

    [Fact]
    public void ReleaseApiWorkflow_PreservesManagedLoginSocialProviderParameters()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("COGNITO_APPLE_SERVICES_ID: ${{ vars.COGNITO_APPLE_SERVICES_ID }}", source);
        Assert.Contains("APPLE_TEAM_ID: ${{ vars.APPLE_TEAM_ID }}", source);
        Assert.Contains("COGNITO_APPLE_KEY_ID: ${{ secrets.COGNITO_APPLE_KEY_ID }}", source);
        Assert.Contains("COGNITO_APPLE_PRIVATE_KEY: ${{ secrets.COGNITO_APPLE_PRIVATE_KEY }}", source);
        Assert.Contains(
            "--parameters \"Conscia-Auth:ManagedLoginApplePrivateKey=$COGNITO_APPLE_PRIVATE_KEY\"",
            source);
    }
}
