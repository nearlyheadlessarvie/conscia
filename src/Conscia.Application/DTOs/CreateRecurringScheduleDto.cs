using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class CreateRecurringScheduleDto
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime StartDate { get; set; }
    public RecurringCadence Cadence { get; set; }
    public DateTime? EndDate { get; set; }
    public RecordScope Scope { get; set; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; set; }
}

public class RecurringOptionsDto
{
    public RecurringCadence Cadence { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
}
