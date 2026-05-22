namespace Conscia.Application.Models;

public sealed record AppleServerNotification(
    string NotificationType,
    string? Subtype,
    DateTime SignedDate,
    AppleServerNotificationData Data);

public sealed record AppleServerNotificationData(
    string Environment,
    string OriginalTransactionId,
    DateTime? ExpiresAt,
    DateTime? RevocationDate,
    bool? IsInBillingRetryPeriod = null,
    DateTime? GracePeriodExpiresAt = null,
    bool? AutoRenewStatus = null);
