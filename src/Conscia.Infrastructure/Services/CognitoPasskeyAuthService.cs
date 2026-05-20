using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public sealed class CognitoPasskeyAuthService : IPasskeyAuthService
{
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
                Credential = credential
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
            throw new InvalidOperationException("Cognito did not return a passkey challenge.");
        }

        if (response.ChallengeParameters is null ||
            !response.ChallengeParameters.TryGetValue("CREDENTIAL_REQUEST_OPTIONS", out var requestOptions))
        {
            throw new InvalidOperationException("Cognito did not return passkey authentication options.");
        }

        var credentialRequestOptions = SerializeDocument(requestOptions);
        if (string.IsNullOrWhiteSpace(credentialRequestOptions))
        {
            throw new InvalidOperationException("Cognito did not return passkey authentication options.");
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
                ProviderSub = email
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

    private static string? SerializeDocument(Amazon.Runtime.Documents.Document? document)
        => document?.ToString();
}
