using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Formats.Cbor;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Nodes;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Amazon.Runtime.Documents;
using Conscia.Application.DTOs;
using Conscia.Application.Exceptions;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public sealed class CognitoPasskeyAuthService : IPasskeyAuthService
{
    private const string NoRegisteredPasskeyMessage =
        "No passkey is registered for this account yet. Sign in with your password, then set up a passkey in Settings.";

    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly IUserRepository _users;
    private readonly ILogger<CognitoPasskeyAuthService> _logger;
    private readonly string _clientId;

    public CognitoPasskeyAuthService(
        IConfiguration configuration,
        IAmazonCognitoIdentityProvider cognito,
        IUserRepository users,
        ILogger<CognitoPasskeyAuthService> logger)
    {
        _cognito = cognito;
        _users = users;
        _logger = logger;
        _clientId = configuration["Auth:Cognito:ClientId"]
            ?? throw new InvalidOperationException("Auth:Cognito:ClientId not configured");
    }

    public async Task<StartPasskeyRegistrationResponse> StartRegistrationAsync(string accessToken, CancellationToken ct = default)
    {
        var response = await _cognito.StartWebAuthnRegistrationAsync(
            new StartWebAuthnRegistrationRequest
            {
                AccessToken = accessToken
            },
            ct);

        var credentialCreationOptions = SerializeDocument(response.CredentialCreationOptions);
        if (string.IsNullOrWhiteSpace(credentialCreationOptions))
        {
            throw new InvalidOperationException("Cognito did not return passkey registration options.");
        }

        return new StartPasskeyRegistrationResponse(credentialCreationOptions);
    }

    public async Task CompleteRegistrationAsync(string accessToken, string credential, CancellationToken ct = default)
    {
        var cognitoCredential = EnrichRegistrationCredentialJson(credential);
        try
        {
            await _cognito.CompleteWebAuthnRegistrationAsync(
                new CompleteWebAuthnRegistrationRequest
                {
                    AccessToken = accessToken,
                    Credential = ParseJsonDocument(cognitoCredential)
                },
                ct);
        }
        catch (InvalidParameterException ex) when (IsCredentialDataInvalid(ex))
        {
            _logger.LogWarning(
                ex,
                "Cognito rejected passkey registration credential. Summary: {@CredentialSummary}",
                SummarizeCredential(cognitoCredential));

            throw new PasskeyRegistrationFailedException(
                "Passkey setup could not be completed on this device. Remove the saved passkey from this device, then try again.");
        }
    }

    private static bool IsCredentialDataInvalid(InvalidParameterException ex)
        => ex.Message.Contains("Credential data is not valid", StringComparison.OrdinalIgnoreCase);

    private static Dictionary<string, object?> SummarizeCredential(string credential)
    {
        try
        {
            using var payload = JsonDocument.Parse(credential);
            if (payload.RootElement.ValueKind != JsonValueKind.Object)
            {
                return new Dictionary<string, object?>
                {
                    ["rootKind"] = payload.RootElement.ValueKind.ToString()
                };
            }

            var root = payload.RootElement;
            var summary = new Dictionary<string, object?>
            {
                ["topLevelKeys"] = root.EnumerateObject().Select(p => p.Name).Order().ToArray(),
                ["type"] = GetString(root, "type"),
                ["idLength"] = GetString(root, "id")?.Length,
                ["rawIdLength"] = GetString(root, "rawId")?.Length,
                ["idMatchesRawId"] = GetString(root, "id") == GetString(root, "rawId"),
                ["authenticatorAttachment"] = GetString(root, "authenticatorAttachment")
            };

            if (root.TryGetProperty("clientExtensionResults", out var extensions) &&
                extensions.ValueKind == JsonValueKind.Object)
            {
                summary["clientExtensionResultKeys"] = extensions
                    .EnumerateObject()
                    .Select(p => p.Name)
                    .Order()
                    .ToArray();
            }

            if (root.TryGetProperty("response", out var response) &&
                response.ValueKind == JsonValueKind.Object)
            {
                summary["responseKeys"] = response.EnumerateObject().Select(p => p.Name).Order().ToArray();
                summary["clientDataJSONLength"] = GetString(response, "clientDataJSON")?.Length;
                summary["attestationObjectLength"] = GetString(response, "attestationObject")?.Length;
                summary["authenticatorDataLength"] = GetString(response, "authenticatorData")?.Length;
                summary["publicKeyLength"] = GetString(response, "publicKey")?.Length;
                summary["publicKeyAlgorithm"] = GetInt(response, "publicKeyAlgorithm");

                if (response.TryGetProperty("transports", out var transports) &&
                    transports.ValueKind == JsonValueKind.Array)
                {
                    summary["transportValues"] = transports
                        .EnumerateArray()
                        .Where(t => t.ValueKind == JsonValueKind.String)
                        .Select(t => t.GetString())
                        .Where(t => !string.IsNullOrWhiteSpace(t))
                        .Order()
                        .ToArray();
                }

                if (GetString(response, "clientDataJSON") is { } clientDataJson)
                {
                    AddClientDataSummary(summary, clientDataJson);
                }
            }

            return summary;
        }
        catch (Exception ex) when (ex is JsonException or FormatException)
        {
            return new Dictionary<string, object?>
            {
                ["parseError"] = ex.GetType().Name
            };
        }
    }

    public async Task<IReadOnlyList<PasskeyCredentialResponse>> ListCredentialsAsync(
        string accessToken,
        CancellationToken ct = default)
    {
        var credentials = new List<PasskeyCredentialResponse>();
        string? nextToken = null;

        do
        {
            var response = await _cognito.ListWebAuthnCredentialsAsync(
                new ListWebAuthnCredentialsRequest
                {
                    AccessToken = accessToken,
                    NextToken = nextToken
                },
                ct);

            foreach (var credential in response.Credentials ?? [])
            {
                credentials.Add(new PasskeyCredentialResponse(
                    credential.CredentialId,
                    credential.FriendlyCredentialName,
                    ToDateTimeOffset(credential.CreatedAt),
                    credential.RelyingPartyId,
                    credential.AuthenticatorAttachment,
                    credential.AuthenticatorTransports?.ToArray() ?? []));
            }

            nextToken = response.NextToken;
        } while (!string.IsNullOrWhiteSpace(nextToken));

        return credentials;
    }

    public async Task DeleteCredentialAsync(
        string accessToken,
        string credentialId,
        CancellationToken ct = default)
    {
        await _cognito.DeleteWebAuthnCredentialAsync(
            new DeleteWebAuthnCredentialRequest
            {
                AccessToken = accessToken,
                CredentialId = credentialId
            },
            ct);
    }

    public async Task<StartPasskeyAuthenticationResponse> StartAuthenticationAsync(
        string email,
        CancellationToken ct = default,
        bool allowExternalPasskeys = false)
    {
        var normalizedEmail = NormalizeEmail(email);
        InitiateAuthResponse response;
        try
        {
            response = await _cognito.InitiateAuthAsync(new InitiateAuthRequest
            {
                ClientId = _clientId,
                AuthFlow = AuthFlowType.USER_AUTH,
                AuthParameters = new Dictionary<string, string>
                {
                    ["USERNAME"] = normalizedEmail,
                    ["PREFERRED_CHALLENGE"] = "WEB_AUTHN"
                }
            }, ct);
        }
        catch (UserNotFoundException)
        {
            throw new PasskeyAuthenticationUnavailableException(NoRegisteredPasskeyMessage);
        }

        var challengeName = response.ChallengeName?.Value;
        if (string.IsNullOrWhiteSpace(challengeName))
        {
            throw CreatePasskeyUnavailable(normalizedEmail, response, "missing challenge");
        }

        if (response.ChallengeParameters is null ||
            !response.ChallengeParameters.TryGetValue("CREDENTIAL_REQUEST_OPTIONS", out var requestOptions))
        {
            throw CreatePasskeyUnavailable(normalizedEmail, response, "missing credential request options");
        }

        var credentialRequestOptions = SerializeDocument(requestOptions);
        if (string.IsNullOrWhiteSpace(credentialRequestOptions))
        {
            throw CreatePasskeyUnavailable(normalizedEmail, response, "blank credential request options");
        }

        if (allowExternalPasskeys)
        {
            credentialRequestOptions = AddHybridTransportToAllowedCredentials(credentialRequestOptions);
        }

        return new StartPasskeyAuthenticationResponse(
            response.Session ?? string.Empty,
            challengeName,
            credentialRequestOptions);
    }

    public async Task<AuthResult> CompleteAuthenticationAsync(
        string email,
        string session,
        string challengeName,
        string credential,
        CancellationToken ct = default)
    {
        var normalizedEmail = NormalizeEmail(email);
        var challengeResponses = new Dictionary<string, string>
        {
            ["USERNAME"] = normalizedEmail,
            ["CREDENTIAL"] = credential
        };

        if (string.Equals(challengeName, ChallengeNameType.SELECT_CHALLENGE.Value, StringComparison.Ordinal))
        {
            challengeResponses["ANSWER"] = ChallengeNameType.WEB_AUTHN.Value;
        }

        var response = await _cognito.RespondToAuthChallengeAsync(new RespondToAuthChallengeRequest
        {
            ClientId = _clientId,
            Session = session,
            ChallengeName = new ChallengeNameType(challengeName),
            ChallengeResponses = challengeResponses
        }, ct);

        if (response.AuthenticationResult is null)
        {
            throw new InvalidOperationException("Cognito passkey authentication did not return tokens.");
        }

        return await TokensToAuthResultAsync(response.AuthenticationResult, normalizedEmail, ct);
    }

    private async Task<AuthResult> TokensToAuthResultAsync(
        AuthenticationResultType tokens,
        string emailFallback,
        CancellationToken ct)
    {
        var tokenForClaims = !string.IsNullOrWhiteSpace(tokens.IdToken)
            ? tokens.IdToken
            : tokens.AccessToken;
        var (userId, email) = ReadClaims(tokenForClaims);
        email ??= emailFallback;

        User? user = null;
        if (userId is not null && email is not null)
        {
            user = await EnsureLocalUserAsync(userId.Value, email, ct);
        }

        return new AuthResult
        {
            Success = true,
            AccessToken = tokens.AccessToken,
            RefreshToken = tokens.RefreshToken,
            UserId = user?.Id.ToString() ?? userId?.ToString(),
            Email = email
        };
    }

    private async Task<User> EnsureLocalUserAsync(Guid userId, string email, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? await _users.GetByEmailAsync(email, ct);
        if (user is null)
        {
            user = new User
            {
                Id = userId,
                Email = email,
                EmailConfirmed = true
            };
            await _users.AddAsync(user, ct);
        }
        else if (!user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            await _users.UpdateAsync(user, ct);
        }

        var existingIdentity = await _users.GetByProviderAsync(AuthProvider.Email, email, ct);
        if (existingIdentity is null)
        {
            await _users.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Provider = AuthProvider.Email,
                ProviderSub = email,
                HasPassword = false
            }, ct);
        }

        return user;
    }

    private static (Guid? UserId, string? Email) ReadClaims(string? token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return (null, null);
        }

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);
        var sub = jwt.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;
        var email = jwt.Claims.FirstOrDefault(c => c.Type == "email" || c.Type == ClaimTypes.Email)?.Value;

        return Guid.TryParse(sub, out var userId)
            ? (userId, email)
            : (null, email);
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    private static string? GetString(JsonElement element, string propertyName)
        => element.TryGetProperty(propertyName, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static int? GetInt(JsonElement element, string propertyName)
        => element.TryGetProperty(propertyName, out var value) && value.TryGetInt32(out var intValue)
            ? intValue
            : null;

    private static void AddClientDataSummary(Dictionary<string, object?> summary, string encodedClientData)
    {
        try
        {
            var decoded = DecodeBase64Url(encodedClientData);
            using var clientData = JsonDocument.Parse(decoded);
            if (clientData.RootElement.ValueKind != JsonValueKind.Object)
            {
                summary["clientDataRootKind"] = clientData.RootElement.ValueKind.ToString();
                return;
            }

            var root = clientData.RootElement;
            summary["clientDataType"] = GetString(root, "type");
            summary["clientDataOrigin"] = GetString(root, "origin");
            summary["clientDataChallengeLength"] = GetString(root, "challenge")?.Length;
            if (root.TryGetProperty("crossOrigin", out var crossOrigin) &&
                crossOrigin.ValueKind is JsonValueKind.True or JsonValueKind.False)
            {
                summary["clientDataCrossOrigin"] = crossOrigin.GetBoolean();
            }
        }
        catch (Exception ex) when (ex is JsonException or FormatException)
        {
            summary["clientDataParseError"] = ex.GetType().Name;
        }
    }

    private static byte[] DecodeBase64Url(string value)
    {
        var base64 = value.Replace('-', '+').Replace('_', '/');
        var padding = base64.Length % 4;
        if (padding > 0)
        {
            base64 = base64.PadRight(base64.Length + 4 - padding, '=');
        }

        return Convert.FromBase64String(base64);
    }

    private static string Base64UrlEncode(byte[] value)
        => Convert.ToBase64String(value)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');

    private sealed record WebAuthnAttestationData(
        byte[] AuthenticatorData,
        int PublicKeyAlgorithm,
        byte[]? PublicKey);

    private sealed record CosePublicKey(
        int? KeyType,
        int Algorithm,
        int? Curve,
        byte[]? X,
        byte[]? Y,
        byte[]? Modulus,
        byte[]? Exponent);

    private static DateTimeOffset? ToDateTimeOffset(DateTime? createdAt)
        => createdAt is null || createdAt.Value == default
            ? null
            : new DateTimeOffset(DateTime.SpecifyKind(createdAt.Value, DateTimeKind.Utc));

    private static string? SerializeDocument(Document? document)
    {
        if (!document.HasValue || document.Value.IsNull())
        {
            return null;
        }

        var value = document.Value;
        return value.IsString()
            ? value.AsString()
            : JsonSerializer.Serialize(ToJsonValue(value));
    }

    private static string? SerializeDocument(string? documentJson)
        => documentJson;

    private static string AddHybridTransportToAllowedCredentials(string credentialRequestOptions)
    {
        var node = JsonNode.Parse(credentialRequestOptions);
        if (node is not JsonObject root ||
            root["allowCredentials"] is not JsonArray allowedCredentials)
        {
            return credentialRequestOptions;
        }

        foreach (var credential in allowedCredentials.OfType<JsonObject>())
        {
            if (credential["transports"] is not JsonArray transports ||
                HasTransport(transports, "hybrid"))
            {
                continue;
            }

            transports.Add("hybrid");
        }

        return root.ToJsonString();
    }

    private static bool HasTransport(JsonArray transports, string expected)
        => transports.Any(transport =>
            transport is JsonValue value &&
            value.TryGetValue<string>(out var actual) &&
            string.Equals(actual, expected, StringComparison.OrdinalIgnoreCase));

    private static Document ParseJsonDocument(string json)
    {
        using var payload = JsonDocument.Parse(json);
        return ToDocument(payload.RootElement);
    }

    private static string EnrichRegistrationCredentialJson(string json)
    {
        var node = JsonNode.Parse(json);
        if (node is not JsonObject root ||
            root["response"] is not JsonObject response ||
            response["attestationObject"]?.GetValue<string>() is not { Length: > 0 } attestationObject)
        {
            return json;
        }

        var extracted = TryExtractWebAuthnAttestation(attestationObject);
        if (extracted is null)
        {
            return json;
        }

        response["authenticatorData"] ??= Base64UrlEncode(extracted.AuthenticatorData);
        response["publicKeyAlgorithm"] ??= extracted.PublicKeyAlgorithm;

        if (response["transports"] is not JsonArray { Count: > 0 })
        {
            root["authenticatorAttachment"] ??= "platform";
            response["transports"] = new JsonArray("internal");
        }

        if (extracted.PublicKey is { Length: > 0 })
        {
            response["publicKey"] ??= Base64UrlEncode(extracted.PublicKey);
        }

        return root.ToJsonString();
    }

    private static WebAuthnAttestationData? TryExtractWebAuthnAttestation(string attestationObject)
    {
        try
        {
            var attestationBytes = DecodeBase64Url(attestationObject);
            var reader = new CborReader(attestationBytes, CborConformanceMode.Lax);
            var mapLength = reader.ReadStartMap();
            byte[]? authData = null;

            for (var i = 0; i < mapLength; i++)
            {
                var key = reader.ReadTextString();
                if (key == "authData")
                {
                    authData = reader.ReadByteString();
                }
                else
                {
                    reader.SkipValue();
                }
            }

            if (authData is null)
            {
                return null;
            }

            var coseKey = TryReadCredentialPublicKey(authData);
            return coseKey is null
                ? null
                : new WebAuthnAttestationData(
                    authData,
                    coseKey.Algorithm,
                    TryExportPublicKey(coseKey));
        }
        catch (Exception ex) when (ex is CborContentException or FormatException or CryptographicException or InvalidOperationException)
        {
            return null;
        }
    }

    private static CosePublicKey? TryReadCredentialPublicKey(byte[] authData)
    {
        const byte attestedCredentialDataFlag = 0x40;
        const int fixedAuthDataLength = 37;
        const int aaguidLength = 16;
        const int credentialIdLengthBytes = 2;

        if (authData.Length < fixedAuthDataLength ||
            (authData[32] & attestedCredentialDataFlag) == 0)
        {
            return null;
        }

        var offset = fixedAuthDataLength + aaguidLength;
        if (authData.Length < offset + credentialIdLengthBytes)
        {
            return null;
        }

        var credentialIdLength = (authData[offset] << 8) | authData[offset + 1];
        offset += credentialIdLengthBytes + credentialIdLength;
        if (authData.Length <= offset)
        {
            return null;
        }

        var reader = new CborReader(authData[offset..], CborConformanceMode.Lax);
        var mapLength = reader.ReadStartMap();
        int? keyType = null;
        int? algorithm = null;
        int? curve = null;
        byte[]? x = null;
        byte[]? y = null;
        byte[]? modulus = null;
        byte[]? exponent = null;

        for (var i = 0; i < mapLength; i++)
        {
            var key = reader.ReadInt32();
            switch (key)
            {
                case 1:
                    keyType = reader.ReadInt32();
                    break;
                case 3:
                    algorithm = reader.ReadInt32();
                    break;
                case -1 when keyType == 2:
                    curve = reader.ReadInt32();
                    break;
                case -2 when keyType == 2:
                    x = reader.ReadByteString();
                    break;
                case -3 when keyType == 2:
                    y = reader.ReadByteString();
                    break;
                case -1 when keyType == 3:
                    modulus = reader.ReadByteString();
                    break;
                case -2 when keyType == 3:
                    exponent = reader.ReadByteString();
                    break;
                default:
                    reader.SkipValue();
                    break;
            }
        }

        return algorithm is null
            ? null
            : new CosePublicKey(
                keyType,
                algorithm.Value,
                curve,
                x,
                y,
                modulus,
                exponent);
    }

    private static byte[]? TryExportPublicKey(CosePublicKey key)
    {
        if (key.KeyType == 2 &&
            key.Curve == 1 &&
            key.X is { Length: 32 } x &&
            key.Y is { Length: 32 } y)
        {
            using var ecdsa = ECDsa.Create(new ECParameters
            {
                Curve = ECCurve.NamedCurves.nistP256,
                Q = new ECPoint
                {
                    X = x,
                    Y = y
                }
            });
            return ecdsa.ExportSubjectPublicKeyInfo();
        }

        if (key.KeyType == 3 &&
            key.Modulus is { Length: > 0 } modulus &&
            key.Exponent is { Length: > 0 } exponent)
        {
            using var rsa = RSA.Create();
            rsa.ImportParameters(new RSAParameters
            {
                Modulus = modulus,
                Exponent = exponent
            });
            return rsa.ExportSubjectPublicKeyInfo();
        }

        return null;
    }

    private static Document ToDocument(JsonElement element)
        => element.ValueKind switch
        {
            JsonValueKind.Object => new Document(ToDocumentDictionary(element)),
            JsonValueKind.Array => new Document(element
                .EnumerateArray()
                .Select(ToDocument)
                .ToArray()),
            JsonValueKind.String => new Document(element.GetString() ?? string.Empty),
            JsonValueKind.Number when element.TryGetInt32(out var intValue) => new Document(intValue),
            JsonValueKind.Number when element.TryGetInt64(out var longValue) => new Document(longValue),
            JsonValueKind.Number => new Document(element.GetDouble()),
            JsonValueKind.True => new Document(true),
            JsonValueKind.False => new Document(false),
            _ => Document.FromObject(null)
        };

    private static Dictionary<string, Document> ToDocumentDictionary(JsonElement element)
    {
        var values = new Dictionary<string, Document>();
        foreach (var property in element.EnumerateObject())
        {
            var value = ToDocumentProperty(property);
            if (value.HasValue)
            {
                values[property.Name] = value.Value;
            }
        }

        return values;
    }

    private static Document? ToDocumentProperty(JsonProperty property)
    {
        if (property.NameEquals("transports") &&
            property.Value.ValueKind == JsonValueKind.Array)
        {
            var transports = property.Value
                .EnumerateArray()
                .Select(element => element.ValueKind == JsonValueKind.String
                    ? NormalizeWebAuthnTransport(element.GetString())
                    : null)
                .Where(transport => transport is not null)
                .Select(transport => new Document(transport!))
                .ToArray();

            return transports.Length == 0
                ? (Document?)null
                : new Document(transports);
        }

        return ToDocument(property.Value);
    }

    private static string? NormalizeWebAuthnTransport(string? transport)
    {
        return transport?.Trim().ToLowerInvariant() switch
        {
            "usb" => "usb",
            "nfc" => "nfc",
            "ble" => "ble",
            "bluetooth" => "ble",
            "smart-card" => "smart-card",
            "hybrid" => "hybrid",
            "internal" => "internal",
            _ => null
        };
    }

    private static object? ToJsonValue(Document document)
        => document switch
        {
            _ when document.IsNull() => null,
            _ when document.IsBool() => document.AsBool(),
            _ when document.IsDouble() => document.AsDouble(),
            _ when document.IsInt() => document.AsInt(),
            _ when document.IsLong() => document.AsLong(),
            _ when document.IsString() => document.AsString(),
            _ when document.IsList() => document.AsList().Select(ToJsonValue).ToList(),
            _ when document.IsDictionary() => document.AsDictionary()
                .ToDictionary(pair => pair.Key, pair => ToJsonValue(pair.Value)),
            _ => throw new InvalidOperationException("Unsupported Cognito passkey document value.")
        };

    private PasskeyAuthenticationUnavailableException CreatePasskeyUnavailable(
        string email,
        InitiateAuthResponse response,
        string reason)
    {
        var availableChallenges = response.AvailableChallenges is null
            ? string.Empty
            : string.Join(",", response.AvailableChallenges);
        var challengeParameters = response.ChallengeParameters is null
            ? string.Empty
            : string.Join(",", response.ChallengeParameters.Keys);

        _logger.LogWarning(
            "Cognito passkey sign-in unavailable for {Email}. Reason: {Reason}; ChallengeName: {ChallengeName}; AvailableChallenges: {AvailableChallenges}; ChallengeParameters: {ChallengeParameters}",
            email,
            reason,
            response.ChallengeName?.Value,
            availableChallenges,
            challengeParameters);

        return new PasskeyAuthenticationUnavailableException(NoRegisteredPasskeyMessage);
    }
}
