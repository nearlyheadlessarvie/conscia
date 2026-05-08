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
    public async Task Register_NewUser_ReturnsSuccess()
    {
        var result = await _auth.RegisterAsync("new@test.com", "password123");

        Assert.True(result.Success);
        Assert.NotNull(result.AccessToken);
        Assert.NotNull(result.RefreshToken);
        Assert.NotNull(result.UserId);
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

        Assert.False(result.Success);
        Assert.Equal("User already exists", result.Error);
    }

    [Fact]
    public async Task Login_ValidCredentials_ReturnsToken()
    {
        await _auth.RegisterAsync("login@test.com", "mypass");
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
        var register = await _auth.RegisterAsync("refreshable@test.com", "pass");

        var refresh = await _auth.RefreshAsync(register.RefreshToken!);

        Assert.True(refresh.Success);
        Assert.NotNull(refresh.AccessToken);
        Assert.NotNull(refresh.RefreshToken);
        Assert.Equal(register.UserId, refresh.UserId);
    }

    [Fact]
    public async Task Refresh_InvalidRefreshToken_ReturnsError()
    {
        var result = await _auth.RefreshAsync("bad-refresh-token");

        Assert.False(result.Success);
        Assert.Equal("Invalid refresh token", result.Error);
    }
}
