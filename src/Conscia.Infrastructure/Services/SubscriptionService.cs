using Conscia.Application.Models;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly IUserSubscriptionRepository _subscriptions;
    private readonly IUserEntitlementOverrideRepository _entitlements;
    private readonly ILogger<SubscriptionService> _logger;
    private readonly IAppleReceiptValidator _appleValidator;
    private readonly IGooglePlayValidator _googleValidator;

    private const string DefaultSubscriptionId = "conscia_premium_monthly";

    public SubscriptionService(
        IUserSubscriptionRepository subscriptions,
        IUserEntitlementOverrideRepository entitlements,
        ILogger<SubscriptionService> logger,
        IAppleReceiptValidator appleValidator,
        IGooglePlayValidator googleValidator)
    {
        _subscriptions = subscriptions;
        _entitlements = entitlements;
        _logger = logger;
        _appleValidator = appleValidator;
        _googleValidator = googleValidator;
    }

    public async Task<UserSubscription> VerifyiOSReceiptAsync(Guid userId, string receiptData, CancellationToken ct = default)
    {
        var existing = await _subscriptions.GetByOriginalTransactionIdAsync(receiptData, ct);
        if (existing is not null)
        {
            await TryRefreshAppleExpiry(existing, receiptData, ct);
            return existing;
        }

        if (!_appleValidator.IsConfigured)
        {
            _logger.LogError(
                "Apple receipt verification attempted without Apple validator configuration for user {UserId}",
                userId);
            throw new InvalidOperationException("Apple subscription verification is not configured.");
        }

        var txnInfo = await _appleValidator.ValidateAsync(receiptData, ct);
        if (txnInfo is null)
            throw new InvalidOperationException("Apple receipt validation failed — receipt rejected.");

        if (txnInfo.IsRevoked)
            throw new InvalidOperationException("This subscription has been revoked.");

        var expiresAt = txnInfo.ExpiresDate;
        _logger.LogInformation(
            "iOS receipt validated via App Store Server API for user {UserId}, product {ProductId}, expires {ExpiresAt}",
            userId, txnInfo.ProductId, expiresAt);

        var sub = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.iOS,
            OriginalTransactionId = receiptData,
            ExpiresAt = expiresAt
        };

        await _subscriptions.AddAsync(sub, ct);
        return sub;
    }

    public async Task<UserSubscription> VerifyAndroidTokenAsync(Guid userId, string purchaseToken, CancellationToken ct = default)
    {
        var existing = await _subscriptions.GetByOriginalTransactionIdAsync(purchaseToken, ct);
        if (existing is not null)
        {
            await TryRefreshGoogleExpiry(existing, purchaseToken, ct);
            return existing;
        }

        if (!_googleValidator.IsConfigured)
        {
            _logger.LogError(
                "Google Play verification attempted without Google validator configuration for user {UserId}",
                userId);
            throw new InvalidOperationException("Google Play subscription verification is not configured.");
        }

        var subInfo = await _googleValidator.ValidateAsync(purchaseToken, DefaultSubscriptionId, ct);
        if (subInfo is null)
            throw new InvalidOperationException("Google Play purchase validation failed — token rejected.");

        if (subInfo.IsCanceled)
            throw new InvalidOperationException("This subscription has been canceled.");

        var expiresAt = subInfo.ExpiryTime;
        _logger.LogInformation(
            "Android token validated via Google Play Developer API for user {UserId}, order {OrderId}, expires {ExpiresAt}",
            userId, subInfo.OrderId, expiresAt);

        var sub = new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.Android,
            OriginalTransactionId = purchaseToken,
            ExpiresAt = expiresAt
        };

        await _subscriptions.AddAsync(sub, ct);
        return sub;
    }

    public async Task<UserSubscription?> GetStatusAsync(Guid userId, CancellationToken ct = default) =>
        await _subscriptions.GetLatestByUserAsync(userId, ct);

    public async Task<EffectiveSubscriptionStatus> GetEffectiveStatusAsync(Guid userId, CancellationToken ct = default)
    {
        var entitlement = await _entitlements.GetPremiumLifetimeAsync(userId, ct);
        if (entitlement is not null)
        {
            return new EffectiveSubscriptionStatus
            {
                Tier = SubscriptionTier.Premium,
                IsActive = true,
                IsLifetime = true,
                Source = "lifetime"
            };
        }

        var sub = await GetStatusAsync(userId, ct);
        if (sub?.IsActive == true)
        {
            return new EffectiveSubscriptionStatus
            {
                Tier = SubscriptionTier.Premium,
                IsActive = true,
                IsLifetime = false,
                Source = "store",
                Platform = sub.Platform,
                ExpiresAt = sub.ExpiresAt
            };
        }

        return new EffectiveSubscriptionStatus
        {
            Tier = SubscriptionTier.Free,
            IsActive = false,
            IsLifetime = false,
            Source = "none"
        };
    }

    public async Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default)
    {
        var status = await GetEffectiveStatusAsync(userId, ct);
        return status.IsActive;
    }

    private async Task TryRefreshAppleExpiry(UserSubscription existing, string transactionId, CancellationToken ct)
    {
        if (!_appleValidator.IsConfigured) return;

        try
        {
            var txnInfo = await _appleValidator.ValidateAsync(transactionId, ct);
            if (txnInfo is not null && txnInfo.ExpiresDate > (existing.ExpiresAt ?? DateTime.MinValue))
            {
                existing.ExpiresAt = txnInfo.ExpiresDate;
                existing.Tier = txnInfo.IsRevoked ? SubscriptionTier.Free : SubscriptionTier.Premium;
                await _subscriptions.UpdateAsync(existing, ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to refresh Apple expiry for subscription {SubId}", existing.Id);
        }
    }

    private async Task TryRefreshGoogleExpiry(UserSubscription existing, string purchaseToken, CancellationToken ct)
    {
        if (!_googleValidator.IsConfigured) return;

        try
        {
            var subInfo = await _googleValidator.ValidateAsync(purchaseToken, DefaultSubscriptionId, ct);
            if (subInfo is not null && subInfo.ExpiryTime > (existing.ExpiresAt ?? DateTime.MinValue))
            {
                existing.ExpiresAt = subInfo.ExpiryTime;
                existing.Tier = subInfo.IsCanceled ? SubscriptionTier.Free : SubscriptionTier.Premium;
                await _subscriptions.UpdateAsync(existing, ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to refresh Google expiry for subscription {SubId}", existing.Id);
        }
    }
}
