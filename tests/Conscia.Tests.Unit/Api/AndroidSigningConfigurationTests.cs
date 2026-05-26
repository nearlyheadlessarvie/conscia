namespace Conscia.Tests.Unit.Api;

public class AndroidSigningConfigurationTests
{
    [Fact]
    public void AndroidReleaseSigning_ResolvesKeystorePathFromAndroidRoot()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var gradlePath = Path.Combine(repoRoot, "app", "android", "app", "build.gradle.kts");

        var source = File.ReadAllText(gradlePath);

        Assert.Contains("storeFile = rootProject.file(storeFilePath)", source);
    }
}
