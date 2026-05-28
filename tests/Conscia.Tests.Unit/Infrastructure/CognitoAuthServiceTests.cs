using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CognitoAuthServiceTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly InMemoryUserRepository _repo = new();
    private readonly CognitoAuthService _auth;

    public CognitoAuthServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:ClientId"] = "client-123"
            })
            .Build();

        _auth = new CognitoAuthService(
            config,
            _cognito.Object,
            _repo,
            NullLogger<CognitoAuthService>.Instance);
    }

    [Fact]
    public async Task RegisterAsync_SignUpPendingConfirmation_CreatesLocalUserFromCognitoSub()
    {
        var userSub = Guid.NewGuid();
        _cognito
            .Setup(c => c.SignUpAsync(
                It.Is<SignUpRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Username == "new@example.com" &&
                    r.Password == "SecureP@ss123" &&
                    r.UserAttributes.Any(a => a.Name == "email" && a.Value == "new@example.com")),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new SignUpResponse
            {
                UserConfirmed = false,
                UserSub = userSub.ToString()
            });

        var result = await _auth.RegisterAsync(" New@Example.com ", "SecureP@ss123");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal(userSub.ToString(), result.UserId);
        Assert.Equal("new@example.com", result.Email);

        var user = _repo.Users.Single();
        Assert.Equal(userSub, user.Id);
        Assert.Equal("new@example.com", user.Email);
        Assert.False(user.EmailConfirmed);

        var identity = _repo.Identities.Single();
        Assert.Equal(AuthProvider.Email, identity.Provider);
        Assert.Equal("new@example.com", identity.ProviderSub);
        Assert.Equal(userSub, identity.UserId);
    }

    [Fact]
    public async Task RegisterAsync_ExistingUnconfirmedUser_ResendsConfirmationAndReturnsPending()
    {
        _cognito
            .Setup(c => c.SignUpAsync(
                It.Is<SignUpRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Username == "new@example.com"),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UsernameExistsException("User already exists"));

        _cognito
            .Setup(c => c.ResendConfirmationCodeAsync(
                It.Is<ResendConfirmationCodeRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Username == "new@example.com"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ResendConfirmationCodeResponse());

        var result = await _auth.RegisterAsync(" New@Example.com ", "SecureP@ss123");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("new@example.com", result.Email);
    }

    [Fact]
    public async Task ConfirmRegistrationAsync_ValidCode_ConfirmsCognitoUser()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "new@example.com",
            EmailConfirmed = false
        };
        await _repo.AddAsync(user);

        _cognito
            .Setup(c => c.ConfirmSignUpAsync(
                It.Is<ConfirmSignUpRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Username == "new@example.com" &&
                    r.ConfirmationCode == "123456"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ConfirmSignUpResponse());

        var result = await _auth.ConfirmRegistrationAsync(" New@Example.com ", "123456");

        Assert.True(result.Success);
        Assert.False(result.RequiresConfirmation);
        Assert.Equal("new@example.com", result.Email);

        var updatedUser = _repo.Users.Single(u => u.Email == "new@example.com");
        Assert.True(updatedUser.EmailConfirmed);
    }

    [Fact]
    public async Task ResendConfirmationAsync_ExistingCognitoUser_RequestsNewCode()
    {
        _cognito
            .Setup(c => c.ResendConfirmationCodeAsync(
                It.Is<ResendConfirmationCodeRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Username == "new@example.com"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ResendConfirmationCodeResponse());

        var result = await _auth.ResendConfirmationAsync(" New@Example.com ");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("new@example.com", result.Email);
    }

    [Fact]
    public async Task LoginAsync_UserPasswordAuth_UsesIdTokenClaimsForLocalUser()
    {
        var userId = Guid.NewGuid();
        _cognito
            .Setup(c => c.InitiateAuthAsync(
                It.Is<InitiateAuthRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.AuthFlow == AuthFlowType.USER_PASSWORD_AUTH &&
                    r.AuthParameters["USERNAME"] == "login@example.com" &&
                    r.AuthParameters["PASSWORD"] == "password123"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new InitiateAuthResponse
            {
                AuthenticationResult = new AuthenticationResultType
                {
                    AccessToken = CreateJwt(userId, "login@example.com"),
                    IdToken = CreateJwt(userId, "login@example.com"),
                    RefreshToken = "refresh-token-123"
                }
            });

        var result = await _auth.LoginAsync(" Login@Example.com ", "password123");

        Assert.True(result.Success);
        Assert.Equal(userId.ToString(), result.UserId);
        Assert.Equal("login@example.com", result.Email);
        Assert.Equal("refresh-token-123", result.RefreshToken);

        var user = _repo.Users.Single();
        Assert.Equal(userId, user.Id);
        Assert.Equal("login@example.com", user.Email);
        Assert.True(user.EmailConfirmed);

        var identity = _repo.Identities.Single();
        Assert.Equal(AuthProvider.Email, identity.Provider);
        Assert.Equal("login@example.com", identity.ProviderSub);
    }

    [Fact]
    public async Task RefreshAsync_CognitoRefreshToken_UsesRefreshFlowAndPreservesRefreshToken()
    {
        var userId = Guid.NewGuid();
        _cognito
            .Setup(c => c.InitiateAuthAsync(
                It.Is<InitiateAuthRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.AuthFlow == AuthFlowType.REFRESH_TOKEN_AUTH &&
                    r.AuthParameters["REFRESH_TOKEN"] == "refresh-token-123"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new InitiateAuthResponse
            {
                AuthenticationResult = new AuthenticationResultType
                {
                    AccessToken = CreateJwt(userId, "refresh@example.com"),
                    IdToken = CreateJwt(userId, "refresh@example.com")
                }
            });

        var result = await _auth.RefreshAsync("refresh-token-123");

        Assert.True(result.Success);
        Assert.Equal(userId.ToString(), result.UserId);
        Assert.Equal("refresh@example.com", result.Email);
        Assert.Equal("refresh-token-123", result.RefreshToken);
        _cognito.Verify(c => c.InitiateAuthAsync(
            It.IsAny<InitiateAuthRequest>(),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    private static string CreateJwt(Guid userId, string email)
    {
        var token = new JwtSecurityToken(
            issuer: "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_example",
            claims:
            [
                new Claim("sub", userId.ToString()),
                new Claim("email", email)
            ]);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
