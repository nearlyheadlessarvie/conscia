using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace Conscia.Api.Middleware;

public interface ICognitoUserInfoClaimsProvider
{
    Task<IReadOnlyList<Claim>> GetClaimsAsync(string accessToken, CancellationToken ct);
}

public sealed class CognitoUserInfoClaimsProvider : ICognitoUserInfoClaimsProvider
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(55);

    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CognitoUserInfoClaimsProvider> _logger;

    public CognitoUserInfoClaimsProvider(
        HttpClient http,
        IMemoryCache cache,
        IConfiguration configuration,
        ILogger<CognitoUserInfoClaimsProvider> logger)
    {
        _http = http;
        _cache = cache;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<IReadOnlyList<Claim>> GetClaimsAsync(string accessToken, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return [];
        }

        var endpoint = ResolveUserInfoEndpoint();
        if (endpoint is null)
        {
            return [];
        }

        var cacheKey = $"cognito-userinfo:{TokenHash(accessToken)}";
        if (_cache.TryGetValue(cacheKey, out IReadOnlyList<Claim>? cachedClaims) &&
            cachedClaims is not null)
        {
            return cachedClaims;
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var response = await _http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogDebug(
                    "Cognito userInfo returned {StatusCode}; continuing with token claims only.",
                    response.StatusCode);
                return [];
            }

            await using var stream = await response.Content.ReadAsStreamAsync(ct);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
            var claims = ParseClaims(document);
            _cache.Set(cacheKey, claims, CacheDuration);
            return claims;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogDebug(ex, "Cognito userInfo request failed; continuing with token claims only.");
            return [];
        }
        catch (JsonException ex)
        {
            _logger.LogDebug(
                ex,
                "Cognito userInfo returned invalid JSON; continuing with token claims only.");
            return [];
        }
    }

    private Uri? ResolveUserInfoEndpoint()
    {
        var configuredEndpoint = _configuration["Auth:Cognito:UserInfoEndpoint"];
        if (!string.IsNullOrWhiteSpace(configuredEndpoint) &&
            Uri.TryCreate(configuredEndpoint, UriKind.Absolute, out var endpoint))
        {
            return endpoint;
        }

        var loginDomain = _configuration["Auth:Cognito:LoginDomain"]
            ?? _configuration["COGNITO_LOGIN_DOMAIN"];
        if (string.IsNullOrWhiteSpace(loginDomain))
        {
            return null;
        }

        var normalizedDomain = loginDomain.StartsWith("http", StringComparison.OrdinalIgnoreCase)
            ? loginDomain
            : $"https://{loginDomain}";

        return Uri.TryCreate(normalizedDomain, UriKind.Absolute, out var baseUri)
            ? new Uri(baseUri, "/oauth2/userInfo")
            : null;
    }

    private static IReadOnlyList<Claim> ParseClaims(JsonDocument document)
    {
        if (document.RootElement.ValueKind != JsonValueKind.Object)
        {
            return [];
        }

        var claims = new List<Claim>();
        foreach (var property in document.RootElement.EnumerateObject())
        {
            foreach (var value in ClaimValues(property.Value))
            {
                AddClaim(claims, property.Name, value);
                if (property.NameEquals("email"))
                {
                    AddClaim(claims, ClaimTypes.Email, value);
                }
                else if (property.NameEquals("name"))
                {
                    AddClaim(claims, ClaimTypes.Name, value);
                }
            }
        }

        return claims;
    }

    private static IEnumerable<string> ClaimValues(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => [element.GetString() ?? string.Empty],
            JsonValueKind.True => ["true"],
            JsonValueKind.False => ["false"],
            JsonValueKind.Number => [element.GetRawText()],
            JsonValueKind.Array => element
                .EnumerateArray()
                .SelectMany(ClaimValues),
            _ => []
        };
    }

    private static void AddClaim(List<Claim> claims, string type, string value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            claims.Add(new Claim(type, value));
        }
    }

    private static string TokenHash(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}

public sealed class CognitoUserInfoClaimsMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ICognitoUserInfoClaimsProvider _claimsProvider;

    public CognitoUserInfoClaimsMiddleware(
        RequestDelegate next,
        ICognitoUserInfoClaimsProvider claimsProvider)
    {
        _next = next;
        _claimsProvider = claimsProvider;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.User.Identity?.IsAuthenticated == true &&
            TryGetBearerToken(context, out var token))
        {
            var claims = await _claimsProvider.GetClaimsAsync(token, context.RequestAborted);
            if (claims.Count > 0)
            {
                context.User = RebuildPrincipal(context.User, claims);
            }
        }

        await _next(context);
    }

    private static ClaimsPrincipal RebuildPrincipal(ClaimsPrincipal principal, IReadOnlyList<Claim> newClaims)
    {
        var identities = principal.Identities
            .Select(identity =>
            {
                var clone = new ClaimsIdentity(
                    identity.Claims,
                    identity.AuthenticationType,
                    identity.NameClaimType,
                    identity.RoleClaimType);
                foreach (var claim in newClaims)
                {
                    if (!clone.HasClaim(existing => existing.Type == claim.Type))
                    {
                        clone.AddClaim(new Claim(claim.Type, claim.Value));
                    }
                }

                return clone;
            })
            .ToList();

        if (identities.Count == 0)
        {
            identities.Add(new ClaimsIdentity(
                newClaims.Select(claim => new Claim(claim.Type, claim.Value)),
                "CognitoUserInfo"));
        }

        return new ClaimsPrincipal(identities);
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
}
