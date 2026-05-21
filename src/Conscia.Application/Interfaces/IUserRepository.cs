using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<IReadOnlyList<UserIdentity>> GetIdentitiesByUserAsync(Guid userId, CancellationToken ct = default);
    Task<User> AddAsync(User user, CancellationToken ct = default);
    Task<User> UpdateAsync(User user, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
    Task<UserIdentity> AddIdentityAsync(UserIdentity identity, CancellationToken ct = default);
    Task<UserIdentity> UpdateIdentityAsync(UserIdentity identity, CancellationToken ct = default);
}
