namespace Conscia.Application.Interfaces;

public interface IAdminAuthorizationService
{
    Task<bool> IsAuthorizedAsync(Guid userId, string email, CancellationToken ct = default);
}
