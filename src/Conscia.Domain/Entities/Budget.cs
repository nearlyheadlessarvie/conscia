using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class Budget
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Category { get; set; } = string.Empty;
    public decimal MonthlyLimit { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public RecordScope Scope { get; set; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; set; }
    public DateTime? SharedAt { get; set; }
    public Guid? SharedByUserId { get; set; }
}
