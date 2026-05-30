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
        email = NormalizeEmail(email);
        var existing = await _repo.GetByEmailAsync(email, ct);
        if (existing is not null)
        {
            return existing.EmailConfirmed
                ? new AuthResult
                {
                    Success = false,
                    RequiresConfirmation = false,
                    Email = email,
                    Error = "Account already exists. Please sign in."
                }
                : await ResendConfirmationAsync(email, ct);
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email,
            EmailConfirmed = false
        };
        await _repo.AddAsync(user, ct);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = email,
            HasPassword = true
        }, ct);

        return new AuthResult
        {
            Success = true,
            RequiresConfirmation = true,
            UserId = user.Id.ToString(),
            Email = email
        };
    }

    public async Task<AuthResult> ConfirmRegistrationAsync(string email, string confirmationCode, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        if (string.IsNullOrWhiteSpace(confirmationCode))
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "Confirmation code is required"
            };
        }

        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "User not found"
            };
        }
        user.EmailConfirmed = true;
        await _repo.UpdateAsync(user, ct);
        await MarkEmailIdentityHasPasswordAsync(user, email, ct);

        return new AuthResult
        {
            Success = true,
            RequiresConfirmation = false,
            UserId = user.Id.ToString(),
            Email = email
        };
    }

    public async Task<AuthResult> ResendConfirmationAsync(string email, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "User not found"
            };
        }

        return new AuthResult
        {
            Success = true,
            RequiresConfirmation = true,
            UserId = user.Id.ToString(),
            Email = email
        };
    }

    public Task<AuthResult> StartPasswordResetAsync(string email, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        return Task.FromResult(new AuthResult
        {
            Success = true,
            Email = email
        });
    }

    public async Task<AuthResult> ConfirmPasswordResetAsync(
        string email,
        string confirmationCode,
        string password,
        CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        if (string.IsNullOrWhiteSpace(confirmationCode))
        {
            return new AuthResult
            {
                Success = false,
                Email = email,
                Error = "Confirmation code is required"
            };
        }

        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return new AuthResult
            {
                Success = false,
                Email = email,
                Error = "Unable to reset password"
            };
        }

        user.EmailConfirmed = true;
        await _repo.UpdateAsync(user, ct);
        await MarkEmailIdentityHasPasswordAsync(user, email, ct);

        return new AuthResult
        {
            Success = true,
            Email = email,
            UserId = user.Id.ToString()
        };
    }

    public async Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
            return new AuthResult { Success = false, Error = "Invalid credentials" };

        if (!user.EmailConfirmed)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "Email confirmation required"
            };
        }

        var token = GenerateToken(user.Id.ToString(), email, "Free");
        return new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id.ToString()
        };
    }

    public async Task<AuthResult> CompletePasswordChangeAsync(
        string email,
        string session,
        string password,
        CancellationToken ct = default)
    {
        email = NormalizeEmail(email);
        var user = await _repo.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return new AuthResult { Success = false, Email = email, Error = "Invalid password change session" };
        }

        await MarkEmailIdentityHasPasswordAsync(user, email, ct);

        var token = GenerateToken(user.Id.ToString(), email, "Free");
        return new AuthResult
        {
            Success = true,
            AccessToken = token,
            RefreshToken = $"mock-refresh-{user.Id}",
            UserId = user.Id.ToString(),
            Email = email
        };
    }

    public async Task<AuthResult> RefreshAsync(string refreshToken, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(refreshToken) ||
            !refreshToken.StartsWith("mock-refresh-", StringComparison.Ordinal))
        {
            return new AuthResult { Success = false, Error = "Invalid refresh token" };
        }

        var userIdText = refreshToken["mock-refresh-".Length..];
        if (!Guid.TryParse(userIdText, out var userId))
        {
            return new AuthResult { Success = false, Error = "Invalid refresh token" };
        }

        var user = await _repo.GetByIdAsync(userId, ct);
        if (user is null)
        {
            return new AuthResult { Success = false, Error = "Invalid refresh token" };
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
            Email = email,
            EmailConfirmed = true
        };
        await _repo.AddAsync(user, ct);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = email,
            HasPassword = true
        }, ct);
    }

    private async Task MarkEmailIdentityHasPasswordAsync(User user, string email, CancellationToken ct)
    {
        var identities = await _repo.GetIdentitiesByUserAsync(user.Id, ct);
        var identity = identities.FirstOrDefault(candidate =>
            candidate.Provider == AuthProvider.Email &&
            string.Equals(candidate.ProviderSub, email, StringComparison.OrdinalIgnoreCase));
        if (identity is null)
        {
            await _repo.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Provider = AuthProvider.Email,
                ProviderSub = email,
                HasPassword = true
            }, ct);
            return;
        }

        if (!identity.HasPassword)
        {
            identity.HasPassword = true;
            await _repo.UpdateIdentityAsync(identity, ct);
        }
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
