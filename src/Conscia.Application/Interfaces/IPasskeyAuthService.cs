using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IPasskeyAuthService
{
    Task<StartPasskeyRegistrationResponse> StartRegistrationAsync(string accessToken, CancellationToken ct = default);
    Task CompleteRegistrationAsync(string accessToken, string credential, CancellationToken ct = default);
    Task<IReadOnlyList<PasskeyCredentialResponse>> ListCredentialsAsync(string accessToken, CancellationToken ct = default);
    Task DeleteCredentialAsync(string accessToken, string credentialId, CancellationToken ct = default);
    Task<StartPasskeyAuthenticationResponse> StartAuthenticationAsync(
        string email,
        CancellationToken ct = default,
        bool allowExternalPasskeys = false);
    Task<AuthResult> CompleteAuthenticationAsync(
        string email,
        string session,
        string challengeName,
        string credential,
        CancellationToken ct = default);
}
