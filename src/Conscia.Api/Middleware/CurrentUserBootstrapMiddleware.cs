using System.Security.Claims;
using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Api.Middleware;

public sealed class CurrentUserBootstrapMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CurrentUserBootstrapMiddleware> _logger;

    public CurrentUserBootstrapMiddleware(
        RequestDelegate next,
        ILogger<CurrentUserBootstrapMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IUserRepository users)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            await EnsureLocalUserAsync(context.User, users, context.RequestAborted);
        }

        await _next(context);
    }

    private async Task EnsureLocalUserAsync(
        ClaimsPrincipal principal,
        IUserRepository users,
        CancellationToken ct)
    {
        var userIdValue = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue("sub");
        var emailValue = principal.FindFirstValue(ClaimTypes.Email)
            ?? principal.FindFirstValue("email");
        if (!Guid.TryParse(userIdValue, out var userId) || string.IsNullOrWhiteSpace(emailValue))
        {
            return;
        }

        var email = emailValue.Trim().ToLowerInvariant();
        var emailConfirmed = bool.TryParse(principal.FindFirstValue("email_verified"), out var verified) && verified;
        var (provider, providerSub) = ResolveIdentity(principal, email);

        var user = await users.GetByIdAsync(userId, ct);
        if (user is null)
        {
            user = new User
            {
                Id = userId,
                Email = email,
                EmailConfirmed = emailConfirmed,
                CreatedAt = DateTime.UtcNow
            };
            await users.AddAsync(user, ct);
        }
        else
        {
            var changed = false;
            if (!string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase))
            {
                user.Email = email;
                changed = true;
            }

            if (emailConfirmed && !user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                changed = true;
            }

            if (changed)
            {
                await users.UpdateAsync(user, ct);
            }
        }

        var existingIdentity = await users.GetByProviderAsync(provider, providerSub, ct);
        if (existingIdentity is null)
        {
            await users.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Provider = provider,
                ProviderSub = providerSub,
                Role = UserIdentityRole.Member,
                CreatedAt = DateTime.UtcNow
            }, ct);
        }
    }

    private (AuthProvider Provider, string ProviderSub) ResolveIdentity(ClaimsPrincipal principal, string email)
    {
        var identitiesJson = principal.FindFirstValue("identities");
        if (string.IsNullOrWhiteSpace(identitiesJson))
        {
            return (AuthProvider.Email, email);
        }

        try
        {
            var identities = JsonSerializer.Deserialize<List<CognitoIdentityClaim>>(identitiesJson, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            var identity = identities?.FirstOrDefault(i =>
                !string.IsNullOrWhiteSpace(i.ProviderName) &&
                !string.IsNullOrWhiteSpace(i.UserId));
            if (identity is null)
            {
                return (AuthProvider.Email, email);
            }

            if (string.Equals(identity.ProviderName, "Google", StringComparison.OrdinalIgnoreCase))
            {
                return (AuthProvider.Google, identity.UserId!);
            }

            if (string.Equals(identity.ProviderName, "SignInWithApple", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(identity.ProviderName, "Apple", StringComparison.OrdinalIgnoreCase))
            {
                return (AuthProvider.Apple, identity.UserId!);
            }
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Unable to parse Cognito identities claim");
        }

        return (AuthProvider.Email, email);
    }

    private sealed record CognitoIdentityClaim(string? ProviderName, string? UserId);
}
