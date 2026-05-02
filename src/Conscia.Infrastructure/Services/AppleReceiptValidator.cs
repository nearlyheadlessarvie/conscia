using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Conscia.Application.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

public record AppleTransactionInfo(
    string TransactionId,
    string ProductId,
    DateTime ExpiresDate,
    bool IsRevoked);

public interface IAppleReceiptValidator
{
    bool IsConfigured { get; }
    Task<AppleTransactionInfo?> ValidateAsync(string signedTransactionInfo, CancellationToken ct = default);
}

public class AppleReceiptValidator : IAppleReceiptValidator
{
    private readonly AppleStoreOptions _options;
    private readonly HttpClient _http;
    private readonly ILogger<AppleReceiptValidator> _logger;

    private const string ProductionUrl = "https://api.storekit.itunes.apple.com";
    private const string SandboxUrl = "https://api.storekit-sandbox.itunes.apple.com";

    public AppleReceiptValidator(
        IOptions<AppleStoreOptions> options,
        HttpClient http,
        ILogger<AppleReceiptValidator> logger)
    {
        _options = options.Value;
        _http = http;
        _logger = logger;
    }

    public bool IsConfigured => _options.IsConfigured;

    public async Task<AppleTransactionInfo?> ValidateAsync(string signedTransactionInfo, CancellationToken ct = default)
    {
        if (!IsConfigured)
            return null;

        try
        {
            var jwt = GenerateAppStoreJwt();

            var response = await TryGetTransactionInfo(ProductionUrl, signedTransactionInfo, jwt, ct);

            if (response is null)
            {
                _logger.LogInformation("Production lookup returned null, falling back to sandbox");
                response = await TryGetTransactionInfo(SandboxUrl, signedTransactionInfo, jwt, ct);
            }

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Apple receipt validation failed for transaction");
            return null;
        }
    }

    private async Task<AppleTransactionInfo?> TryGetTransactionInfo(
        string baseUrl, string transactionId, string jwt, CancellationToken ct)
    {
        var url = $"{baseUrl}/inApps/v1/transactions/{transactionId}";
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", jwt);
        var response = await _http.SendAsync(request, ct);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogDebug("Apple API returned {StatusCode} from {Url}", response.StatusCode, baseUrl);
            return null;
        }

        var json = await response.Content.ReadAsStringAsync(ct);
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        if (!root.TryGetProperty("signedTransactionInfo", out var signedInfo))
            return null;

        var payload = DecodeJwsPayload(signedInfo.GetString()!);
        using var payloadDoc = JsonDocument.Parse(payload);
        var txn = payloadDoc.RootElement;

        var expiresMs = txn.GetProperty("expiresDate").GetInt64();
        var expiresDate = DateTimeOffset.FromUnixTimeMilliseconds(expiresMs).UtcDateTime;

        return new AppleTransactionInfo(
            TransactionId: txn.GetProperty("originalTransactionId").GetString()!,
            ProductId: txn.GetProperty("productId").GetString()!,
            ExpiresDate: expiresDate,
            IsRevoked: txn.TryGetProperty("revocationDate", out _));
    }

    private string GenerateAppStoreJwt()
    {
        var keyBytes = Convert.FromBase64String(_options.PrivateKey!);
        using var ecdsa = ECDsa.Create();
        ecdsa.ImportPkcs8PrivateKey(keyBytes, out _);

        var now = DateTimeOffset.UtcNow;
        var header = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            alg = "ES256",
            kid = _options.KeyId,
            typ = "JWT"
        }));
        var payload = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            iss = _options.IssuerId,
            iat = now.ToUnixTimeSeconds(),
            exp = now.AddMinutes(20).ToUnixTimeSeconds(),
            aud = "appstoreconnect-v1",
            bid = _options.BundleId
        }));

        var signingInput = $"{header}.{payload}";
        var signature = ecdsa.SignData(
            Encoding.UTF8.GetBytes(signingInput),
            HashAlgorithmName.SHA256);

        return $"{signingInput}.{Base64UrlEncode(signature)}";
    }

    private static string DecodeJwsPayload(string jws)
    {
        var parts = jws.Split('.');
        if (parts.Length != 3) throw new FormatException("Invalid JWS format");
        return Encoding.UTF8.GetString(Base64UrlEncoder.DecodeBytes(parts[1]));
    }

    private static string Base64UrlEncode(byte[] data) =>
        Convert.ToBase64String(data)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
}
