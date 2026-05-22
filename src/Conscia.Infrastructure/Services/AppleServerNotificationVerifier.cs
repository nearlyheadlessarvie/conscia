using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

public sealed class AppleServerNotificationVerifier : IAppleServerNotificationVerifier
{
    public Task<AppleServerNotification> VerifyAndDecodeAsync(string signedPayload, CancellationToken ct = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(signedPayload);

        var payloadElement = VerifyAndDecodeJwsPayload(signedPayload);

        var dataElement = payloadElement.TryGetProperty("data", out var data) ? data : default;
        var transactionInfo = dataElement.ValueKind != JsonValueKind.Undefined &&
            dataElement.TryGetProperty("signedTransactionInfo", out var signedTransactionInfo)
                ? DecodeNestedSignedInfo(signedTransactionInfo.GetString())
                : default;
        var renewalInfo = dataElement.ValueKind != JsonValueKind.Undefined &&
            dataElement.TryGetProperty("signedRenewalInfo", out var signedRenewalInfo)
                ? DecodeNestedSignedInfo(signedRenewalInfo.GetString())
                : default;

        var expiresAt = TryReadUnixMilliseconds(transactionInfo, "expiresDate")
            ?? TryReadUnixMilliseconds(renewalInfo, "gracePeriodExpiresDate");
        var revocationDate = TryReadUnixMilliseconds(transactionInfo, "revocationDate");
        var gracePeriodExpiresAt = TryReadUnixMilliseconds(renewalInfo, "gracePeriodExpiresDate");

        return Task.FromResult(new AppleServerNotification(
            payloadElement.GetProperty("notificationType").GetString()!,
            payloadElement.TryGetProperty("subtype", out var subtype) ? subtype.GetString() : null,
            DateTimeOffset.FromUnixTimeMilliseconds(payloadElement.GetProperty("signedDate").GetInt64()).UtcDateTime,
            new AppleServerNotificationData(
                payloadElement.TryGetProperty("environment", out var environment)
                    ? environment.GetString() ?? "UNKNOWN"
                    : "UNKNOWN",
                transactionInfo.TryGetProperty("originalTransactionId", out var originalTransactionId)
                    ? originalTransactionId.GetString()!
                    : throw new InvalidOperationException("Apple notification is missing originalTransactionId."),
                expiresAt,
                revocationDate,
                TryReadBoolean(renewalInfo, "isInBillingRetryPeriod"),
                gracePeriodExpiresAt,
                TryReadBoolean(renewalInfo, "autoRenewStatus"))));
    }

    private static JsonElement VerifyAndDecodeJwsPayload(string signedPayload)
    {
        var parts = signedPayload.Split('.');
        if (parts.Length != 3)
        {
            throw new InvalidOperationException("Invalid Apple signed payload format.");
        }

        using var headerDocument = JsonDocument.Parse(Encoding.UTF8.GetString(Base64UrlEncoder.DecodeBytes(parts[0])));
        var header = headerDocument.RootElement;
        if (!header.TryGetProperty("x5c", out var certificateChainElement) || certificateChainElement.GetArrayLength() == 0)
        {
            throw new InvalidOperationException("Apple signed payload is missing the x5c certificate chain.");
        }

        var certificates = certificateChainElement
            .EnumerateArray()
            .Select(certificate => new X509Certificate2(Convert.FromBase64String(certificate.GetString()!)))
            .ToList();

        var signingCertificate = certificates[0];
        var chain = new X509Chain();
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        chain.ChainPolicy.VerificationFlags = X509VerificationFlags.NoFlag;

        foreach (var extraCertificate in certificates.Skip(1))
        {
            chain.ChainPolicy.ExtraStore.Add(extraCertificate);
        }

        if (!chain.Build(signingCertificate) || chain.ChainElements.Count == 0)
        {
            throw new InvalidOperationException("Apple signed payload certificate chain is invalid.");
        }

        var rootCertificate = chain.ChainElements[^1].Certificate;
        var issuer = rootCertificate.Subject;
        if (!issuer.Contains("Apple Root", StringComparison.OrdinalIgnoreCase) &&
            !issuer.Contains("Apple Inc.", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Apple signed payload certificate chain does not terminate at an Apple root certificate.");
        }

        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new X509SecurityKey(signingCertificate),
            RequireSignedTokens = true
        };

        var handler = new JwtSecurityTokenHandler();
        handler.ValidateToken(signedPayload, tokenValidationParameters, out _);

        using var payloadDocument = JsonDocument.Parse(Encoding.UTF8.GetString(Base64UrlEncoder.DecodeBytes(parts[1])));
        return payloadDocument.RootElement.Clone();
    }

    private static JsonElement DecodeNestedSignedInfo(string? signedInfo)
    {
        if (string.IsNullOrWhiteSpace(signedInfo))
        {
            return default;
        }

        var parts = signedInfo.Split('.');
        if (parts.Length != 3)
        {
            throw new InvalidOperationException("Invalid Apple nested signed payload format.");
        }

        using var payloadDocument = JsonDocument.Parse(Encoding.UTF8.GetString(Base64UrlEncoder.DecodeBytes(parts[1])));
        return payloadDocument.RootElement.Clone();
    }

    private static DateTime? TryReadUnixMilliseconds(JsonElement element, string propertyName)
    {
        if (element.ValueKind == JsonValueKind.Undefined || !element.TryGetProperty(propertyName, out var property))
        {
            return null;
        }

        return property.ValueKind switch
        {
            JsonValueKind.Number => DateTimeOffset.FromUnixTimeMilliseconds(property.GetInt64()).UtcDateTime,
            JsonValueKind.String when long.TryParse(property.GetString(), out var milliseconds)
                => DateTimeOffset.FromUnixTimeMilliseconds(milliseconds).UtcDateTime,
            _ => null
        };
    }

    private static bool? TryReadBoolean(JsonElement element, string propertyName)
    {
        if (element.ValueKind == JsonValueKind.Undefined || !element.TryGetProperty(propertyName, out var property))
        {
            return null;
        }

        return property.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Number => property.GetInt32() != 0,
            JsonValueKind.String when bool.TryParse(property.GetString(), out var value) => value,
            JsonValueKind.String when int.TryParse(property.GetString(), out var number) => number != 0,
            _ => null
        };
    }
}
