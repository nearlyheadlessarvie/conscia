using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class UpdateRecurringScheduleDto
{
    public TransactionType? Type { get; set; }
    public decimal? Amount { get; set; }
    public string? CurrencyCode { get; set; }
    public string? Category { get; set; }
    public string? Counterparty { get; set; }
    public DateTime? StartDate { get; set; }
    public RecurringCadence? Cadence { get; set; }
    public DateTime? EndDate { get; set; }
    public bool? IsActive { get; set; }
    public RecordScope? Scope { get; set; }
    public Guid? FamilySpaceId { get; set; }
}
