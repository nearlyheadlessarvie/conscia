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

    [Fact]
    public void ReleaseInfraWorkflow_DoesNotSyncAdminBootstrapEmailsToSecretsManager()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-infra.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("ADMIN_BOOTSTRAP_EMAILS: ${{ secrets.ADMIN_BOOTSTRAP_EMAILS }}", source);
        Assert.Contains("Conscia-Compute:AdminBootstrapEmails=$ADMIN_BOOTSTRAP_EMAILS", source);
        Assert.DoesNotContain("ADMIN_BOOTSTRAP_EMAILS_SECRET_NAME", source);
        Assert.DoesNotContain("upsert_secret \"$ADMIN_BOOTSTRAP_EMAILS", source);
    }

    [Fact]
    public void ReleaseInfraWorkflow_PassesRecaptchaKeyAsDeploySecret()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-infra.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("RECAPTCHA_API_KEY_SECRET: ${{ secrets.RECAPTCHA_API_KEY_SECRET }}", source);
        Assert.Contains("RECAPTCHA_ALLOWED_SITE_KEYS: ${{ vars.RECAPTCHA_ALLOWED_SITE_KEYS || vars.RECAPTCHA_SITE_KEY }}", source);
        Assert.DoesNotContain("RECAPTCHA_API_KEY_SECRET_NAME", source);
        Assert.DoesNotContain("upsert_secret \"$RECAPTCHA_API_KEY", source);
    }
}
