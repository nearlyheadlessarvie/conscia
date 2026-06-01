namespace Conscia.Application.DTOs;

public sealed record StartPasskeyRegistrationResponse(string CredentialCreationOptions);

public sealed record CompletePasskeyRegistrationRequest(string Credential);

public sealed record PasskeyCredentialResponse(
    string CredentialId,
    string? FriendlyName,
    DateTimeOffset? CreatedAt,
    string? RelyingPartyId,
    string? AuthenticatorAttachment,
    IReadOnlyList<string> Transports);

public sealed record StartPasskeyAuthenticationRequest(
    string Email,
    bool AllowExternalPasskeys = false);

public sealed record StartPasskeyAuthenticationResponse(
    string Session,
    string ChallengeName,
    string CredentialRequestOptions);

public sealed record CompletePasskeyAuthenticationRequest(
    string Email,
    string Session,
    string ChallengeName,
    string Credential);
