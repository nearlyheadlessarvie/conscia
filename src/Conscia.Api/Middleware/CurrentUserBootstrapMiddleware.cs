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
    private readonly ICognitoUserInfoEmailResolver _userInfoEmailResolver;

    public CurrentUserBootstrapMiddleware(
        RequestDelegate next,
        ILogger<CurrentUserBootstrapMiddleware> logger,
        ICognitoUserInfoEmailResolver userInfoEmailResolver)
    {
        _next = next;
        _logger = logger;
        _userInfoEmailResolver = userInfoEmailResolver;
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
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return;
        }

        var email = NormalizeEmail(emailValue);
        var emailConfirmed = bool.TryParse(principal.FindFirstValue("email_verified"), out var verified) && verified;
        var resolvedIdentity = ResolveIdentity(principal, email);

        User? user = null;
        if (resolvedIdentity is { } identity)
        {
            user = await users.GetByProviderAsync(identity.Provider, identity.ProviderSub, ct);
        }

        user ??= await users.GetByIdAsync(userId, ct);
        if (email is null && !string.IsNullOrWhiteSpace(user?.Email))
        {
            email = NormalizeEmail(user.Email);
            emailConfirmed = user.EmailConfirmed;
            AddResolvedEmailClaims(context, email, emailConfirmed);
            resolvedIdentity ??= ResolveIdentity(principal, email);
        }

        if (email is null && TryGetBearerToken(context, out var accessToken))
        {
            var userInfo = await _userInfoEmailResolver.ResolveAsync(accessToken, ct);
            if (userInfo is not null)
            {
                email = userInfo.Email;
                emailConfirmed = userInfo.EmailVerified;
                AddResolvedEmailClaims(context, email, emailConfirmed);
                resolvedIdentity ??= ResolveIdentity(principal, email);
            }
        }

        if (user is null)
        {
            user = email is null
                ? null
                : await users.GetByEmailAsync(email, ct);
        }

        if (user is null)
        {
            if (email is null)
            {
                return;
            }

            user = new User
            {
                Id = userId,
                Email = email,
                EmailConfirmed = emailConfirmed,
                CreatedAt = DateTime.UtcNow
            };
            try
            {
                await users.AddAsync(user, ct);
            }
            catch (Exception ex) when (IsConditionalCreateConflict(ex))
            {
                _logger.LogInformation(
                    ex,
                    "Local user bootstrap found an existing user for {Email}; reloading before continuing.",
                    email);
                user = await users.GetByIdAsync(userId, ct)
                    ?? await users.GetByEmailAsync(email, ct);
                if (user is null)
                {
                    throw;
                }
            }
        }
        else
        {
            var changed = false;
            if (email is not null &&
                !string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase))
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

        if (resolvedIdentity is null)
        {
            return;
        }

        var existingIdentity = await users.GetByProviderAsync(
            resolvedIdentity.Value.Provider,
            resolvedIdentity.Value.ProviderSub,
            ct);
        if (existingIdentity is null)
        {
            await users.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Provider = resolvedIdentity.Value.Provider,
                ProviderSub = resolvedIdentity.Value.ProviderSub,
                Role = UserIdentityRole.Member,
                CreatedAt = DateTime.UtcNow
            }, ct);
        }
    }

    private (AuthProvider Provider, string ProviderSub)? ResolveIdentity(ClaimsPrincipal principal, string? email)
    {
        var identity = principal
            .FindAll("identities")
            .SelectMany(claim => ParseIdentityClaims(claim.Value))
            .FirstOrDefault(i =>
                !string.IsNullOrWhiteSpace(i.ProviderName) &&
                !string.IsNullOrWhiteSpace(i.UserId));
        if (identity is null)
        {
            return string.IsNullOrWhiteSpace(email)
                ? null
                : (AuthProvider.Email, email);
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

        return string.IsNullOrWhiteSpace(email)
            ? null
            : (AuthProvider.Email, email);
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

    private static string? NormalizeEmail(string? email) =>
        string.IsNullOrWhiteSpace(email)
            ? null
            : email.Trim().ToLowerInvariant();

    private static bool IsConditionalCreateConflict(Exception ex)
    {
        return ex.GetType().Name == "TransactionCanceledException" &&
            ex.Message.Contains("ConditionalCheckFailed", StringComparison.Ordinal);
    }

    private static void AddResolvedEmailClaims(HttpContext context, string? email, bool emailConfirmed)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return;
        }

        foreach (var identity in context.User.Identities)
        {
            if (!identity.HasClaim(claim => claim.Type == ClaimTypes.Email))
            {
                identity.AddClaim(new Claim(ClaimTypes.Email, email));
            }

            if (!identity.HasClaim(claim => claim.Type == "email"))
            {
                identity.AddClaim(new Claim("email", email));
            }

            if (emailConfirmed && !identity.HasClaim(claim => claim.Type == "email_verified"))
            {
                identity.AddClaim(new Claim("email_verified", "true"));
            }
        }
    }

    private static bool TryGetBearerToken(HttpContext context, out string token)
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        const string prefix = "Bearer ";
        if (authorization.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            token = authorization[prefix.Length..].Trim();
            return !string.IsNullOrWhiteSpace(token);
        }

        token = string.Empty;
        return false;
    }

    private sealed record CognitoIdentityClaim(string? ProviderName, string? UserId);
}
