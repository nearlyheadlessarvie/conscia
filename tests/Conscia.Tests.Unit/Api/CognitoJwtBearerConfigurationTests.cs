using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Conscia.Api.Configuration;
using Microsoft.Extensions.Configuration;

namespace Conscia.Tests.Unit.Api;

public class CognitoJwtBearerConfigurationTests
{
    [Fact]
    public void CreateTokenValidationParameters_ValidatesIssuerAndClientId()
    {
        var configuration = CreateConfiguration("client-123");

        var parameters = CognitoJwtBearerConfiguration.CreateTokenValidationParameters(configuration);

        Assert.True(parameters.ValidateIssuer);
        Assert.True(parameters.ValidateIssuerSigningKey);
        Assert.True(parameters.ValidateAudience);
        Assert.Equal("client-123", parameters.ValidAudience);
        Assert.Equal(
            "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_pool",
            parameters.ValidIssuer);
    }

    [Fact]
    public void AudienceValidator_AcceptsIdTokenAudienceForConfiguredClient()
    {
        var parameters = CognitoJwtBearerConfiguration.CreateTokenValidationParameters(
            CreateConfiguration("client-123"));

        var accepted = parameters.AudienceValidator?.Invoke(
            ["client-123"],
            new JwtSecurityToken(),
            parameters) ?? false;

        Assert.True(accepted);
    }

    [Fact]
    public void AudienceValidator_AcceptsAccessTokenClientIdForConfiguredClient()
    {
        var parameters = CognitoJwtBearerConfiguration.CreateTokenValidationParameters(
            CreateConfiguration("client-123"));
        var token = new JwtSecurityToken(claims:
        [
            new Claim("client_id", "client-123")
        ]);

        var accepted = parameters.AudienceValidator?.Invoke(
            [],
            token,
            parameters) ?? false;

        Assert.True(accepted);
    }

    [Fact]
    public void AudienceValidator_RejectsWrongClientId()
    {
        var parameters = CognitoJwtBearerConfiguration.CreateTokenValidationParameters(
            CreateConfiguration("client-123"));
        var token = new JwtSecurityToken(claims:
        [
            new Claim("client_id", "other-client")
        ]);

        var accepted = parameters.AudienceValidator?.Invoke(
            ["other-client"],
            token,
            parameters) ?? false;

        Assert.False(accepted);
    }

    [Theory]
    [InlineData("access")]
    [InlineData("id")]
    public void HasAcceptedTokenUse_AcceptsExplicitCognitoTokenUse(string tokenUse)
    {
        var principal = new ClaimsPrincipal(new ClaimsIdentity(
        [
            new Claim("token_use", tokenUse)
        ]));

        Assert.True(CognitoJwtBearerConfiguration.HasAcceptedTokenUse(principal));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("refresh")]
    public void HasAcceptedTokenUse_RejectsMissingOrUnexpectedTokenUse(string? tokenUse)
    {
        var claims = string.IsNullOrEmpty(tokenUse)
            ? []
            : new[] { new Claim("token_use", tokenUse) };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims));

        Assert.False(CognitoJwtBearerConfiguration.HasAcceptedTokenUse(principal));
    }

    private static IConfiguration CreateConfiguration(string clientId) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS_REGION"] = "ap-southeast-1",
                ["Auth:Cognito:UserPoolId"] = "ap-southeast-1_pool",
                ["Auth:Cognito:ClientId"] = clientId
            })
            .Build();
}
