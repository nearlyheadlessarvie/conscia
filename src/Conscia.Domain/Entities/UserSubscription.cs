using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class UserSubscription
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public SubscriptionTier Tier { get; set; } = SubscriptionTier.Free;
    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Unknown;
    public Platform Platform { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? OriginalTransactionId { get; set; }

    public bool IsActive =>
        Tier == SubscriptionTier.Premium &&
        Status is not SubscriptionStatus.BillingRetry
            and not SubscriptionStatus.Expired
            and not SubscriptionStatus.Refunded
            and not SubscriptionStatus.Revoked &&
        (!ExpiresAt.HasValue || ExpiresAt.Value > DateTime.UtcNow);
}
