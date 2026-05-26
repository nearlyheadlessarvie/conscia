namespace Conscia.Tests.Unit.Api;

public class LambdaHostingConfigurationTests
{
    [Fact]
    public void Program_ConfiguresLambdaHostingForRestApi()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var programPath = Path.Combine(repoRoot, "src", "Conscia.Api", "Program.cs");

        var source = File.ReadAllText(programPath);

        Assert.Contains("AddAWSLambdaHosting", source);
        Assert.Contains("LambdaEventSource.RestApi", source);
    }
}
