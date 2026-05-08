using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Application.Services;

public class RecurringScheduleGenerator : IRecurringScheduleGenerator
{
    public Task<IReadOnlyList<GeneratedOccurrence>> CalculateOccurrencesAsync(
        RecurringSchedule schedule,
        DateTime nowUtc,
        CancellationToken ct = default)
    {
        if (!schedule.IsActive)
            return Task.FromResult<IReadOnlyList<GeneratedOccurrence>>([]);

        var occurrences = new List<GeneratedOccurrence>();
        var cursor = schedule.NextRunAt;

        while (cursor <= nowUtc && (!schedule.EndDate.HasValue || cursor <= schedule.EndDate.Value))
        {
            occurrences.Add(new GeneratedOccurrence(
                cursor,
                $"{schedule.Id:N}:{cursor:O}"));

            cursor = Advance(schedule, cursor);
        }

        return Task.FromResult<IReadOnlyList<GeneratedOccurrence>>(occurrences);
    }

    private static DateTime Advance(RecurringSchedule schedule, DateTime current)
    {
        return schedule.Cadence switch
        {
            RecurringCadence.Weekly => current.AddDays(7),
            RecurringCadence.Monthly => AdvanceMonthly(schedule.StartDate, current),
            RecurringCadence.Yearly => AdvanceYearly(schedule.StartDate, current),
            _ => throw new ArgumentOutOfRangeException(nameof(schedule.Cadence)),
        };
    }

    private static DateTime AdvanceMonthly(DateTime anchor, DateTime current)
    {
        var nextMonth = current.AddMonths(1);
        var day = Math.Min(anchor.Day, DateTime.DaysInMonth(nextMonth.Year, nextMonth.Month));
        return new DateTime(
            nextMonth.Year,
            nextMonth.Month,
            day,
            anchor.Hour,
            anchor.Minute,
            anchor.Second,
            DateTimeKind.Utc);
    }

    private static DateTime AdvanceYearly(DateTime anchor, DateTime current)
    {
        var year = current.Year + 1;
        var day = Math.Min(anchor.Day, DateTime.DaysInMonth(year, anchor.Month));
        return new DateTime(
            year,
            anchor.Month,
            day,
            anchor.Hour,
            anchor.Minute,
            anchor.Second,
            DateTimeKind.Utc);
    }
}
