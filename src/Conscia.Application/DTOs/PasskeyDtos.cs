namespace Conscia.Application.DTOs;

public sealed record StartPasskeyRegistrationResponse(string CredentialCreationOptions);

public sealed record CompletePasskeyRegistrationRequest(string Credential);

public sealed record StartPasskeyAuthenticationRequest(string Email);

public sealed record StartPasskeyAuthenticationResponse(
    string Session,
    string ChallengeName,
    string CredentialRequestOptions);

public sealed record CompletePasskeyAuthenticationRequest(
    string Email,
    string Session,
    string ChallengeName,
    string Credential);
