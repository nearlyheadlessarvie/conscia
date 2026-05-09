using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IRecurringScheduleGenerator
{
    Task<IReadOnlyList<GeneratedOccurrence>> CalculateOccurrencesAsync(
        RecurringSchedule schedule,
        DateTime nowUtc,
        CancellationToken ct = default);
}

public sealed record GeneratedOccurrence(
    DateTime OccurrenceDate,
    string DuplicateKey);
