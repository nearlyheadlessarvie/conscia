using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

/// <summary>
/// Polls OutboxEvents table for pending events and acknowledges them after
/// dispatching any side-effects that still exist for the event type.
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

    public async Task RepairProjectionAsync(
        Guid userId,
        IReadOnlyList<string> monthKeys,
        CancellationToken ct = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var transactionRepository = scope.ServiceProvider.GetRequiredService<ITransactionRepository>();
        var projectionRepository = scope.ServiceProvider.GetRequiredService<IMonthlyCategorySpendRepository>();

        foreach (var monthKey in monthKeys)
            await RepairMonthAsync(userId, monthKey, transactionRepository, projectionRepository, ct);
    }

    public async Task ProcessBatchAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var outboxRepo = scope.ServiceProvider.GetRequiredService<IOutboxEventRepository>();
        var projectionRepo = scope.ServiceProvider.GetRequiredService<IMonthlyCategorySpendRepository>();
        var userRepo = scope.ServiceProvider.GetRequiredService<IUserRepository>();
        var alertRepo = scope.ServiceProvider.GetRequiredService<IInAppAlertRepository>();
        var pushSender = scope.ServiceProvider.GetRequiredService<IPushNotificationSender>();

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
                await DispatchEventAsync(evt, projectionRepo, userRepo, alertRepo, pushSender, ct);
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
        OutboxEvent evt,
        IMonthlyCategorySpendRepository projections,
        IUserRepository users,
        IInAppAlertRepository alerts,
        IPushNotificationSender pushSender,
        CancellationToken ct)
    {
        switch (evt.EventType)
        {
            case OutboxEventType.TransactionCreated:
                await ApplyCreatedAsync(evt, projections, ct);
                break;
            case OutboxEventType.TransactionDeleted:
                await ApplyDeletedAsync(evt, projections, ct);
                break;
            case OutboxEventType.TransactionUpdated:
                await ApplyUpdatedAsync(evt, projections, ct);
                break;
            case OutboxEventType.FamilyInviteCreated:
                await ApplyFamilyInviteCreatedAsync(evt, users, alerts, pushSender, ct);
                break;
            default:
                _logger.LogWarning("Unknown outbox event type: {EventType}", evt.EventType);
                break;
        }
    }

    private async Task ApplyFamilyInviteCreatedAsync(
        OutboxEvent evt,
        IUserRepository users,
        IInAppAlertRepository alerts,
        IPushNotificationSender pushSender,
        CancellationToken ct)
    {
        var invite = ParseFamilyInvite(evt.Payload);
        if (invite is null)
        {
            _logger.LogWarning("Family invite outbox event {EventId} has an invalid payload", evt.Id);
            return;
        }

        var user = await users.GetByEmailAsync(invite.Email, ct);
        if (user is null)
        {
            _logger.LogInformation(
                "Family invite {InviteId} targets unregistered email {Email}; skipping in-app and device notification",
                invite.InviteId,
                invite.Email);
            return;
        }

        const string title = "Family invite";
        var body = $"You were invited to {invite.FamilySpaceName}.";
        const string route = "/family-space/invites";

        await alerts.AddAsync(new InAppAlert
        {
            AlertKey = $"family-invite:{invite.InviteId}",
            UserId = user.Id,
            TriggerName = "family_invite_created",
            Title = title,
            Message = body,
            Priority = 60,
            ActionLabel = "Review invite",
            ActionRoute = route,
            CreatedAt = DateTime.UtcNow,
            TTL = new DateTimeOffset(DateTime.UtcNow.AddDays(30)).ToUnixTimeSeconds()
        }, ct);

        try
        {
            await pushSender.SendToUserAsync(user.Id, title, body, route, ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Best-effort push failed for family invite {InviteId}", invite.InviteId);
        }
    }

    private Task ApplyCreatedAsync(
        OutboxEvent evt,
        IMonthlyCategorySpendRepository projections,
        CancellationToken ct)
    {
        var current = ParseCurrentSnapshot(evt.Payload);
        return current is not null && current.Type == TransactionType.Expense
            ? ApplyDeltaAsync(current, 1, projections, evt.Id, ct)
            : Task.CompletedTask;
    }

    private Task ApplyDeletedAsync(
        OutboxEvent evt,
        IMonthlyCategorySpendRepository projections,
        CancellationToken ct)
    {
        var previous = ParsePreviousSnapshot(evt.Payload);
        return previous is not null && previous.Type == TransactionType.Expense
            ? ApplyDeltaAsync(previous, -1, projections, evt.Id, ct)
            : Task.CompletedTask;
    }

    private async Task ApplyUpdatedAsync(
        OutboxEvent evt,
        IMonthlyCategorySpendRepository projections,
        CancellationToken ct)
    {
        var previous = ParsePreviousSnapshot(evt.Payload);
        if (previous is not null && previous.Type == TransactionType.Expense)
            await ApplyDeltaAsync(previous, -1, projections, evt.Id, ct);

        var current = ParseCurrentSnapshot(evt.Payload);
        if (current is not null && current.Type == TransactionType.Expense)
            await ApplyDeltaAsync(current, 1, projections, evt.Id, ct);
    }

    private async Task ApplyDeltaAsync(
        TransactionProjectionSnapshot snapshot,
        int direction,
        IMonthlyCategorySpendRepository projections,
        Guid eventId,
        CancellationToken ct)
    {
        var monthKey = snapshot.TransactionDate.ToString("yyyy-MM");
        var normalizedCategory = NormalizeCategory(snapshot.Category);
        var existing = (await projections.ListRecentMonthsAsync(snapshot.UserId, [monthKey], ct))
            .FirstOrDefault(p => string.Equals(p.NormalizedCategory, normalizedCategory, StringComparison.Ordinal));

        var currentAmount = existing?.TotalExpenseAmount ?? 0m;
        var currentCount = existing?.TransactionCount ?? 0;
        var updatedAmount = currentAmount + (snapshot.Amount * direction);
        var updatedCount = currentCount + direction;

        if (updatedAmount < 0m || updatedCount < 0)
        {
            _logger.LogWarning(
                "Projection delta clamped for user {UserId}, category {Category}, month {MonthKey}, event {EventId}",
                snapshot.UserId,
                snapshot.Category,
                monthKey,
                eventId);
            updatedAmount = Math.Max(0m, updatedAmount);
            updatedCount = Math.Max(0, updatedCount);
        }

        await projections.UpsertAsync(new MonthlyCategorySpend
        {
            UserId = snapshot.UserId,
            MonthKey = monthKey,
            Category = existing?.Category ?? snapshot.Category,
            NormalizedCategory = normalizedCategory,
            CurrencyCode = existing?.CurrencyCode ?? snapshot.CurrencyCode,
            TotalExpenseAmount = updatedAmount,
            TransactionCount = updatedCount,
            LastUpdatedAt = DateTime.UtcNow
        }, ct);
    }

    private static TransactionProjectionSnapshot? ParseCurrentSnapshot(string payload)
    {
        using var doc = JsonDocument.Parse(payload);
        var root = doc.RootElement;

        if (!TryParseType(root, "Type", out var type)
            || !root.TryGetProperty("Category", out var categoryElement)
            || !root.TryGetProperty("Amount", out var amountElement)
            || !root.TryGetProperty("CurrencyCode", out var currencyElement)
            || !root.TryGetProperty("TransactionDate", out var dateElement)
            || !root.TryGetProperty("UserId", out var userIdElement))
        {
            return null;
        }

        return new TransactionProjectionSnapshot(
            Guid.Parse(userIdElement.GetString()!),
            type,
            categoryElement.GetString() ?? string.Empty,
            amountElement.GetDecimal(),
            currencyElement.GetString() ?? "USD",
            dateElement.GetDateTime());
    }

    private static TransactionProjectionSnapshot? ParsePreviousSnapshot(string payload)
    {
        using var doc = JsonDocument.Parse(payload);
        var root = doc.RootElement;

        if (!TryParseType(root, "PreviousType", out var type)
            || !root.TryGetProperty("PreviousCategory", out var categoryElement)
            || !root.TryGetProperty("PreviousAmount", out var amountElement)
            || !root.TryGetProperty("PreviousCurrencyCode", out var currencyElement)
            || !root.TryGetProperty("PreviousTransactionDate", out var dateElement)
            || !root.TryGetProperty("UserId", out var userIdElement))
        {
            return null;
        }

        return new TransactionProjectionSnapshot(
            Guid.Parse(userIdElement.GetString()!),
            type,
            categoryElement.GetString() ?? string.Empty,
            amountElement.GetDecimal(),
            currencyElement.GetString() ?? "USD",
            dateElement.GetDateTime());
    }

    private static bool TryParseType(JsonElement root, string propertyName, out TransactionType type)
    {
        type = default;
        return root.TryGetProperty(propertyName, out var typeElement)
            && Enum.TryParse(typeElement.GetString(), out type);
    }

    private static string NormalizeCategory(string category) =>
        category.Trim().ToLowerInvariant();

    private static FamilyInviteNotificationSnapshot? ParseFamilyInvite(string payload)
    {
        using var doc = JsonDocument.Parse(payload);
        var root = doc.RootElement;

        if (!root.TryGetProperty("InviteId", out var inviteIdElement)
            || !Guid.TryParse(inviteIdElement.GetString(), out var inviteId)
            || !root.TryGetProperty("Email", out var emailElement)
            || string.IsNullOrWhiteSpace(emailElement.GetString()))
        {
            return null;
        }

        var familySpaceName = root.TryGetProperty("FamilySpaceName", out var nameElement)
            && !string.IsNullOrWhiteSpace(nameElement.GetString())
                ? nameElement.GetString()!
                : "your Family Space";

        return new FamilyInviteNotificationSnapshot(
            inviteId,
            emailElement.GetString()!.Trim().ToLowerInvariant(),
            familySpaceName);
    }

    private async Task RepairMonthAsync(
        Guid userId,
        string monthKey,
        ITransactionRepository transactionRepository,
        IMonthlyCategorySpendRepository projectionRepository,
        CancellationToken ct)
    {
        var monthStart = DateTime.SpecifyKind(
            DateTime.ParseExact(monthKey + "-01", "yyyy-MM-dd", null),
            DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

        var totals = (await transactionRepository.GetByUserIdAndDateRangeAsync(userId, monthStart, monthEnd, ct))
            .Where(transaction => transaction.Type == TransactionType.Expense)
            .GroupBy(transaction => NormalizeCategory(transaction.Category))
            .Select(group => new MonthlyCategorySpend
            {
                UserId = userId,
                MonthKey = monthKey,
                Category = group.First().Category,
                NormalizedCategory = group.Key,
                CurrencyCode = group.First().Amount.CurrencyCode,
                TotalExpenseAmount = group.Sum(transaction => transaction.Amount.Amount),
                TransactionCount = group.Count(),
                LastUpdatedAt = DateTime.UtcNow
            })
            .ToList();

        foreach (var total in totals)
            await projectionRepository.UpsertAsync(total, ct);
    }

    private sealed record TransactionProjectionSnapshot(
        Guid UserId,
        TransactionType Type,
        string Category,
        decimal Amount,
        string CurrencyCode,
        DateTime TransactionDate);

    private sealed record FamilyInviteNotificationSnapshot(
        Guid InviteId,
        string Email,
        string FamilySpaceName);
}
