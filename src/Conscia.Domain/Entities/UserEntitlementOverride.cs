namespace Conscia.Domain.Entities;

public class UserEntitlementOverride
{
    public const string PremiumLifetimeKey = "premium_lifetime";

    public Guid UserId { get; set; }
    public string EntitlementKey { get; set; } = PremiumLifetimeKey;
    public DateTime GrantedAt { get; set; } = DateTime.UtcNow;
    public string? GrantedBy { get; set; }
    public string? Note { get; set; }
}
