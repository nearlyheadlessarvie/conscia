using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class SubscriptionServiceTests
{
    [Fact]
    public async Task VerifyiOSReceiptAsync_Throws_WhenAppleValidationIsNotConfigured()
    {
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions
            .Setup(r => r.GetByOriginalTransactionIdAsync("receipt-token", It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var service = new SubscriptionService(
            subscriptions.Object,
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
