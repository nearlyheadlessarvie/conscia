using Conscia.Domain.Enums;

namespace Conscia.Application.Models;

public sealed class EffectiveSubscriptionStatus
{
    public SubscriptionTier Tier { get; init; } = SubscriptionTier.Free;
    public bool IsActive { get; init; }
    public bool IsLifetime { get; init; }
    public string Source { get; init; } = "none";
    public Platform? Platform { get; init; }
    public DateTime? ExpiresAt { get; init; }
}
