using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text.Json;
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
        await _cognito.CompleteWebAuthnRegistrationAsync(
            new CompleteWebAuthnRegistrationRequest
            {
                AccessToken = accessToken,
                Credential = ParseJsonDocument(credential)
            },
            ct);
    }

    public async Task<StartPasskeyAuthenticationResponse> StartAuthenticationAsync(string email, CancellationToken ct = default)
    {
        var normalizedEmail = NormalizeEmail(email);
        var response = await _cognito.InitiateAuthAsync(new InitiateAuthRequest
        {
            ClientId = _clientId,
            AuthFlow = AuthFlowType.USER_AUTH,
            AuthParameters = new Dictionary<string, string>
            {
                ["USERNAME"] = normalizedEmail,
                ["PREFERRED_CHALLENGE"] = "WEB_AUTHN"
            }
        }, ct);

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

        if (userId is not null && email is not null)
        {
            await EnsureLocalUserAsync(userId.Value, email, ct);
        }

        return new AuthResult
        {
            Success = true,
            AccessToken = tokens.AccessToken,
            RefreshToken = tokens.RefreshToken,
            UserId = userId?.ToString(),
            Email = email
        };
    }

    private async Task EnsureLocalUserAsync(Guid userId, string email, CancellationToken ct)
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

    private static Document ParseJsonDocument(string json)
    {
        using var payload = JsonDocument.Parse(json);
        return ToDocument(payload.RootElement);
    }

    private static Document ToDocument(JsonElement element)
        => element.ValueKind switch
        {
            JsonValueKind.Object => new Document(element
                .EnumerateObject()
                .ToDictionary(property => property.Name, property => ToDocument(property.Value))),
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
