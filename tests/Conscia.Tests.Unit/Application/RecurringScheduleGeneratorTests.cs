using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Tests.Unit.Application;

public class RecurringScheduleGeneratorTests
{
    [Fact]
    public async Task CalculateOccurrencesAsync_MonthlyThirtyFirst_UsesLastDayOfShortMonth()
    {
        var now = new DateTime(2026, 03, 31, 12, 0, 0, DateTimeKind.Utc);
        var start = new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc);
        var schedule = new RecurringSchedule
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Type = TransactionType.Expense,
            Amount = new Money(500m, "PHP"),
            Category = "Subscriptions",
            Counterparty = "Netflix",
            StartDate = start,
            Cadence = RecurringCadence.Monthly,
            NextRunAt = start,
            IsActive = true,
        };

        var generator = new RecurringScheduleGenerator();

        var result = await generator.CalculateOccurrencesAsync(schedule, now, CancellationToken.None);

        Assert.Equal(
            [
                new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc),
                new DateTime(2026, 02, 28, 0, 0, 0, DateTimeKind.Utc),
                new DateTime(2026, 03, 31, 0, 0, 0, DateTimeKind.Utc)
            ],
            result.Select(x => x.OccurrenceDate).ToArray());
    }

    [Fact]
    public async Task CalculateOccurrencesAsync_StopsAtEndDate()
    {
        var start = new DateTime(2026, 05, 01, 0, 0, 0, DateTimeKind.Utc);
        var end = new DateTime(2026, 05, 15, 0, 0, 0, DateTimeKind.Utc);
        var schedule = new RecurringSchedule
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Type = TransactionType.Expense,
            Amount = new Money(900m, "PHP"),
            Category = "Bills",
            Counterparty = "Rent",
            StartDate = start,
            Cadence = RecurringCadence.Weekly,
            NextRunAt = start,
            EndDate = end,
            IsActive = true,
        };

        var generator = new RecurringScheduleGenerator();

        var result = await generator.CalculateOccurrencesAsync(
            schedule,
            new DateTime(2026, 06, 01, 0, 0, 0, DateTimeKind.Utc),
            CancellationToken.None);

        Assert.All(result, x => Assert.True(x.OccurrenceDate <= end));
        Assert.Equal(3, result.Count);
    }
}
