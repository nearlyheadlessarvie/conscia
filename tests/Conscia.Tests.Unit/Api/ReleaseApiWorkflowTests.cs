namespace Conscia.Tests.Unit.Api;

public class ReleaseApiWorkflowTests
{
    [Fact]
    public void ReleaseApiWorkflow_DoesNotReferenceLegacyAppJwtSecret()
    {
        var repoRoot = FindRepoRoot();
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.DoesNotContain("AUTH_APP_JWT_SIGNING_KEY", source);
    }

    [Fact]
    public void ReleaseApiWorkflow_PublishesCognitoPreSignupLinkerAsset()
    {
        var repoRoot = FindRepoRoot();
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains(
            "dotnet publish src/Conscia.CognitoCustomEmailSender -c Release -r linux-arm64 --self-contained -o publish/cognito-custom-email-sender",
            source);
        Assert.Contains(
            "dotnet publish src/Conscia.CognitoPreSignupLinker -c Release -r linux-arm64 --self-contained -o publish/cognito-pre-signup-linker",
            source);
    }

    [Fact]
    public void ReleaseApiWorkflow_PreservesManagedLoginSocialProviderParameters()
    {
        var repoRoot = FindRepoRoot();
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("COGNITO_APPLE_SERVICES_ID: ${{ vars.COGNITO_APPLE_SERVICES_ID }}", source);
        Assert.Contains("APPLE_TEAM_ID: ${{ vars.APPLE_TEAM_ID }}", source);
        Assert.Contains("COGNITO_APPLE_KEY_ID: ${{ secrets.COGNITO_APPLE_KEY_ID }}", source);
        Assert.Contains("COGNITO_APPLE_PRIVATE_KEY: ${{ secrets.COGNITO_APPLE_PRIVATE_KEY }}", source);
        Assert.DoesNotContain("COGNITO_GOOGLE_CLIENT_SECRET", source);
        Assert.Contains(
            "--parameters \"Conscia-Auth:ManagedLoginApplePrivateKey=$COGNITO_APPLE_PRIVATE_KEY\"",
            source);
    }

    [Fact]
    public void ReleaseApiWorkflow_PassesSignupAbuseRuntimeSettings()
    {
        var repoRoot = FindRepoRoot();
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-api.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("COGNITO_SIGNUP_GUARD_TOKEN: ${{ secrets.COGNITO_SIGNUP_GUARD_TOKEN }}", source);
        Assert.Contains("RECAPTCHA_API_KEY_SECRET: ${{ secrets.RECAPTCHA_API_KEY_SECRET }}", source);
        Assert.Contains("RECAPTCHA_PROJECT_ID: ${{ vars.RECAPTCHA_PROJECT_ID }}", source);
        Assert.Contains("RECAPTCHA_ALLOWED_SITE_KEYS: ${{ vars.RECAPTCHA_ALLOWED_SITE_KEYS || vars.RECAPTCHA_SITE_KEY }}", source);
        Assert.Contains("RECAPTCHA_MINIMUM_SCORE: ${{ vars.RECAPTCHA_MINIMUM_SCORE || '0.5' }}", source);
        Assert.DoesNotContain("RECAPTCHA_API_KEY_SECRET_NAME", source);
    }

    private static string FindRepoRoot()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, ".github")))
            {
                return current.FullName;
            }

            current = current.Parent;
        }

        throw new InvalidOperationException("Could not locate repository root.");
    }
}
