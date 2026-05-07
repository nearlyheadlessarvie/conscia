using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

/// <summary>
/// Polls OutboxEvents table for pending events and dispatches side-effects:
/// - TransactionCreated → increment budget spend
/// - TransactionDeleted → decrement budget spend
/// Processing runs on a configurable interval with batch-based polling.
/// </summary>
public class OutboxProcessor : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<OutboxProcessor> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromSeconds(5);

    public OutboxProcessor(IServiceScopeFactory scopeFactory, ILogger<OutboxProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("OutboxProcessor started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessBatchAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Error processing outbox batch");
            }

            await Task.Delay(_interval, stoppingToken);
        }

        _logger.LogInformation("OutboxProcessor stopped");
    }

    private async Task ProcessBatchAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var outboxRepo = scope.ServiceProvider.GetRequiredService<IOutboxEventRepository>();
        var budgetRepo = scope.ServiceProvider.GetRequiredService<IBudgetRepository>();

        var pending = await outboxRepo.GetPendingAsync(50, ct);
        if (pending.Count == 0) return;

        _logger.LogDebug("Processing {Count} outbox events", pending.Count);

        foreach (var evt in pending)
        {
            var claimed = false;
            try
            {
                claimed = await outboxRepo.TryStartProcessingAsync(evt, ct);
                if (!claimed)
                {
                    _logger.LogDebug("Skipping outbox event {EventId}; it was already claimed", evt.Id);
                    continue;
                }

                _logger.LogInformation("Processing outbox event {EventId}: {EventType}", evt.Id, evt.EventType);
                await DispatchEventAsync(evt.EventType, evt.Payload, budgetRepo, ct);
                await outboxRepo.MarkProcessedAsync(evt, ct);
            }
            catch (Exception ex)
            {
                if (claimed)
                {
                    try
                    {
                        await outboxRepo.MarkPendingAsync(evt, ct);
                    }
                    catch (Exception revertEx)
                    {
                        _logger.LogError(revertEx, "Failed to return outbox event {EventId} to pending", evt.Id);
                    }
                }

                _logger.LogError(ex, "Failed to process outbox event {EventId}: {Error}",
                    evt.Id, ex.Message);
            }
        }
    }

    private async Task DispatchEventAsync(
        OutboxEventType eventType, string payload,
        IBudgetRepository budgetRepo, CancellationToken ct)
    {
        using var doc = JsonDocument.Parse(payload);
        var root = doc.RootElement;

        switch (eventType)
        {
            case OutboxEventType.TransactionCreated:
            {
                var category = root.GetProperty("Category").GetString()!;
                var userId = Guid.Parse(root.GetProperty("UserId").GetString()!);
                var amount = root.GetProperty("Amount").GetDecimal();

                var budgets = await budgetRepo.ListByUserAsync(userId, ct);
                var matched = budgets.FirstOrDefault(b =>
                    b.Category.Equals(category, StringComparison.OrdinalIgnoreCase));

                if (matched is not null)
                {
                    await budgetRepo.IncrementCurrentSpendAsync(matched.Id, amount, ct);
                    _logger.LogInformation(
                        "Budget {BudgetId} incremented by {Amount} for category {Category}",
                        matched.Id, amount, category);
                }

                break;
            }
            case OutboxEventType.TransactionDeleted:
            {
                _logger.LogInformation("TransactionDeleted event processed (no budget rollback in MVP)");
                break;
            }
            case OutboxEventType.TransactionUpdated:
            {
                _logger.LogInformation("TransactionUpdated event processed (no-op in MVP)");
                break;
            }
            default:
                _logger.LogWarning("Unknown outbox event type: {EventType}", eventType);
                break;
        }
    }
}
