using System.Security.Claims;

namespace Conscia.Application.Interfaces;

public interface ICurrentUserPasswordService
{
    Task SetPasswordAsync(
        ClaimsPrincipal principal,
        string password,
        CancellationToken ct = default);
}
