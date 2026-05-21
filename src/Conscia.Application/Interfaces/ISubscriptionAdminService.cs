using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface ISubscriptionAdminService
{
    Task<AdminUserLookupResponse?> LookupByEmailAsync(string email, CancellationToken ct = default);
    Task<AdminUserLookupResponse> GrantLifetimePremiumAsync(Guid targetUserId, string grantedBy, string? note, CancellationToken ct = default);
    Task<AdminUserLookupResponse?> RevokeLifetimePremiumAsync(Guid targetUserId, CancellationToken ct = default);
}
