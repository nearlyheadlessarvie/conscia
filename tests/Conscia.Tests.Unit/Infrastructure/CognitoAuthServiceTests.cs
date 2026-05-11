using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Conscia.Infrastructure.Repositories;
using Conscia.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CognitoAuthServiceTests : IDisposable
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly FakeExternalSocialTokenVerifier _socialVerifier = new();
    private readonly ConsciaDbContext _db;
    private readonly CognitoAuthService _auth;

    public CognitoAuthServiceTests()
    {
        var options = new DbContextOptionsBuilder<ConsciaDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new ConsciaDbContext(options);

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:ClientId"] = "client-123",
                ["Auth:Cognito:UserPoolId"] = "pool-123",
                ["Auth:AppJwtSigningKey"] = "social-signing-key-at-least-32-chars-long"
            })
            .Build();

        _auth = new CognitoAuthService(
            config,
            _cognito.Object,
            _socialVerifier,
            new UserRepository(_db),
            NullLogger<CognitoAuthService>.Instance);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
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

        var user = await _db.Users.SingleAsync();
        Assert.Equal(userSub, user.Id);
        Assert.Equal("new@example.com", user.Email);
        Assert.False(user.EmailConfirmed);

        var identity = await _db.UserIdentities.SingleAsync();
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
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

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

        var updatedUser = await _db.Users.SingleAsync(u => u.Email == "new@example.com");
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
    public async Task LoginWithGoogleAsync_NewVerifiedToken_CreatesLocalIdentityAndCognitoUser()
    {
        _socialVerifier.GooglePayload = new SocialTokenPayload(
            ProviderSub: "google-sub-123",
            Email: "Social@Example.com",
            EmailVerified: true);

        _cognito
            .Setup(c => c.AdminCreateUserAsync(
                It.Is<AdminCreateUserRequest>(r =>
                    r.UserPoolId == "pool-123" &&
                    r.MessageAction == MessageActionType.SUPPRESS &&
                    r.UserAttributes.Any(a => a.Name == "email" && a.Value == "social@example.com") &&
                    r.UserAttributes.Any(a => a.Name == "email_verified" && a.Value == "true")),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminCreateUserResponse());

        var result = await _auth.LoginWithGoogleAsync("valid-google-token");

        Assert.True(result.Success);
        Assert.Equal("social@example.com", result.Email);
        Assert.False(string.IsNullOrWhiteSpace(result.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(result.RefreshToken));

        var user = await _db.Users.SingleAsync();
        Assert.Equal("social@example.com", user.Email);
        Assert.True(user.EmailConfirmed);

        var identity = await _db.UserIdentities.SingleAsync();
        Assert.Equal(AuthProvider.Google, identity.Provider);
        Assert.Equal("google-sub-123", identity.ProviderSub);
        Assert.Equal(user.Id, identity.UserId);

        _cognito.Verify(c => c.AdminCreateUserAsync(
            It.IsAny<AdminCreateUserRequest>(),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task LoginWithAppleAsync_ExistingIdentity_ReturnsAppTokensWithoutCreatingCognitoUser()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "apple@example.com",
            EmailConfirmed = true
        };
        _db.Users.Add(user);
        _db.UserIdentities.Add(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Apple,
            ProviderSub = "apple-sub-123"
        });
        await _db.SaveChangesAsync();

        _socialVerifier.ApplePayload = new SocialTokenPayload(
            ProviderSub: "apple-sub-123",
            Email: "ignored@example.com",
            EmailVerified: true);

        var result = await _auth.LoginWithAppleAsync("valid-apple-token", "auth-code");

        Assert.True(result.Success);
        Assert.Equal(user.Id.ToString(), result.UserId);
        Assert.Equal("apple@example.com", result.Email);
        Assert.False(string.IsNullOrWhiteSpace(result.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(result.RefreshToken));

        _cognito.Verify(c => c.AdminCreateUserAsync(
            It.IsAny<AdminCreateUserRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task RefreshAsync_AppRefreshToken_IssuesNewAppAccessToken()
    {
        _socialVerifier.GooglePayload = new SocialTokenPayload(
            ProviderSub: "google-refresh-sub",
            Email: "refresh@example.com",
            EmailVerified: true);

        _cognito
            .Setup(c => c.AdminCreateUserAsync(
                It.IsAny<AdminCreateUserRequest>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminCreateUserResponse());

        var initial = await _auth.LoginWithGoogleAsync("valid-google-token");
        var refreshed = await _auth.RefreshAsync(initial.RefreshToken!);

        Assert.True(refreshed.Success);
        Assert.False(string.IsNullOrWhiteSpace(refreshed.AccessToken));
        Assert.Equal(initial.RefreshToken, refreshed.RefreshToken);
        Assert.Equal(initial.UserId, refreshed.UserId);
        Assert.Equal("refresh@example.com", refreshed.Email);

        _cognito.Verify(c => c.InitiateAuthAsync(
            It.IsAny<InitiateAuthRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    private sealed class FakeExternalSocialTokenVerifier : IExternalSocialTokenVerifier
    {
        public SocialTokenPayload? GooglePayload { get; set; }
        public SocialTokenPayload? ApplePayload { get; set; }

        public Task<SocialTokenPayload?> VerifyGoogleAsync(string idToken, CancellationToken ct = default) =>
            Task.FromResult(GooglePayload);

        public Task<SocialTokenPayload?> VerifyAppleAsync(string identityToken, CancellationToken ct = default) =>
            Task.FromResult(ApplePayload);
    }
}
