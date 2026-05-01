using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

public class MockAuthService : IAuthService
{
    private readonly string _signingKey;
    private readonly Dictionary<string, MockUser> _users = new();

    public MockAuthService(IConfiguration config)
    {
        _signingKey = config["Auth:MockSigningKey"]
            ?? throw new InvalidOperationException("Auth:MockSigningKey not configured");
    }

    public Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default)
    {
        if (_users.ContainsKey(email))
            return Task.FromResult(new AuthResult { Success = false, Error = "User already exists" });

        var userId = Guid.NewGuid().ToString();
        _users[email] = new MockUser(userId, email, password, "Free");

        var token = GenerateToken(userId, email, "Free");

        return Task.FromResult(new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{userId}",
            UserId = userId
        });
    }

    public Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        if (!_users.TryGetValue(email, out var user) || user.Password != password)
            return Task.FromResult(new AuthResult { Success = false, Error = "Invalid credentials" });

        var token = GenerateToken(user.Id, email, user.Tier);

        return Task.FromResult(new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id
        });
    }

    public Task<ClaimsPrincipal?> ValidateTokenAsync(string token, CancellationToken ct = default)
    {
        var handler = new JwtSecurityTokenHandler();
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_signingKey));

        try
        {
            var principal = handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = "conscia-mock",
                ValidateAudience = true,
                ValidAudience = "conscia-api",
                ValidateLifetime = true,
                IssuerSigningKey = key,
                ClockSkew = TimeSpan.FromMinutes(1)
            }, out _);

            return Task.FromResult<ClaimsPrincipal?>(principal);
        }
        catch
        {
            return Task.FromResult<ClaimsPrincipal?>(null);
        }
    }

    public string GenerateToken(string userId, string email, string tier)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Email, email),
            new Claim("tier", tier),
            new Claim("sub", userId)
        };

        var token = new JwtSecurityToken(
            issuer: "conscia-mock",
            audience: "conscia-api",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public void SeedUser(string id, string email, string password, string tier)
    {
        _users[email] = new MockUser(id, email, password, tier);
    }

    private record MockUser(string Id, string Email, string Password, string Tier);
}
