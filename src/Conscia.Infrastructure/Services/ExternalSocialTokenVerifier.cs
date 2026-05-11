using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

public record SocialTokenPayload(string ProviderSub, string Email, bool EmailVerified);

public interface IExternalSocialTokenVerifier
{
    Task<SocialTokenPayload?> VerifyGoogleAsync(string idToken, CancellationToken ct = default);
    Task<SocialTokenPayload?> VerifyAppleAsync(string identityToken, CancellationToken ct = default);
}

public class ExternalSocialTokenVerifier : IExternalSocialTokenVerifier
{
    private const string GoogleJwksUri = "https://www.googleapis.com/oauth2/v3/certs";
    private const string AppleJwksUri = "https://appleid.apple.com/auth/keys";

    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly ILogger<ExternalSocialTokenVerifier> _logger;

    public ExternalSocialTokenVerifier(
        HttpClient http,
        IConfiguration config,
        ILogger<ExternalSocialTokenVerifier> logger)
    {
        _http = http;
        _config = config;
        _logger = logger;
    }

    public Task<SocialTokenPayload?> VerifyGoogleAsync(string idToken, CancellationToken ct = default)
    {
        var audiences = ReadAudiences("Auth:Google:ClientIds", "Auth:Google:ClientId", "Auth:Google:WebClientId");
        return VerifyAsync(
            idToken,
            GoogleJwksUri,
            ["https://accounts.google.com", "accounts.google.com"],
            audiences,
            "Google",
            ct);
    }

    public Task<SocialTokenPayload?> VerifyAppleAsync(string identityToken, CancellationToken ct = default)
    {
        var audiences = ReadAudiences("Auth:Apple:ClientIds", "Auth:Apple:ClientId", "Apple:BundleId");
        return VerifyAsync(
            identityToken,
            AppleJwksUri,
            ["https://appleid.apple.com"],
            audiences,
            "Apple",
            ct);
    }

    private async Task<SocialTokenPayload?> VerifyAsync(
        string token,
        string jwksUri,
        string[] validIssuers,
        string[] validAudiences,
        string providerName,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return null;
        }

        if (validAudiences.Length == 0)
        {
            _logger.LogWarning("{Provider} social auth is missing audience configuration", providerName);
            return null;
        }

        try
        {
            var jwks = await _http.GetStringAsync(jwksUri, ct);
            var keySet = new JsonWebKeySet(jwks);
            var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
            var principal = handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = keySet.GetSigningKeys(),
                ValidateIssuer = true,
                ValidIssuers = validIssuers,
                ValidateAudience = true,
                ValidAudiences = validAudiences,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(2)
            }, out _);

            var sub = principal.FindFirst("sub")?.Value;
            var email = principal.FindFirst("email")?.Value;
            if (string.IsNullOrWhiteSpace(sub) || string.IsNullOrWhiteSpace(email))
            {
                return null;
            }

            return new SocialTokenPayload(
                ProviderSub: sub,
                Email: email,
                EmailVerified: IsEmailVerified(principal));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "{Provider} social token validation failed", providerName);
            return null;
        }
    }

    private string[] ReadAudiences(params string[] keys)
    {
        var values = new List<string>();
        foreach (var key in keys)
        {
            values.AddRange(_config.GetSection(key)
                .GetChildren()
                .Select(child => child.Value)
                .Where(value => !string.IsNullOrWhiteSpace(value))!);

            var raw = _config[key];
            if (!string.IsNullOrWhiteSpace(raw))
            {
                values.AddRange(raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
            }
        }

        return values.Distinct(StringComparer.Ordinal).ToArray();
    }

    private static bool IsEmailVerified(ClaimsPrincipal principal)
    {
        var value = principal.FindFirst("email_verified")?.Value;
        return string.Equals(value, "true", StringComparison.OrdinalIgnoreCase)
            || string.Equals(value, "1", StringComparison.Ordinal);
    }
}
