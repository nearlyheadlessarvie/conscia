using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class UserSubscription
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public SubscriptionTier Tier { get; set; } = SubscriptionTier.Free;
    public Platform Platform { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? OriginalTransactionId { get; set; }

    public bool IsActive =>
        Tier == SubscriptionTier.Premium && (!ExpiresAt.HasValue || ExpiresAt.Value > DateTime.UtcNow);
}
