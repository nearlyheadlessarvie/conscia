using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ISubscriptionService
{
    Task<UserSubscription> VerifyiOSReceiptAsync(Guid userId, string receiptData, CancellationToken ct = default);
    Task<UserSubscription> VerifyAndroidTokenAsync(Guid userId, string purchaseToken, CancellationToken ct = default);
    Task<UserSubscription?> GetStatusAsync(Guid userId, CancellationToken ct = default);
    Task<EffectiveSubscriptionStatus> GetEffectiveStatusAsync(Guid userId, CancellationToken ct = default);
    Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default);
}
