using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Application.Services;

public sealed class SubscriptionAdminService : ISubscriptionAdminService
{
    private readonly IUserRepository _users;
    private readonly IUserEntitlementOverrideRepository _entitlements;
    private readonly ISubscriptionService _subscriptions;

    public SubscriptionAdminService(
        IUserRepository users,
        IUserEntitlementOverrideRepository entitlements,
        ISubscriptionService subscriptions)
    {
        _users = users;
        _entitlements = entitlements;
        _subscriptions = subscriptions;
    }

    public async Task<AdminUserLookupResponse?> LookupByEmailAsync(string email, CancellationToken ct = default)
    {
        var user = await _users.GetByEmailAsync(email, ct);
        return user is null ? null : await BuildResponseAsync(user, ct);
    }

    public async Task<AdminUserLookupResponse> GrantLifetimePremiumAsync(Guid targetUserId, string grantedBy, string? note, CancellationToken ct = default)
    {
        var user = await _users.GetByIdAsync(targetUserId, ct)
            ?? throw new InvalidOperationException("User not found.");

        await _entitlements.UpsertPremiumLifetimeAsync(new UserEntitlementOverride
        {
            UserId = user.Id,
            GrantedBy = grantedBy,
            Note = note
        }, ct);

        return await BuildResponseAsync(user, ct);
    }

    public async Task<AdminUserLookupResponse?> RevokeLifetimePremiumAsync(Guid targetUserId, CancellationToken ct = default)
    {
        var user = await _users.GetByIdAsync(targetUserId, ct);
        if (user is null)
        {
            return null;
        }

        await _entitlements.RevokePremiumLifetimeAsync(targetUserId, ct);
        return await BuildResponseAsync(user, ct);
    }

    private async Task<AdminUserLookupResponse> BuildResponseAsync(User user, CancellationToken ct)
    {
        var status = await _subscriptions.GetEffectiveStatusAsync(user.Id, ct);
        return new AdminUserLookupResponse(
            user.Id,
            user.Email,
            status.IsLifetime,
            status.Source,
            status.IsActive);
    }
}
