namespace Conscia.Domain.Enums;

public enum SubscriptionStatus
{
    Unknown,
    Active,
    GracePeriod,
    BillingRetry,
    Canceled,
    Expired,
    Refunded,
    Revoked
}
