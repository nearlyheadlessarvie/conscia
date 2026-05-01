using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;

namespace Conscia.Tests.Unit.Infrastructure;

public class MockAuthServiceTests
{
    private readonly MockAuthService _auth;
    private const string SigningKey = "super-secret-dev-key-at-least-32-chars-long!!";

    public MockAuthServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:MockSigningKey"] = SigningKey
            })
            .Build();

        _auth = new MockAuthService(config);
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
    public async Task Login_InvalidPassword_ReturnsError()
    {
        await _auth.RegisterAsync("wrongpass@test.com", "correct");
        var result = await _auth.LoginAsync("wrongpass@test.com", "wrong");

        Assert.False(result.Success);
        Assert.Equal("Invalid credentials", result.Error);
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
        _auth.SeedUser("test-id", "premium@test.com", "pass", "Premium");
        var result = await _auth.LoginAsync("premium@test.com", "pass");

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(result.AccessToken);
        var tier = jwt.Claims.First(c => c.Type == "tier").Value;

        Assert.Equal("Premium", tier);
    }

    [Fact]
    public async Task Token_ContainsUserIdClaim()
    {
        _auth.SeedUser("my-user-id", "claims@test.com", "pass", "Free");
        var result = await _auth.LoginAsync("claims@test.com", "pass");

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(result.AccessToken);
        var sub = jwt.Claims.First(c => c.Type == "sub").Value;

        Assert.Equal("my-user-id", sub);
    }

    [Fact]
    public void SeedUser_AllowsLoginWithSeededCredentials()
    {
        _auth.SeedUser("seed-id", "seeded@test.com", "seedpass", "Premium");
        var result = _auth.LoginAsync("seeded@test.com", "seedpass").Result;

        Assert.True(result.Success);
        Assert.Equal("seed-id", result.UserId);
    }
}
