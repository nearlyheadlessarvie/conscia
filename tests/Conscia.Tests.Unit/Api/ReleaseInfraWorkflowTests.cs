namespace Conscia.Tests.Unit.Api;

public class ReleaseInfraWorkflowTests
{
    [Fact]
    public void ReleaseInfraWorkflow_DoesNotReferenceLegacyAppJwtSecret()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-infra.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.DoesNotContain("AUTH_APP_JWT_SIGNING_KEY", source);
    }

    [Fact]
    public void ReleaseInfraWorkflow_DoesNotSyncCognitoDeploySecretsToSecretsManager()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-infra.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.DoesNotContain("COGNITO_GOOGLE_CLIENT_SECRET_SECRET_NAME", source);
        Assert.DoesNotContain("COGNITO_APPLE_PRIVATE_KEY_SECRET_NAME", source);
        Assert.DoesNotContain("upsert_secret \"$COGNITO_GOOGLE_CLIENT_SECRET_SECRET_NAME\"", source);
        Assert.DoesNotContain("upsert_secret \"$COGNITO_APPLE_PRIVATE_KEY_SECRET_NAME\"", source);
    }
}
