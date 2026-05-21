using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class RecurringScheduleProcessor : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<RecurringScheduleProcessor> _logger;
    private readonly Func<DateTime> _utcNow;
    private readonly TimeSpan _interval = TimeSpan.FromMinutes(5);

    public RecurringScheduleProcessor(
        IServiceScopeFactory scopeFactory,
        ILogger<RecurringScheduleProcessor> logger,
        Func<DateTime>? utcNow = null)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _utcNow = utcNow ?? (() => DateTime.UtcNow);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOnceAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Error processing recurring schedules");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    public async Task ProcessOnceAsync(CancellationToken ct = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var scheduleRepository = scope.ServiceProvider.GetRequiredService<IRecurringScheduleRepository>();
        var generator = scope.ServiceProvider.GetRequiredService<IRecurringScheduleGenerator>();
        var transactionRepository = scope.ServiceProvider.GetRequiredService<ITransactionRepository>();
        var alertRepository = scope.ServiceProvider.GetRequiredService<IInAppAlertRepository>();

        var nowUtc = _utcNow();
        var dueSchedules = await scheduleRepository.ListDueAsync(nowUtc, ct);

        foreach (var schedule in dueSchedules)
        {
            var occurrences = await generator.CalculateOccurrencesAsync(schedule, nowUtc, ct);
            foreach (var occurrence in occurrences)
            {
                var exists = await transactionRepository.ExistsRecurringOccurrenceAsync(
                    schedule.UserId,
                    schedule.Id,
                    occurrence.OccurrenceDate,
                    ct);

                if (exists)
                    continue;

                var transaction = new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = schedule.UserId,
                    Type = schedule.Type,
                    Amount = new(schedule.Amount.Amount, schedule.Amount.CurrencyCode, schedule.Amount.ExchangeRateToBase),
                    Category = schedule.Category,
                    Counterparty = schedule.Counterparty,
                    Date = occurrence.OccurrenceDate,
                    RecurringScheduleId = schedule.Id,
                    RecurringOccurrenceDate = occurrence.OccurrenceDate,
                    CreatedAt = nowUtc,
                };

                await transactionRepository.AddWithOutboxAsync(
                    transaction,
                    CreateTransactionCreatedEvent(transaction, nowUtc),
                    ct);
                await alertRepository.AddAsync(BuildReminderAlert(schedule, transaction, nowUtc), ct);
                schedule.LastGeneratedAt = occurrence.OccurrenceDate;
            }

            schedule.NextRunAt = CalculateNextRun(schedule, nowUtc);
            schedule.UpdatedAt = nowUtc;
            await scheduleRepository.UpdateAsync(schedule, ct);
        }
    }

    private static DateTime CalculateNextRun(RecurringSchedule schedule, DateTime nowUtc)
    {
        var next = schedule.NextRunAt;

        while (next <= nowUtc && (!schedule.EndDate.HasValue || next <= schedule.EndDate.Value))
        {
            next = schedule.Cadence switch
            {
                RecurringCadence.Weekly => next.AddDays(7),
                RecurringCadence.Monthly => AdvanceMonthly(schedule.StartDate, next),
                RecurringCadence.Yearly => AdvanceYearly(schedule.StartDate, next),
                _ => throw new ArgumentOutOfRangeException(nameof(schedule.Cadence)),
            };
        }

        return next;
    }

    private static DateTime AdvanceMonthly(DateTime anchor, DateTime current)
    {
        var nextMonth = current.AddMonths(1);
        var day = Math.Min(anchor.Day, DateTime.DaysInMonth(nextMonth.Year, nextMonth.Month));
        return new DateTime(nextMonth.Year, nextMonth.Month, day, anchor.Hour, anchor.Minute, anchor.Second, DateTimeKind.Utc);
    }

    private static DateTime AdvanceYearly(DateTime anchor, DateTime current)
    {
        var nextYear = current.Year + 1;
        var day = Math.Min(anchor.Day, DateTime.DaysInMonth(nextYear, anchor.Month));
        return new DateTime(nextYear, anchor.Month, day, anchor.Hour, anchor.Minute, anchor.Second, DateTimeKind.Utc);
    }

    private static InAppAlert BuildReminderAlert(RecurringSchedule schedule, Transaction transaction, DateTime nowUtc)
    {
        var recurringLabel = transaction.Type == Domain.Enums.TransactionType.Income
            ? "Recurring income added"
            : "Recurring transaction added";

        var subject = schedule.Counterparty ?? schedule.Category;

        return new InAppAlert
        {
            UserId = schedule.UserId,
            AlertKey = $"recurring:{schedule.Id:N}:{transaction.RecurringOccurrenceDate:O}",
            TriggerName = "recurring_transaction_created",
            Title = recurringLabel,
            Message = $"{subject} was added automatically.",
            Counterparty = schedule.Counterparty,
            Category = schedule.Category,
            TransactionId = transaction.Id,
            Priority = 30,
            ActionLabel = "View transaction",
            ActionRoute = $"/transactions/{transaction.Id}",
            CreatedAt = nowUtc,
            TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
        };
    }

    private static OutboxEvent CreateTransactionCreatedEvent(Transaction transaction, DateTime nowUtc) =>
        new()
        {
            Id = Guid.NewGuid(),
            AggregateId = transaction.Id,
            EventType = OutboxEventType.TransactionCreated,
            Payload = JsonSerializer.Serialize(new
            {
                TransactionId = transaction.Id,
                transaction.UserId,
                Type = transaction.Type.ToString(),
                transaction.Category,
                Amount = transaction.Amount.Amount,
                CurrencyCode = transaction.Amount.CurrencyCode,
                TransactionDate = transaction.Date,
                Scope = transaction.Scope.ToString(),
                transaction.FamilySpaceId,
                transaction.SharedByUserId,
                transaction.SharedAt
            }),
            CreatedAt = nowUtc
        };
}
