using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class SubscriptionServiceTests
{
    [Fact]
    public async Task GetEffectiveStatusAsync_ReturnsLifetimePremium_WhenOverrideExists()
    {
        var userId = Guid.Parse("10000000-0000-4000-8000-000000000001");
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var overrides = new Mock<IUserEntitlementOverrideRepository>();
        overrides.Setup(r => r.GetPremiumLifetimeAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserEntitlementOverride
            {
                UserId = userId,
                EntitlementKey = UserEntitlementOverride.PremiumLifetimeKey,
                GrantedAt = DateTime.UtcNow
            });

        var service = new SubscriptionService(
            subscriptions.Object,
            overrides.Object,
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        var status = await service.GetEffectiveStatusAsync(userId);

        Assert.True(status.IsActive);
        Assert.True(status.IsLifetime);
        Assert.Equal("lifetime", status.Source);
        Assert.Equal(SubscriptionTier.Premium, status.Tier);
        Assert.Null(status.ExpiresAt);
    }

    [Fact]
    public async Task GetEffectiveStatusAsync_ReturnsStorePremium_WhenActiveSubscriptionExists()
    {
        var userId = Guid.Parse("10000000-0000-4000-8000-000000000002");
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Tier = SubscriptionTier.Premium,
                Status = SubscriptionStatus.Active,
                Platform = Platform.iOS,
                ExpiresAt = DateTime.UtcNow.AddDays(30)
            });

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        var status = await service.GetEffectiveStatusAsync(userId);

        Assert.True(status.IsActive);
        Assert.False(status.IsLifetime);
        Assert.Equal("store", status.Source);
        Assert.Equal(Platform.iOS, status.Platform);
        Assert.Equal(SubscriptionStatus.Active, status.Status);
    }

    [Fact]
    public async Task IsPremiumAsync_ReturnsFalse_WhenNoOverrideAndSubscriptionIsInactive()
    {
        var userId = Guid.Parse("10000000-0000-4000-8000-000000000003");
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Tier = SubscriptionTier.Premium,
                Status = SubscriptionStatus.Expired,
                Platform = Platform.Android,
                ExpiresAt = DateTime.UtcNow.AddDays(-1)
            });

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        Assert.False(await service.IsPremiumAsync(userId));
    }

    [Fact]
    public async Task VerifyiOSReceiptAsync_Throws_WhenAppleValidationIsNotConfigured()
    {
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions
            .Setup(r => r.GetByOriginalTransactionIdAsync("receipt-token", It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: false),
            new FakeGooglePlayValidator(isConfigured: true));

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.VerifyiOSReceiptAsync(Guid.NewGuid(), "receipt-token"));

        Assert.Contains("Apple", ex.Message);
        subscriptions.Verify(
            r => r.AddAsync(It.IsAny<UserSubscription>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task VerifyAndroidTokenAsync_Throws_WhenGoogleValidationIsNotConfigured()
    {
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions
            .Setup(r => r.GetByOriginalTransactionIdAsync("purchase-token", It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: false));

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.VerifyAndroidTokenAsync(Guid.NewGuid(), "purchase-token"));

        Assert.Contains("Google Play", ex.Message);
        subscriptions.Verify(
            r => r.AddAsync(It.IsAny<UserSubscription>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ProcessAppleServerNotificationAsync_RenewalUpdatesExpiry()
    {
        var userId = Guid.Parse("10000000-0000-4000-8000-000000000010");
        var subscription = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Platform = Platform.iOS,
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Active,
            OriginalTransactionId = "orig-123",
            ExpiresAt = new DateTime(2026, 05, 20, 0, 0, 0, DateTimeKind.Utc)
        };

        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetByOriginalTransactionIdAsync("orig-123", It.IsAny<CancellationToken>()))
            .ReturnsAsync(subscription);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        await service.ProcessAppleServerNotificationAsync(new AppleServerNotification(
            "DID_RENEW",
            null,
            new DateTime(2026, 05, 21, 0, 0, 0, DateTimeKind.Utc),
            new AppleServerNotificationData(
                "PROD",
                "orig-123",
                new DateTime(2026, 06, 20, 0, 0, 0, DateTimeKind.Utc),
                null)),
            CancellationToken.None);

        Assert.Equal(new DateTime(2026, 06, 20, 0, 0, 0, DateTimeKind.Utc), subscription.ExpiresAt);
        Assert.Equal(SubscriptionTier.Premium, subscription.Tier);
        Assert.Equal(SubscriptionStatus.Active, subscription.Status);
        subscriptions.Verify(r => r.UpdateAsync(subscription, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ProcessAppleServerNotificationAsync_ExpirationDowngradesToFree()
    {
        var subscription = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Platform = Platform.iOS,
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Active,
            OriginalTransactionId = "orig-expired",
            ExpiresAt = new DateTime(2026, 06, 20, 0, 0, 0, DateTimeKind.Utc)
        };
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetByOriginalTransactionIdAsync("orig-expired", It.IsAny<CancellationToken>()))
            .ReturnsAsync(subscription);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        await service.ProcessAppleServerNotificationAsync(new AppleServerNotification(
            "EXPIRED",
            null,
            new DateTime(2026, 06, 21, 0, 0, 0, DateTimeKind.Utc),
            new AppleServerNotificationData(
                "PROD",
                "orig-expired",
                new DateTime(2026, 06, 20, 0, 0, 0, DateTimeKind.Utc),
                null)),
            CancellationToken.None);

        Assert.Equal(SubscriptionTier.Free, subscription.Tier);
        Assert.Equal(SubscriptionStatus.Expired, subscription.Status);
    }

    [Fact]
    public async Task ProcessAppleServerNotificationAsync_GracePeriodPreservesAccess()
    {
        var subscription = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Platform = Platform.iOS,
            Tier = SubscriptionTier.Premium,
            Status = SubscriptionStatus.Active,
            OriginalTransactionId = "orig-grace",
            ExpiresAt = new DateTime(2026, 06, 20, 0, 0, 0, DateTimeKind.Utc)
        };
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetByOriginalTransactionIdAsync("orig-grace", It.IsAny<CancellationToken>()))
            .ReturnsAsync(subscription);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        await service.ProcessAppleServerNotificationAsync(new AppleServerNotification(
            "DID_FAIL_TO_RENEW",
            "GRACE_PERIOD",
            DateTime.UtcNow,
            new AppleServerNotificationData(
                "Sandbox",
                "orig-grace",
                subscription.ExpiresAt,
                null,
                true,
                new DateTime(2026, 06, 27, 0, 0, 0, DateTimeKind.Utc))),
            CancellationToken.None);

        Assert.Equal(SubscriptionStatus.GracePeriod, subscription.Status);
        Assert.True(subscription.IsActive);
        Assert.Equal(new DateTime(2026, 06, 27, 0, 0, 0, DateTimeKind.Utc), subscription.ExpiresAt);
    }

    [Fact]
    public async Task ProcessAppleServerNotificationAsync_UnlinkedOriginalTransactionId_IsIgnored()
    {
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetByOriginalTransactionIdAsync("missing-orig", It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var service = new SubscriptionService(
            subscriptions.Object,
            Mock.Of<IUserEntitlementOverrideRepository>(),
            NullLogger<SubscriptionService>.Instance,
            new FakeAppleReceiptValidator(isConfigured: true),
            new FakeGooglePlayValidator(isConfigured: true));

        await service.ProcessAppleServerNotificationAsync(new AppleServerNotification(
            "DID_FAIL_TO_RENEW",
            "GRACE_PERIOD",
            DateTime.UtcNow,
            new AppleServerNotificationData("Sandbox", "missing-orig", DateTime.UtcNow.AddDays(3), null)),
            CancellationToken.None);

        subscriptions.Verify(r => r.UpdateAsync(It.IsAny<UserSubscription>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    private sealed class FakeAppleReceiptValidator(bool isConfigured) : IAppleReceiptValidator
    {
        public bool IsConfigured { get; } = isConfigured;

        public Task<AppleTransactionInfo?> ValidateAsync(string signedTransactionInfo, CancellationToken ct = default)
            => Task.FromResult<AppleTransactionInfo?>(null);
    }

    private sealed class FakeGooglePlayValidator(bool isConfigured) : IGooglePlayValidator
    {
        public bool IsConfigured { get; } = isConfigured;

        public Task<GoogleSubscriptionInfo?> ValidateAsync(
            string purchaseToken,
            string subscriptionId,
            CancellationToken ct = default) =>
            Task.FromResult<GoogleSubscriptionInfo?>(null);
    }
}
