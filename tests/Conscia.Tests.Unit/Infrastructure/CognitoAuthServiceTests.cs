using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
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
                ["Auth:Cognito:UserPoolId"] = "pool-123"
            })
            .Build();

        _auth = new CognitoAuthService(
            config,
            _cognito.Object,
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
}
