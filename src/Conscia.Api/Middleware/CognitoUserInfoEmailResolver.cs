using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace Conscia.Api.Middleware;

public sealed record CognitoUserInfoEmail(string Email, bool EmailVerified);

public interface ICognitoUserInfoEmailResolver
{
    Task<CognitoUserInfoEmail?> ResolveAsync(string accessToken, CancellationToken ct);
}

public sealed class CognitoUserInfoEmailResolver : ICognitoUserInfoEmailResolver
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(55);

    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CognitoUserInfoEmailResolver> _logger;

    public CognitoUserInfoEmailResolver(
        HttpClient http,
        IMemoryCache cache,
        IConfiguration configuration,
        ILogger<CognitoUserInfoEmailResolver> logger)
    {
        _http = http;
        _cache = cache;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<CognitoUserInfoEmail?> ResolveAsync(string accessToken, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return null;
        }

        var endpoint = ResolveUserInfoEndpoint();
        if (endpoint is null)
        {
            return null;
        }

        var cacheKey = $"cognito-userinfo-email:{TokenHash(accessToken)}";
        if (_cache.TryGetValue(cacheKey, out CognitoUserInfoEmail? cachedEmail))
        {
            return cachedEmail;
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var response = await _http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogDebug(
                    "Cognito userInfo returned {StatusCode}; continuing without email hydration.",
                    response.StatusCode);
                return null;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(ct);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
            var email = ParseEmail(document);
            if (email is not null)
            {
                _cache.Set(cacheKey, email, CacheDuration);
            }

            return email;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogDebug(ex, "Cognito userInfo request failed; continuing without email hydration.");
            return null;
        }
        catch (JsonException ex)
        {
            _logger.LogDebug(ex, "Cognito userInfo returned invalid JSON; continuing without email hydration.");
            return null;
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

    private static CognitoUserInfoEmail? ParseEmail(JsonDocument document)
    {
        if (document.RootElement.ValueKind != JsonValueKind.Object ||
            !document.RootElement.TryGetProperty("email", out var emailElement) ||
            emailElement.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        var email = emailElement.GetString()?.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email))
        {
            return null;
        }

        var verified = document.RootElement.TryGetProperty("email_verified", out var verifiedElement) &&
            verifiedElement.ValueKind switch
            {
                JsonValueKind.True => true,
                JsonValueKind.String => bool.TryParse(verifiedElement.GetString(), out var value) && value,
                _ => false
            };

        return new CognitoUserInfoEmail(email, verified);
    }

    private static string TokenHash(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}
