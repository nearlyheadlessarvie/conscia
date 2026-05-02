using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Conscia.Application.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.Infrastructure.Services;

public record GoogleSubscriptionInfo(
    string OrderId,
    string ProductId,
    DateTime ExpiryTime,
    bool IsAutoRenewing,
    bool IsCanceled);

public interface IGooglePlayValidator
{
    bool IsConfigured { get; }
    Task<GoogleSubscriptionInfo?> ValidateAsync(string purchaseToken, string subscriptionId, CancellationToken ct = default);
}

public class GooglePlayValidator : IGooglePlayValidator
{
    private readonly GooglePlayOptions _options;
    private readonly HttpClient _http;
    private readonly ILogger<GooglePlayValidator> _logger;

    private const string TokenUrl = "https://oauth2.googleapis.com/token";
    private const string AndroidPublisherUrl = "https://androidpublisher.googleapis.com/androidpublisher/v3";

    public GooglePlayValidator(
        IOptions<GooglePlayOptions> options,
        HttpClient http,
        ILogger<GooglePlayValidator> logger)
    {
        _options = options.Value;
        _http = http;
        _logger = logger;
    }

    public bool IsConfigured => _options.IsConfigured;

    public async Task<GoogleSubscriptionInfo?> ValidateAsync(
        string purchaseToken, string subscriptionId, CancellationToken ct = default)
    {
        if (!IsConfigured)
            return null;

        try
        {
            var accessToken = await GetAccessTokenAsync(ct);
            if (accessToken is null) return null;

            var url = $"{AndroidPublisherUrl}/applications/{_options.PackageName}" +
                      $"/purchases/subscriptions/{subscriptionId}/tokens/{purchaseToken}";

            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            var response = await _http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("Google Play API returned {StatusCode}: {Body}",
                    response.StatusCode, body);
                return null;
            }

            var json = await response.Content.ReadAsStringAsync(ct);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var expiryMs = long.Parse(root.GetProperty("expiryTimeMillis").GetString()!);
            var expiryTime = DateTimeOffset.FromUnixTimeMilliseconds(expiryMs).UtcDateTime;

            return new GoogleSubscriptionInfo(
                OrderId: root.TryGetProperty("orderId", out var oid) ? oid.GetString()! : "",
                ProductId: subscriptionId,
                ExpiryTime: expiryTime,
                IsAutoRenewing: root.TryGetProperty("autoRenewing", out var ar) && ar.GetBoolean(),
                IsCanceled: root.TryGetProperty("cancelReason", out _));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Google Play receipt validation failed");
            return null;
        }
    }

    private async Task<string?> GetAccessTokenAsync(CancellationToken ct)
    {
        try
        {
            var saJson = Encoding.UTF8.GetString(Convert.FromBase64String(_options.ServiceAccountJson!));
            using var saDoc = JsonDocument.Parse(saJson);
            var sa = saDoc.RootElement;

            var clientEmail = sa.GetProperty("client_email").GetString()!;
            var privateKeyPem = sa.GetProperty("private_key").GetString()!;

            var jwt = BuildGoogleJwt(clientEmail, privateKeyPem);

            var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer",
                ["assertion"] = jwt
            });

            var response = await _http.PostAsync(TokenUrl, content, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Google OAuth token request failed: {StatusCode}", response.StatusCode);
                return null;
            }

            var tokenJson = await response.Content.ReadAsStringAsync(ct);
            using var tokenDoc = JsonDocument.Parse(tokenJson);
            return tokenDoc.RootElement.GetProperty("access_token").GetString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to obtain Google access token");
            return null;
        }
    }

    private static string BuildGoogleJwt(string clientEmail, string privateKeyPem)
    {
        var now = DateTimeOffset.UtcNow;

        var header = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            alg = "RS256",
            typ = "JWT"
        }));

        var payload = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            iss = clientEmail,
            scope = "https://www.googleapis.com/auth/androidpublisher",
            aud = TokenUrl,
            iat = now.ToUnixTimeSeconds(),
            exp = now.AddHours(1).ToUnixTimeSeconds()
        }));

        var signingInput = Encoding.UTF8.GetBytes($"{header}.{payload}");

        var keyContent = privateKeyPem
            .Replace("-----BEGIN PRIVATE KEY-----", "")
            .Replace("-----END PRIVATE KEY-----", "")
            .Replace("\n", "")
            .Replace("\r", "");

        using var rsa = System.Security.Cryptography.RSA.Create();
        rsa.ImportPkcs8PrivateKey(Convert.FromBase64String(keyContent), out _);
        var signature = rsa.SignData(signingInput,
            System.Security.Cryptography.HashAlgorithmName.SHA256,
            System.Security.Cryptography.RSASignaturePadding.Pkcs1);

        return $"{header}.{payload}.{Base64UrlEncode(signature)}";
    }

    private static string Base64UrlEncode(byte[] data) =>
        Convert.ToBase64String(data)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
}
