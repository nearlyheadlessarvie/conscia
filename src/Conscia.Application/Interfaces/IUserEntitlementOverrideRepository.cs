using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IUserEntitlementOverrideRepository
{
    Task<UserEntitlementOverride?> GetPremiumLifetimeAsync(Guid userId, CancellationToken ct = default);
    Task<UserEntitlementOverride> UpsertPremiumLifetimeAsync(UserEntitlementOverride entitlement, CancellationToken ct = default);
    Task RevokePremiumLifetimeAsync(Guid userId, CancellationToken ct = default);
}
