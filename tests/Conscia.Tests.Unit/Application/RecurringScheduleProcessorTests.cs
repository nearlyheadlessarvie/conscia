using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class RecurringScheduleProcessorTests
{
    private readonly Mock<IRecurringScheduleRepository> _scheduleRepoMock = new();
    private readonly Mock<IRecurringScheduleGenerator> _generatorMock = new();
    private readonly Mock<ITransactionRepository> _transactionRepoMock = new();
    private readonly Mock<IInAppAlertRepository> _alertRepoMock = new();

    [Fact]
    public async Task ProcessOnceAsync_BackfillsMissedOccurrences_AndCreatesReminderAlert()
    {
        var userId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var now = new DateTime(2026, 03, 31, 12, 0, 0, DateTimeKind.Utc);
        var january = new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc);
        var february = new DateTime(2026, 02, 28, 0, 0, 0, DateTimeKind.Utc);
        var march = new DateTime(2026, 03, 31, 0, 0, 0, DateTimeKind.Utc);
        var schedule = new RecurringSchedule
        {
            Id = scheduleId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(500m, "PHP"),
            Category = "Subscriptions",
            Counterparty = "Netflix",
            StartDate = january,
            Cadence = RecurringCadence.Monthly,
            NextRunAt = january,
            IsActive = true,
        };

        _scheduleRepoMock
            .Setup(r => r.ListDueAsync(now, It.IsAny<CancellationToken>()))
            .ReturnsAsync([schedule]);
        _generatorMock
            .Setup(g => g.CalculateOccurrencesAsync(schedule, now, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new GeneratedOccurrence(january, $"{scheduleId:N}:{january:O}"),
                new GeneratedOccurrence(february, $"{scheduleId:N}:{february:O}"),
                new GeneratedOccurrence(march, $"{scheduleId:N}:{march:O}"),
            ]);
        _transactionRepoMock
            .Setup(r => r.ExistsRecurringOccurrenceAsync(userId, scheduleId, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);
        _transactionRepoMock
            .Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction transaction, OutboxEvent _, CancellationToken _) => transaction);
        _alertRepoMock
            .Setup(r => r.AddAsync(It.IsAny<InAppAlert>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        _scheduleRepoMock
            .Setup(r => r.UpdateAsync(It.IsAny<RecurringSchedule>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var processor = CreateProcessor(now);

        await processor.ProcessOnceAsync(CancellationToken.None);

        _transactionRepoMock.Verify(r => r.AddWithOutboxAsync(
            It.IsAny<Transaction>(),
            It.Is<OutboxEvent>(e =>
                e.EventType == OutboxEventType.TransactionCreated &&
                e.Payload.Contains("\"Category\":\"Subscriptions\"")),
            It.IsAny<CancellationToken>()), Times.Exactly(3));
        _transactionRepoMock.Verify(r => r.AddAsync(It.IsAny<Transaction>(), It.IsAny<CancellationToken>()), Times.Never);
        _alertRepoMock.Verify(r => r.AddAsync(
            It.Is<InAppAlert>(a => a.TriggerName == "recurring_transaction_created" && a.Counterparty == "Netflix"),
            It.IsAny<CancellationToken>()), Times.Exactly(3));
        _scheduleRepoMock.Verify(r => r.UpdateAsync(
            It.Is<RecurringSchedule>(s => s.LastGeneratedAt == march && s.NextRunAt > now),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ProcessOnceAsync_SkipsDuplicateOccurrence_WhenRetrying()
    {
        var userId = Guid.NewGuid();
        var scheduleId = Guid.NewGuid();
        var now = new DateTime(2026, 05, 31, 12, 0, 0, DateTimeKind.Utc);
        var occurrenceDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);
        var schedule = new RecurringSchedule
        {
            Id = scheduleId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(800m, "PHP"),
            Category = "Bills",
            Counterparty = "Rent",
            StartDate = occurrenceDate,
            Cadence = RecurringCadence.Monthly,
            NextRunAt = occurrenceDate,
            IsActive = true,
        };

        _scheduleRepoMock
            .Setup(r => r.ListDueAsync(now, It.IsAny<CancellationToken>()))
            .ReturnsAsync([schedule]);
        _generatorMock
            .Setup(g => g.CalculateOccurrencesAsync(schedule, now, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new GeneratedOccurrence(occurrenceDate, $"{scheduleId:N}:{occurrenceDate:O}")]);
        _transactionRepoMock
            .Setup(r => r.ExistsRecurringOccurrenceAsync(userId, scheduleId, occurrenceDate, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _scheduleRepoMock
            .Setup(r => r.UpdateAsync(It.IsAny<RecurringSchedule>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var processor = CreateProcessor(now);

        await processor.ProcessOnceAsync(CancellationToken.None);

        _transactionRepoMock.Verify(r => r.AddWithOutboxAsync(
            It.IsAny<Transaction>(),
            It.IsAny<OutboxEvent>(),
            It.IsAny<CancellationToken>()), Times.Never);
        _alertRepoMock.Verify(r => r.AddAsync(It.IsAny<InAppAlert>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    private RecurringScheduleProcessor CreateProcessor(DateTime nowUtc)
    {
        var services = new ServiceCollection();
        services.AddScoped(_ => _scheduleRepoMock.Object);
        services.AddScoped(_ => _generatorMock.Object);
        services.AddScoped(_ => _transactionRepoMock.Object);
        services.AddScoped(_ => _alertRepoMock.Object);
        var sp = services.BuildServiceProvider();

        return new RecurringScheduleProcessor(
            sp.GetRequiredService<IServiceScopeFactory>(),
            NullLogger<RecurringScheduleProcessor>.Instance,
            () => nowUtc);
    }
}
