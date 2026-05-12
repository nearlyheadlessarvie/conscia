using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class ManagedCategory
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public TransactionType Type { get; set; } = TransactionType.Expense;
    public RecordScope Scope { get; set; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; set; }
    public string IconKey { get; set; } = "other";
    public string ColorKey { get; set; } = "blue";
    public bool IsArchived { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
