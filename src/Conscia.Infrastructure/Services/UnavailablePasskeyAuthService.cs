using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Infrastructure.Services;

public sealed class UnavailablePasskeyAuthService : IPasskeyAuthService
{
    private const string Message =
        "Passkeys are unavailable in this environment.";

    public Task<StartPasskeyRegistrationResponse> StartRegistrationAsync(
        string accessToken,
        CancellationToken ct = default) =>
        throw new InvalidOperationException(Message);

    public Task CompleteRegistrationAsync(
        string accessToken,
        string credential,
        CancellationToken ct = default) =>
        throw new InvalidOperationException(Message);

    public Task<IReadOnlyList<PasskeyCredentialResponse>> ListCredentialsAsync(
        string accessToken,
        CancellationToken ct = default) =>
        throw new InvalidOperationException(Message);

    public Task DeleteCredentialAsync(
        string accessToken,
        string credentialId,
        CancellationToken ct = default) =>
        throw new InvalidOperationException(Message);

    public Task<StartPasskeyAuthenticationResponse> StartAuthenticationAsync(
        string email,
        CancellationToken ct = default,
        bool allowExternalPasskeys = false) =>
        throw new InvalidOperationException(Message);

    public Task<AuthResult> CompleteAuthenticationAsync(
        string email,
        string session,
        string challengeName,
        string credential,
        CancellationToken ct = default) =>
        throw new InvalidOperationException(Message);
}
