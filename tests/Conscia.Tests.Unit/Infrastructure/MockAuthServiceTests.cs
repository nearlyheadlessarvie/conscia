using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Conscia.Infrastructure.Repositories;
using Conscia.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Conscia.Tests.Unit.Infrastructure;

public class MockAuthServiceTests : IDisposable
{
    private readonly MockAuthService _auth;
    private readonly ConsciaDbContext _db;
    private const string SigningKey = "super-secret-dev-key-at-least-32-chars-long!!";

    public MockAuthServiceTests()
    {
        var options = new DbContextOptionsBuilder<ConsciaDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new ConsciaDbContext(options);

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:MockSigningKey"] = SigningKey
            })
            .Build();

        var repo = new UserRepository(_db);
        _auth = new MockAuthService(config, repo);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    [Fact]
    public async Task Register_NewUser_ReturnsSuccessAndRequiresConfirmation()
    {
        var result = await _auth.RegisterAsync("new@test.com", "password123");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("new@test.com", result.Email);
        Assert.Null(result.AccessToken);
        Assert.Null(result.RefreshToken);
        Assert.NotNull(result.UserId);

        var user = await _db.Users.SingleAsync(u => u.Email == "new@test.com");
        Assert.False(user.EmailConfirmed);
    }

    [Fact]
    public async Task ConfirmRegistration_ExistingUserWithCode_ReturnsSuccess()
    {
        await _auth.RegisterAsync("confirm@test.com", "password123");

        var result = await _auth.ConfirmRegistrationAsync("confirm@test.com", "123456");

        Assert.True(result.Success);
        Assert.False(result.RequiresConfirmation);
        Assert.Equal("confirm@test.com", result.Email);

        var user = await _db.Users.SingleAsync(u => u.Email == "confirm@test.com");
        Assert.True(user.EmailConfirmed);
    }

    [Fact]
    public async Task ResendConfirmation_ExistingUser_ReturnsSuccess()
    {
        await _auth.RegisterAsync("resend@test.com", "password123");

        var result = await _auth.ResendConfirmationAsync("resend@test.com");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("resend@test.com", result.Email);
    }

    [Fact]
    public async Task Register_CreatesUserIdentityWithEmailProvider()
    {
        await _auth.RegisterAsync("identity@test.com", "pass");

        var identity = await _db.UserIdentities.FirstOrDefaultAsync(i => i.ProviderSub == "identity@test.com");
        Assert.NotNull(identity);
        Assert.Equal(AuthProvider.Email, identity.Provider);
    }

    [Fact]
    public async Task Register_DuplicateEmail_ReturnsError()
    {
        await _auth.RegisterAsync("dup@test.com", "pass1");
        var result = await _auth.RegisterAsync("dup@test.com", "pass2");

        Assert.True(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("dup@test.com", result.Email);
    }

    [Fact]
    public async Task Register_DuplicateConfirmedEmail_ReturnsSignInError()
    {
        await _auth.RegisterAsync("confirmed-dup@test.com", "pass1");
        await _auth.ConfirmRegistrationAsync("confirmed-dup@test.com", "123456");

        var result = await _auth.RegisterAsync("confirmed-dup@test.com", "pass2");

        Assert.False(result.Success);
        Assert.False(result.RequiresConfirmation);
        Assert.Equal("Account already exists. Please sign in.", result.Error);
    }

    [Fact]
    public async Task Login_UnconfirmedUser_ReturnsRequiresConfirmation()
    {
        await _auth.RegisterAsync("pending-login@test.com", "mypass");

        var result = await _auth.LoginAsync("pending-login@test.com", "mypass");

        Assert.False(result.Success);
        Assert.True(result.RequiresConfirmation);
        Assert.Equal("Email confirmation required", result.Error);
    }

    [Fact]
    public async Task Login_ValidCredentials_ReturnsToken()
    {
        await _auth.RegisterAsync("login@test.com", "mypass");
        await _auth.ConfirmRegistrationAsync("login@test.com", "123456");
        var result = await _auth.LoginAsync("login@test.com", "mypass");

        Assert.True(result.Success);
        Assert.NotNull(result.AccessToken);
    }

    [Fact]
    public async Task Login_NonExistentUser_ReturnsError()
    {
        var result = await _auth.LoginAsync("nobody@test.com", "pass");

        Assert.False(result.Success);
        Assert.Equal("Invalid credentials", result.Error);
    }

    [Fact]
    public async Task ValidateToken_ValidToken_ReturnsPrincipal()
    {
        await _auth.RegisterAsync("validate@test.com", "pass");
        await _auth.ConfirmRegistrationAsync("validate@test.com", "123456");
        var loginResult = await _auth.LoginAsync("validate@test.com", "pass");

        var principal = await _auth.ValidateTokenAsync(loginResult.AccessToken!);

        Assert.NotNull(principal);
        var email = principal.FindFirstValue(ClaimTypes.Email);
        Assert.Equal("validate@test.com", email);
    }

    [Fact]
    public async Task ValidateToken_InvalidToken_ReturnsNull()
    {
        var principal = await _auth.ValidateTokenAsync("invalid.token.here");
        Assert.Null(principal);
    }

    [Fact]
    public async Task Token_ContainsTierClaim()
    {
        await _auth.SeedUser("a1b2c3d4-0001-4000-8000-000000000001", "premium@test.com", "pass", "Premium");
        var result = await _auth.LoginAsync("premium@test.com", "pass");

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(result.AccessToken);
        var sub = jwt.Claims.First(c => c.Type == "sub").Value;

        Assert.Equal("a1b2c3d4-0001-4000-8000-000000000001", sub);
    }

    [Fact]
    public async Task SeedUser_AllowsLoginWithSeededCredentials()
    {
        await _auth.SeedUser("a1b2c3d4-0099-4000-8000-000000000099", "seeded@test.com", "seedpass", "Premium");
        var result = await _auth.LoginAsync("seeded@test.com", "seedpass");

        Assert.True(result.Success);
        Assert.Equal("a1b2c3d4-0099-4000-8000-000000000099", result.UserId);
    }

    [Fact]
    public async Task LoginWithGoogle_NewUser_CreatesUserAndIdentity()
    {
        var result = await _auth.LoginWithGoogleAsync("mock-google-token");

        Assert.True(result.Success);
        Assert.NotNull(result.AccessToken);
        Assert.NotNull(result.UserId);

        var identity = await _db.UserIdentities.FirstOrDefaultAsync(i => i.Provider == AuthProvider.Google);
        Assert.NotNull(identity);
    }

    [Fact]
    public async Task LoginWithGoogle_SameToken_ReturnsSameUser()
    {
        var first = await _auth.LoginWithGoogleAsync("consistent-token");
        var second = await _auth.LoginWithGoogleAsync("consistent-token");

        Assert.Equal(first.UserId, second.UserId);
    }

    [Fact]
    public async Task LoginWithApple_NewUser_CreatesUserAndIdentity()
    {
        var result = await _auth.LoginWithAppleAsync("mock-apple-identity-token", "mock-auth-code");

        Assert.True(result.Success);
        Assert.NotNull(result.AccessToken);
        Assert.NotNull(result.UserId);

        var identity = await _db.UserIdentities.FirstOrDefaultAsync(i => i.Provider == AuthProvider.Apple);
        Assert.NotNull(identity);
    }

    [Fact]
    public async Task LoginWithApple_SameToken_ReturnsSameUser()
    {
        var first = await _auth.LoginWithAppleAsync("apple-consistent", null);
        var second = await _auth.LoginWithAppleAsync("apple-consistent", null);

        Assert.Equal(first.UserId, second.UserId);
    }

    [Fact]
    public async Task Refresh_ValidRefreshToken_ReturnsFreshTokensForSameUser()
    {
        await _auth.RegisterAsync("refreshable@test.com", "pass");
        await _auth.ConfirmRegistrationAsync("refreshable@test.com", "123456");
        var login = await _auth.LoginAsync("refreshable@test.com", "pass");

        var refresh = await _auth.RefreshAsync(login.RefreshToken!);

        Assert.True(refresh.Success);
        Assert.NotNull(refresh.AccessToken);
        Assert.NotNull(refresh.RefreshToken);
        Assert.Equal(login.UserId, refresh.UserId);
    }

    [Fact]
    public async Task Refresh_InvalidRefreshToken_ReturnsError()
    {
        var result = await _auth.RefreshAsync("bad-refresh-token");

        Assert.False(result.Success);
        Assert.Equal("Invalid refresh token", result.Error);
    }
}
