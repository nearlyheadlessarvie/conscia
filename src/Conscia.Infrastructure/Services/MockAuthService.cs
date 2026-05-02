using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

public class MockAuthService : IAuthService
{
    private readonly string _signingKey;
    private readonly IUserRepository _repo;

    public MockAuthService(IConfiguration config, IUserRepository repo)
    {
        _signingKey = config["Auth:MockSigningKey"]
            ?? throw new InvalidOperationException("Auth:MockSigningKey not configured");
        _repo = repo;
    }

    public async Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default)
    {
        var existing = await _repo.GetByEmailAsync(email, ct);
        if (existing is not null)
            return new AuthResult { Success = false, Error = "User already exists" };

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email
        };
        await _repo.AddAsync(user, ct);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = email
        }, ct);

        var token = GenerateToken(user.Id.ToString(), email, "Free");
        return new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id.ToString()
        };
    }

    public async Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
            return new AuthResult { Success = false, Error = "Invalid credentials" };

        var token = GenerateToken(user.Id.ToString(), email, "Free");
        return new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id.ToString()
        };
    }

    public async Task<AuthResult> LoginWithGoogleAsync(string idToken, CancellationToken ct = default)
    {
        var bytes = System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(idToken));
        var mockSub = $"google_{Convert.ToHexString(bytes)[..16].ToLowerInvariant()}";
        var mockEmail = $"{mockSub}@gmail.com";

        return await ResolveOrCreateSocialUser(AuthProvider.Google, mockSub, mockEmail, ct);
    }

    public async Task<AuthResult> LoginWithAppleAsync(string identityToken, string? authorizationCode, CancellationToken ct = default)
    {
        var bytes = System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(identityToken));
        var mockSub = $"apple_{Convert.ToHexString(bytes)[..16].ToLowerInvariant()}";
        var mockEmail = $"{mockSub}@privaterelay.appleid.com";

        return await ResolveOrCreateSocialUser(AuthProvider.Apple, mockSub, mockEmail, ct);
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

    public async Task SeedUser(string id, string email, string password, string tier, CancellationToken ct = default)
    {
        var user = new User
        {
            Id = Guid.Parse(id),
            Email = email
        };
        await _repo.AddAsync(user, ct);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = email
        }, ct);
    }

    private async Task<AuthResult> ResolveOrCreateSocialUser(
        AuthProvider provider, string providerSub, string email, CancellationToken ct)
    {
        // 1. Lookup by (Provider, ProviderSub)
        var user = await _repo.GetByProviderAsync(provider, providerSub, ct);

        if (user is null)
        {
            // 2. Lookup by email to link identity
            user = await _repo.GetByEmailAsync(email, ct);

            if (user is null)
            {
                // 3. Create new user
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = email
                };
                await _repo.AddAsync(user, ct);
            }

            try
            {
                await _repo.AddIdentityAsync(new UserIdentity
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Provider = provider,
                    ProviderSub = providerSub
                }, ct);
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException)
            {
                user = await _repo.GetByProviderAsync(provider, providerSub, ct);
                if (user is null)
                    return new AuthResult { Success = false, Error = "Identity conflict — please retry" };
            }
        }

        var token = GenerateToken(user.Id.ToString(), user.Email, "Free");
        return new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id.ToString()
        };
    }
}
