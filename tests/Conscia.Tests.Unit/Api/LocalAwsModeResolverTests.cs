using Conscia.Api.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;

namespace Conscia.Tests.Unit.Api;

public class LocalAwsModeResolverTests
{
    [Fact]
    public void ShouldUseLocalAwsEmulators_DevelopmentWithoutOverride_ReturnsTrue()
    {
        var configuration = new ConfigurationBuilder().Build();

        var result = LocalAwsModeResolver.ShouldUseLocalAwsEmulators(
            configuration,
            new FakeHostEnvironment(Environments.Development));

        Assert.True(result);
    }

    [Fact]
    public void ShouldUseLocalAwsEmulators_DevelopmentWithRealAwsOverride_ReturnsFalse()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["LocalAws:UseRealAws"] = "true"
            })
            .Build();

        var result = LocalAwsModeResolver.ShouldUseLocalAwsEmulators(
            configuration,
            new FakeHostEnvironment(Environments.Development));

        Assert.False(result);
    }

    [Fact]
    public void ShouldUseLocalAwsEmulators_Production_ReturnsFalse()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["LocalAws:UseRealAws"] = "false"
            })
            .Build();

        var result = LocalAwsModeResolver.ShouldUseLocalAwsEmulators(
            configuration,
            new FakeHostEnvironment(Environments.Production));

        Assert.False(result);
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
