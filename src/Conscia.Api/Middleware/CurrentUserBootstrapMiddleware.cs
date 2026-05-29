using System.Security.Claims;
using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.AspNetCore.Authorization;

namespace Conscia.Api.Middleware;

public sealed class CurrentUserBootstrapMiddleware
{
    private static readonly JsonSerializerOptions CognitoIdentityJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

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
        if (context.User.Identity?.IsAuthenticated == true &&
            ShouldBootstrapCurrentUser(context))
        {
            await EnsureLocalUserAsync(context, users, context.RequestAborted);
        }

        await _next(context);
    }

    private async Task EnsureLocalUserAsync(
        HttpContext context,
        IUserRepository users,
        CancellationToken ct)
    {
        var principal = context.User;
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
            user = await users.GetByEmailAsync(email, ct);
        }

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

        if (user.Id != userId)
        {
            UseLocalUserId(context, user.Id);
        }

        var existingIdentity = await users.GetByProviderAsync(provider, providerSub, ct);
        if (existingIdentity is null)
        {
            await users.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Provider = provider,
                ProviderSub = providerSub,
                Role = UserIdentityRole.Member,
                CreatedAt = DateTime.UtcNow
            }, ct);
        }
    }

    private (AuthProvider Provider, string ProviderSub) ResolveIdentity(ClaimsPrincipal principal, string email)
    {
        var identity = principal
            .FindAll("identities")
            .SelectMany(claim => ParseIdentityClaims(claim.Value))
            .FirstOrDefault(i =>
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

        return (AuthProvider.Email, email);
    }

    private IReadOnlyList<CognitoIdentityClaim> ParseIdentityClaims(string? identitiesJson)
    {
        if (string.IsNullOrWhiteSpace(identitiesJson))
        {
            return [];
        }

        try
        {
            using var document = JsonDocument.Parse(identitiesJson);
            if (document.RootElement.ValueKind == JsonValueKind.Array)
            {
                return document.RootElement
                    .EnumerateArray()
                    .Select(element => element.Deserialize<CognitoIdentityClaim>(CognitoIdentityJsonOptions))
                    .Where(identity => identity is not null)
                    .Cast<CognitoIdentityClaim>()
                    .ToList();
            }

            if (document.RootElement.ValueKind == JsonValueKind.Object)
            {
                var identity = document.RootElement.Deserialize<CognitoIdentityClaim>(CognitoIdentityJsonOptions);
                return identity is null ? [] : [identity];
            }
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Unable to parse Cognito identities claim");
        }

        return [];
    }

    private static bool ShouldBootstrapCurrentUser(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
        {
            return false;
        }

        return endpoint is null ||
            endpoint.Metadata.GetOrderedMetadata<IAuthorizeData>().Count > 0;
    }

    private static void UseLocalUserId(HttpContext context, Guid userId)
    {
        var localUserId = userId.ToString();
        foreach (var identity in context.User.Identities)
        {
            foreach (var claim in identity.FindAll(ClaimTypes.NameIdentifier).ToList())
            {
                identity.TryRemoveClaim(claim);
            }

            identity.AddClaim(new Claim(ClaimTypes.NameIdentifier, localUserId));
        }
    }

    private sealed record CognitoIdentityClaim(string? ProviderName, string? UserId);
}
