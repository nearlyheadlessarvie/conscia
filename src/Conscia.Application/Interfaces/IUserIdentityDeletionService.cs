using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IUserIdentityDeletionService
{
    Task DeleteUserAsync(User user, CancellationToken ct = default);
}
