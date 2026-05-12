using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Domain.Entities;

public enum RecurringCadence
{
    Weekly = 0,
    Monthly = 1,
    Yearly = 2,
}

public class RecurringSchedule
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TransactionType Type { get; set; }
    public Money Amount { get; set; } = null!;
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime StartDate { get; set; }
    public RecurringCadence Cadence { get; set; }
    public DateTime NextRunAt { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastGeneratedAt { get; set; }
    public RecordScope Scope { get; set; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; set; }
    public DateTime? SharedAt { get; set; }
    public Guid? SharedByUserId { get; set; }
}
