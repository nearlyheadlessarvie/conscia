using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Tests.Unit.Domain;

public class UserSubscriptionTests
{
    [Fact]
    public void IsActive_PremiumNotExpired_ReturnsTrue()
    {
        var sub = new UserSubscription
        {
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Active,
            ExpiresAt = DateTime.UtcNow.AddDays(30)
        };
        Assert.True(sub.IsActive);
    }

    [Fact]
    public void IsActive_PremiumExpired_ReturnsFalse()
    {
        var sub = new UserSubscription
        {
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Expired,
            ExpiresAt = DateTime.UtcNow.AddDays(-1)
        };
        Assert.False(sub.IsActive);
    }

    [Fact]
    public void IsActive_FreeTier_ReturnsFalse()
    {
        var sub = new UserSubscription { Tier = SubscriptionTier.Free };
        Assert.False(sub.IsActive);
    }

    [Fact]
    public void IsActive_PremiumNoExpiry_ReturnsTrue()
    {
        var sub = new UserSubscription
        {
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Active,
            ExpiresAt = null
        };
        Assert.True(sub.IsActive);
    }

    [Fact]
    public void IsActive_BillingRetry_ReturnsFalse()
    {
        var sub = new UserSubscription
        {
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.BillingRetry,
            ExpiresAt = DateTime.UtcNow.AddDays(1)
        };

        Assert.False(sub.IsActive);
    }

    [Fact]
    public void IsActive_GracePeriod_ReturnsTrue()
    {
        var sub = new UserSubscription
        {
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.GracePeriod,
            ExpiresAt = DateTime.UtcNow.AddDays(1)
        };

        Assert.True(sub.IsActive);
    }
}
