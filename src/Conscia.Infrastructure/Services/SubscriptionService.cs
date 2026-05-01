using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly ConsciaDbContext _db;

    public SubscriptionService(ConsciaDbContext db) => _db = db;

    public async Task<UserSubscription> VerifyiOSReceiptAsync(Guid userId, string receiptData, CancellationToken ct = default)
    {
        var existing = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.OriginalTransactionId == receiptData, ct);
        if (existing is not null) return existing;

        var sub = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.iOS,
            OriginalTransactionId = receiptData,
            ExpiresAt = DateTime.UtcNow.AddYears(1)
        };

        _db.UserSubscriptions.Add(sub);
        await _db.SaveChangesAsync(ct);
        return sub;
    }

    public async Task<UserSubscription> VerifyAndroidTokenAsync(Guid userId, string purchaseToken, CancellationToken ct = default)
    {
        var existing = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.OriginalTransactionId == purchaseToken, ct);
        if (existing is not null) return existing;

        var sub = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.Android,
            OriginalTransactionId = purchaseToken,
            ExpiresAt = DateTime.UtcNow.AddYears(1)
        };

        _db.UserSubscriptions.Add(sub);
        await _db.SaveChangesAsync(ct);
        return sub;
    }

    public async Task<UserSubscription?> GetStatusAsync(Guid userId, CancellationToken ct = default) =>
        await _db.UserSubscriptions
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.ExpiresAt)
            .FirstOrDefaultAsync(ct);

    public async Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default)
    {
        var sub = await GetStatusAsync(userId, ct);
        return sub?.IsActive ?? false;
    }
}
