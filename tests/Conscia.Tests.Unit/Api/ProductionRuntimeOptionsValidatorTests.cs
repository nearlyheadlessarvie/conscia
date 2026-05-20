using Conscia.Api.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;

namespace Conscia.Tests.Unit.Api;

public class ProductionRuntimeOptionsValidatorTests
{
    [Fact]
    public void Validate_Succeeds_OutsideProduction()
    {
        var validator = CreateValidator(
            environmentName: Environments.Development,
            config: new Dictionary<string, string?>());

        var result = validator.Validate(null, new ProductionRuntimeOptions());

        Assert.True(result.Succeeded);
    }

    [Fact]
    public void Validate_Fails_WhenProductionConfigIsIncomplete()
    {
        var validator = CreateValidator(
            environmentName: Environments.Production,
            config: new Dictionary<string, string?>
            {
                ["Auth:UseMock"] = "true",
                ["Auth:Cognito:ClientId"] = "client-123"
            });

        var result = validator.Validate(null, new ProductionRuntimeOptions());

        Assert.False(result.Succeeded);
        Assert.Contains(result.Failures!, failure => failure.Contains("Auth:UseMock"));
        Assert.Contains(result.Failures!, failure => failure.Contains("Auth:AppJwtSigningKey"));
        Assert.Contains(result.Failures!, failure => failure.Contains("Google social auth audience"));
        Assert.Contains(result.Failures!, failure => failure.Contains("Apple social auth audience"));
        Assert.Contains(result.Failures!, failure => failure.Contains("GooglePlay:ServiceAccountJson"));
        Assert.Contains(result.Failures!, failure => failure.Contains("Firebase:AdminServiceAccountJson"));
        Assert.Contains(result.Failures!, failure => failure.Contains("InviteEmail:FromEmail"));
        Assert.Contains(result.Failures!, failure => failure.Contains("AppCompatibility:CurrentSupportedAppVersion"));
    }

    [Fact]
    public void Validate_Succeeds_WhenProductionConfigIsComplete()
    {
        var validator = CreateValidator(
            environmentName: Environments.Production,
            config: new Dictionary<string, string?>
            {
                ["Auth:UseMock"] = "false",
                ["Auth:AppJwtSigningKey"] = "social-signing-key-at-least-32-chars-long",
                ["Auth:Cognito:ClientId"] = "client-123",
                ["Auth:Cognito:UserPoolId"] = "pool-123",
                ["Auth:Google:ClientId"] = "google.apps.googleusercontent.com",
                ["Auth:Apple:ClientId"] = "com.conscia.app",
                ["Apple:KeyId"] = "ABC1234567",
                ["Apple:IssuerId"] = "00000000-0000-0000-0000-000000000000",
                ["Apple:BundleId"] = "com.conscia.app",
                ["Apple:PrivateKey"] = "private-key",
                ["GooglePlay:PackageName"] = "com.conscia.app",
                ["GooglePlay:ServiceAccountJson"] = "service-account",
                ["Firebase:AdminServiceAccountJson"] = "{\"project_id\":\"conscia-prod\"}",
                ["InviteEmail:FromEmail"] = "invites@getconscia.com",
                ["AppCompatibility:CurrentSupportedAppVersion"] = "1.2.0+5",
                ["AppCompatibility:PreviousSupportedAppVersion"] = "1.1.0+4"
            });

        var result = validator.Validate(null, new ProductionRuntimeOptions());

        Assert.True(result.Succeeded);
    }

    private static ProductionRuntimeOptionsValidator CreateValidator(
        string environmentName,
        Dictionary<string, string?> config)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(config)
            .Build();

        return new ProductionRuntimeOptionsValidator(
            configuration,
            new FakeHostEnvironment(environmentName));
    }

    private sealed class FakeHostEnvironment : IHostEnvironment
    {
        public FakeHostEnvironment(string environmentName)
        {
            EnvironmentName = environmentName;
            ContentRootFileProvider = new PhysicalFileProvider(ContentRootPath);
        }

        public string EnvironmentName { get; set; }
        public string ApplicationName { get; set; } = "Conscia.Tests";
        public string ContentRootPath { get; set; } = Directory.GetCurrentDirectory();
        public IFileProvider ContentRootFileProvider { get; set; }
    }
}
