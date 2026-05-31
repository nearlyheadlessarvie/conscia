using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Formats.Cbor;
using System.Text.Json;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Amazon.Runtime.Documents;
using Conscia.Application.Exceptions;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CognitoPasskeyAuthServiceTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly InMemoryUserRepository _repo = new();
    private readonly CognitoPasskeyAuthService _passkeys;

    public CognitoPasskeyAuthServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:ClientId"] = "client-123"
            })
            .Build();

        _passkeys = new CognitoPasskeyAuthService(
            config,
            _cognito.Object,
            _repo,
            NullLogger<CognitoPasskeyAuthService>.Instance);
    }

    [Fact]
    public async Task StartRegistrationAsync_ReturnsJsonCredentialCreationOptions()
    {
        _cognito
            .Setup(c => c.StartWebAuthnRegistrationAsync(
                It.Is<StartWebAuthnRegistrationRequest>(r => r.AccessToken == "access-token"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new StartWebAuthnRegistrationResponse
            {
                CredentialCreationOptions = Document.FromObject(new
                {
                    challenge = "wxvbDicyqQqvF2EXAMPLE",
                    rp = new
                    {
                        id = "getconscia.com",
                        name = "getconscia.com"
                    },
                    user = new
                    {
                        displayName = "demo@example.com",
                        id = "ZGVtby11c2VyLWlk",
                        name = "demo@example.com"
                    },
                    pubKeyCredParams = new[]
                    {
                        new { alg = -7, type = "public-key" }
                    }
                })
            });

        var result = await _passkeys.StartRegistrationAsync("access-token");

        using var payload = JsonDocument.Parse(result.CredentialCreationOptions);
        Assert.Equal("wxvbDicyqQqvF2EXAMPLE", payload.RootElement.GetProperty("challenge").GetString());
        Assert.Equal("getconscia.com", payload.RootElement.GetProperty("rp").GetProperty("id").GetString());
        Assert.Equal("demo@example.com", payload.RootElement.GetProperty("user").GetProperty("name").GetString());
    }

    [Fact]
    public async Task StartAuthenticationAsync_NoWebAuthnOptions_ThrowsFriendlyUnavailableError()
    {
        _cognito
            .Setup(c => c.InitiateAuthAsync(
                It.Is<InitiateAuthRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.AuthFlow == AuthFlowType.USER_AUTH &&
                    r.AuthParameters["USERNAME"] == "demo@example.com" &&
                    r.AuthParameters["PREFERRED_CHALLENGE"] == "WEB_AUTHN"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new InitiateAuthResponse
            {
                ChallengeName = ChallengeNameType.SELECT_CHALLENGE,
                AvailableChallenges = [ChallengeNameType.PASSWORD]
            });

        var ex = await Assert.ThrowsAsync<PasskeyAuthenticationUnavailableException>(() =>
            _passkeys.StartAuthenticationAsync(" Demo@Example.com "));

        Assert.Equal("No passkey is registered for this account yet. Sign in with your password, then set up a passkey in Settings.", ex.Message);
    }

    [Fact]
    public async Task CompleteRegistrationAsync_SendsCredentialAsJsonDocument()
    {
        const string credentialJson = """
            {
              "id": "credential-id",
              "rawId": "credential-id",
              "type": "public-key",
              "response": {
                "clientDataJSON": "client-data",
                "attestationObject": "attestation-object"
              },
              "clientExtensionResults": {}
            }
            """;

        _cognito
            .Setup(c => c.CompleteWebAuthnRegistrationAsync(
                It.Is<CompleteWebAuthnRegistrationRequest>(r =>
                    r.AccessToken == "access-token" &&
                    r.Credential.IsDictionary() &&
                    r.Credential.AsDictionary().ContainsKey("response")),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CompleteWebAuthnRegistrationResponse());

        await _passkeys.CompleteRegistrationAsync("access-token", credentialJson);

        _cognito.VerifyAll();
    }

    [Fact]
    public async Task CompleteRegistrationAsync_NormalizesInvalidRegistrationTransports()
    {
        const string credentialJson = """
            {
              "id": "credential-id",
              "rawId": "credential-id",
              "type": "public-key",
              "response": {
                "clientDataJSON": "client-data",
                "attestationObject": "attestation-object",
                "transports": ["", "bluetooth", "unknown", "internal"]
              },
              "clientExtensionResults": {}
            }
            """;

        _cognito
            .Setup(c => c.CompleteWebAuthnRegistrationAsync(
                It.Is<CompleteWebAuthnRegistrationRequest>(r =>
                    HasWebAuthnTransports(r, "ble", "internal")),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CompleteWebAuthnRegistrationResponse());

        await _passkeys.CompleteRegistrationAsync("access-token", credentialJson);

        _cognito.VerifyAll();
    }

    [Fact]
    public async Task CompleteRegistrationAsync_EnrichesMinimalIosCredentialResponse()
    {
        var credentialJson = $$"""
            {
              "id": "credential-id",
              "rawId": "credential-id",
              "type": "public-key",
              "response": {
                "clientDataJSON": "client-data",
                "attestationObject": "{{CreateAttestationObject()}}"
              },
              "clientExtensionResults": {}
            }
            """;

        _cognito
            .Setup(c => c.CompleteWebAuthnRegistrationAsync(
                It.Is<CompleteWebAuthnRegistrationRequest>(r =>
                    HasEnrichedWebAuthnFields(r)),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CompleteWebAuthnRegistrationResponse());

        await _passkeys.CompleteRegistrationAsync("access-token", credentialJson);

        _cognito.VerifyAll();
    }

    [Fact]
    public async Task CompleteRegistrationAsync_InvalidCredentialData_ThrowsFriendlyRegistrationError()
    {
        const string credentialJson = """
            {
              "id": "credential-id",
              "rawId": "credential-id",
              "type": "public-key",
              "response": {
                "clientDataJSON": "client-data",
                "attestationObject": "attestation-object"
              },
              "clientExtensionResults": {}
            }
            """;

        _cognito
            .Setup(c => c.CompleteWebAuthnRegistrationAsync(
                It.IsAny<CompleteWebAuthnRegistrationRequest>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidParameterException("Credential data is not valid"));

        var ex = await Assert.ThrowsAsync<PasskeyRegistrationFailedException>(() =>
            _passkeys.CompleteRegistrationAsync("access-token", credentialJson));

        Assert.Equal(
            "Passkey setup could not be completed on this device. Remove the saved passkey from this device, then try again.",
            ex.Message);
    }

    [Fact]
    public async Task ListCredentialsAsync_ReturnsRegisteredPasskeys()
    {
        _cognito
            .Setup(c => c.ListWebAuthnCredentialsAsync(
                It.Is<ListWebAuthnCredentialsRequest>(r => r.AccessToken == "access-token"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListWebAuthnCredentialsResponse
            {
                Credentials =
                [
                    new WebAuthnCredentialDescription
                    {
                        CredentialId = "credential-id",
                        FriendlyCredentialName = "Android",
                        RelyingPartyId = "getconscia.com",
                        AuthenticatorAttachment = "platform",
                        AuthenticatorTransports = ["internal"],
                        CreatedAt = new DateTime(2026, 5, 31, 2, 15, 0, DateTimeKind.Utc)
                    }
                ]
            });

        var credentials = await _passkeys.ListCredentialsAsync("access-token");

        var credential = Assert.Single(credentials);
        Assert.Equal("credential-id", credential.CredentialId);
        Assert.Equal("Android", credential.FriendlyName);
        Assert.Equal("getconscia.com", credential.RelyingPartyId);
        Assert.Equal("platform", credential.AuthenticatorAttachment);
        Assert.Equal(["internal"], credential.Transports);
        Assert.Equal(new DateTimeOffset(2026, 5, 31, 2, 15, 0, TimeSpan.Zero), credential.CreatedAt);
    }

    [Fact]
    public async Task DeleteCredentialAsync_DeletesSelectedPasskey()
    {
        _cognito
            .Setup(c => c.DeleteWebAuthnCredentialAsync(
                It.Is<DeleteWebAuthnCredentialRequest>(r =>
                    r.AccessToken == "access-token" &&
                    r.CredentialId == "credential-id"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new DeleteWebAuthnCredentialResponse());

        await _passkeys.DeleteCredentialAsync("access-token", "credential-id");

        _cognito.VerifyAll();
    }

    [Fact]
    public async Task CompleteAuthenticationAsync_ExistingLocalUserWithSameEmail_ReturnsResolvedLocalUserId()
    {
        var cognitoSub = Guid.NewGuid();
        var localUserId = Guid.NewGuid();
        await _repo.AddAsync(new User
        {
            Id = localUserId,
            Email = "demo@example.com",
            EmailConfirmed = true
        });

        _cognito
            .Setup(c => c.RespondToAuthChallengeAsync(
                It.Is<RespondToAuthChallengeRequest>(r =>
                    r.ClientId == "client-123" &&
                    r.Session == "session-token" &&
                    r.ChallengeName == ChallengeNameType.WEB_AUTHN &&
                    r.ChallengeResponses["USERNAME"] == "demo@example.com" &&
                    r.ChallengeResponses["CREDENTIAL"] == "{}"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RespondToAuthChallengeResponse
            {
                AuthenticationResult = new AuthenticationResultType
                {
                    AccessToken = CreateJwt(cognitoSub, "demo@example.com"),
                    IdToken = CreateJwt(cognitoSub, "demo@example.com"),
                    RefreshToken = "refresh-token-123"
                }
            });

        var result = await _passkeys.CompleteAuthenticationAsync(
            " Demo@Example.com ",
            "session-token",
            ChallengeNameType.WEB_AUTHN.Value,
            "{}");

        Assert.True(result.Success);
        Assert.Equal(localUserId.ToString(), result.UserId);

        var identity = Assert.Single(_repo.Identities);
        Assert.Equal(localUserId, identity.UserId);
        Assert.Equal(AuthProvider.Email, identity.Provider);
        Assert.Equal("demo@example.com", identity.ProviderSub);
    }

    private static string CreateJwt(Guid userId, string email)
    {
        var token = new JwtSecurityToken(
            issuer: "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_example",
            claims:
            [
                new Claim("sub", userId.ToString()),
                new Claim("email", email)
            ]);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static bool HasWebAuthnTransports(
        CompleteWebAuthnRegistrationRequest request,
        params string[] expected)
    {
        var response = request.Credential.AsDictionary()["response"].AsDictionary();
        var transports = response["transports"]
            .AsList()
            .Select(transport => transport.AsString())
            .ToArray();

        return transports.SequenceEqual(expected);
    }

    private static bool HasEnrichedWebAuthnFields(CompleteWebAuthnRegistrationRequest request)
    {
        var response = request.Credential.AsDictionary()["response"].AsDictionary();

        return response.TryGetValue("authenticatorData", out var authenticatorData) &&
            !string.IsNullOrWhiteSpace(authenticatorData.AsString()) &&
            response.TryGetValue("publicKeyAlgorithm", out var publicKeyAlgorithm) &&
            publicKeyAlgorithm.AsInt() == -7 &&
            response.TryGetValue("publicKey", out var publicKey) &&
            !string.IsNullOrWhiteSpace(publicKey.AsString());
    }

    private static string CreateAttestationObject()
    {
        var publicKeyWriter = new CborWriter();
        publicKeyWriter.WriteStartMap(5);
        publicKeyWriter.WriteInt32(1);
        publicKeyWriter.WriteInt32(2);
        publicKeyWriter.WriteInt32(3);
        publicKeyWriter.WriteInt32(-7);
        publicKeyWriter.WriteInt32(-1);
        publicKeyWriter.WriteInt32(1);
        publicKeyWriter.WriteInt32(-2);
        publicKeyWriter.WriteByteString(Convert.FromHexString("6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296"));
        publicKeyWriter.WriteInt32(-3);
        publicKeyWriter.WriteByteString(Convert.FromHexString("4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5"));
        publicKeyWriter.WriteEndMap();

        var authData = BuildAuthData(publicKeyWriter.Encode());

        var writer = new CborWriter();
        writer.WriteStartMap(3);
        writer.WriteTextString("fmt");
        writer.WriteTextString("none");
        writer.WriteTextString("authData");
        writer.WriteByteString(authData);
        writer.WriteTextString("attStmt");
        writer.WriteStartMap(0);
        writer.WriteEndMap();
        writer.WriteEndMap();

        return Base64UrlEncode(writer.Encode());
    }

    private static byte[] BuildAuthData(byte[] credentialPublicKey)
    {
        var authData = new List<byte>();
        authData.AddRange(Enumerable.Repeat((byte)1, 32));
        authData.Add(0x41);
        authData.AddRange([0, 0, 0, 0]);
        authData.AddRange(Enumerable.Repeat((byte)0, 16));
        authData.AddRange([0, 4]);
        authData.AddRange([1, 2, 3, 4]);
        authData.AddRange(credentialPublicKey);
        return authData.ToArray();
    }

    private static string Base64UrlEncode(byte[] value)
        => Convert.ToBase64String(value)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
}
