using System.Security.Claims;

namespace Conscia.Application.Interfaces;

public interface ICurrentUserPasswordService
{
    Task SetPasswordAsync(
        ClaimsPrincipal principal,
        string password,
        string? currentPassword = null,
        string? accessToken = null,
        CancellationToken ct = default);
}
