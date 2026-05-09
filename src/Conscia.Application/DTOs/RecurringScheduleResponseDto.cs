using Conscia.Domain.Entities;

namespace Conscia.Application.DTOs;

public class RecurringScheduleResponseDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Type { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime StartDate { get; set; }
    public string Cadence { get; set; } = string.Empty;
    public DateTime NextRunAt { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; }

    public static RecurringScheduleResponseDto From(RecurringSchedule schedule) =>
        new()
        {
            Id = schedule.Id,
            UserId = schedule.UserId,
            Type = schedule.Type.ToString(),
            Amount = schedule.Amount.Amount,
            CurrencyCode = schedule.Amount.CurrencyCode,
            Category = schedule.Category,
            Counterparty = schedule.Counterparty,
            StartDate = schedule.StartDate,
            Cadence = schedule.Cadence.ToString(),
            NextRunAt = schedule.NextRunAt,
            EndDate = schedule.EndDate,
            IsActive = schedule.IsActive,
        };
}
