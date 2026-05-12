namespace Conscia.Domain.Entities;

public class FamilySpace
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CurrencyCode { get; set; } = "USD";
    public Guid CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PremiumGraceEndsAt { get; set; }
    public bool IsReadOnly { get; set; }
}
