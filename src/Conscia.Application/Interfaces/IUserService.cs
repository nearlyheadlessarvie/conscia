using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface IUserService
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default);
    Task<User> UpdateProfileAsync(Guid id, string? preferredCurrency, string? locale, CancellationToken ct = default);
    Task DeleteAccountAsync(Guid id, CancellationToken ct = default);
}
