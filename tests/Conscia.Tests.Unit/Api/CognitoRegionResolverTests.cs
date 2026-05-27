using Conscia.Api.Configuration;
using Microsoft.Extensions.Configuration;

namespace Conscia.Tests.Unit.Api;

public class CognitoRegionResolverTests
{
    [Fact]
    public void Resolve_UsesAwsSectionRegionFirst()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS:Region"] = "eu-west-1",
                ["AWS_REGION"] = "us-east-1"
            })
            .Build();

        var region = CognitoRegionResolver.Resolve(configuration);

        Assert.Equal("eu-west-1", region);
    }

    [Fact]
    public void Resolve_FallsBackToAwsRegionEnvironmentKey()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS_REGION"] = "us-east-1"
            })
            .Build();

        var region = CognitoRegionResolver.Resolve(configuration);

        Assert.Equal("us-east-1", region);
    }

    [Fact]
    public void Resolve_DefaultsWhenNoRegionIsConfigured()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>())
            .Build();

        var region = CognitoRegionResolver.Resolve(configuration);

        Assert.Equal("ap-southeast-1", region);
    }

    [Fact]
    public void ResolveIssuer_BuildsCognitoIssuerFromConfiguredRegionAndUserPool()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS_REGION"] = "ap-southeast-1",
                ["Auth:Cognito:UserPoolId"] = "ap-southeast-1_abc123"
            })
            .Build();

        var issuer = CognitoRegionResolver.ResolveIssuer(configuration);

        Assert.Equal(
            "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_abc123",
            issuer);
    }
}
