namespace Conscia.Tests.Unit.Api;

public class ReleaseAppWorkflowTests
{
    [Fact]
    public void ReleaseAppWorkflow_UsesFastlaneMatchForIosSigning()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var workflowPath = Path.Combine(repoRoot, ".github", "workflows", "release-app.yml");

        var source = File.ReadAllText(workflowPath);

        Assert.Contains("MATCH_GIT_URL: ${{ vars.MATCH_GIT_URL }}", source);
        Assert.Contains("MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}", source);
        Assert.Contains("run: fastlane ios release", source);
        Assert.Contains("RECAPTCHA_ANDROID_SITE_KEY: ${{ vars.RECAPTCHA_ANDROID_SITE_KEY || vars.RECAPTCHA_SITE_KEY }}", source);
        Assert.Contains("RECAPTCHA_IOS_SITE_KEY: ${{ vars.RECAPTCHA_IOS_SITE_KEY || vars.RECAPTCHA_SITE_KEY }}", source);
        Assert.DoesNotContain("GOOGLE_SERVER_CLIENT_ID", source);
        Assert.DoesNotContain("configure_google_sign_in_ios.dart", source);
    }
}
