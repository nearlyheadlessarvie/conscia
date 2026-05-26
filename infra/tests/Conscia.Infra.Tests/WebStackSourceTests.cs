namespace Conscia.Infra.Tests;

public class WebStackSourceTests
{
    [Fact]
    public void WebStack_SuppressesDnsValidatedCertificateWarningsUntilUsEastMigration()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var sourcePath = Path.Combine(repoRoot, "src", "Conscia.Infra", "WebStack.cs");

        var source = File.ReadAllText(sourcePath);

        Assert.Contains("new DnsValidatedCertificate(", source);
        Assert.Contains("#pragma warning disable CS0618", source);
        Assert.Contains("#pragma warning disable CS0612", source);
        Assert.Contains("#pragma warning restore CS0612", source);
        Assert.Contains("#pragma warning restore CS0618", source);
    }
}
