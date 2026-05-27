using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Exceptions;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CognitoPasskeyAuthServiceTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly CognitoPasskeyAuthService _passkeys;

    public CognitoPasskeyAuthServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:ClientId"] = "client-123"
            })
            .Build();

        _passkeys = new CognitoPasskeyAuthService(
            config,
            _cognito.Object,
            new InMemoryUserRepository(),
            NullLogger<CognitoPasskeyAuthService>.Instance);
    }

    [Fact]
    public async Task StartAuthenticationAsync_NoWebAuthnOptions_ThrowsFriendlyUnavailableError()
    {
        _cognito
            .Setup(c => c.InitiateAuthAsync(
                It.Is<InitiateAuthRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.AuthFlow == AuthFlowType.USER_AUTH &&
                    r.AuthParameters["USERNAME"] == "demo@example.com" &&
                    r.AuthParameters["PREFERRED_CHALLENGE"] == "WEB_AUTHN"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new InitiateAuthResponse
            {
                ChallengeName = ChallengeNameType.SELECT_CHALLENGE,
                AvailableChallenges = [ChallengeNameType.PASSWORD]
            });

        var ex = await Assert.ThrowsAsync<PasskeyAuthenticationUnavailableException>(() =>
            _passkeys.StartAuthenticationAsync(" Demo@Example.com "));

        Assert.Equal("No passkey is registered for this account yet. Sign in with your password, then set up a passkey in Settings.", ex.Message);
    }
}
