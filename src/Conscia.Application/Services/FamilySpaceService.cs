using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.DTOs;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class FamilySpaceService : IFamilySpaceService
{
    private static readonly JsonSerializerOptions OutboxJsonOptions = new(JsonSerializerDefaults.Web);
    private const string ImportWarning =
        "These records will become visible to your Family Space. They stay in your Personal timeline with a Family badge.";

    private readonly IFamilySpaceRepository _repository;
    private readonly ISubscriptionService _subscriptions;
    private readonly IOutboxEventRepository _outboxEvents;
    private readonly ITransactionRepository _transactions;
    private readonly IBudgetRepository _budgets;
    private readonly IRecurringScheduleRepository _recurringSchedules;
    private readonly ILogger<FamilySpaceService> _logger;

    public FamilySpaceService(
        IFamilySpaceRepository repository,
        ISubscriptionService subscriptions,
        IOutboxEventRepository outboxEvents,
        ITransactionRepository transactions,
        IBudgetRepository budgets,
        IRecurringScheduleRepository recurringSchedules,
        ILogger<FamilySpaceService> logger)
    {
        _repository = repository;
        _subscriptions = subscriptions;
        _outboxEvents = outboxEvents;
        _transactions = transactions;
        _budgets = budgets;
        _recurringSchedules = recurringSchedules;
        _logger = logger;
    }

    public async Task<FamilySpace> CreateAsync(
        Guid userId,
        string name,
        string currencyCode,
        CancellationToken ct = default)
    {
        var premium = await _subscriptions.IsPremiumAsync(userId, ct);
        if (!premium)
            throw new InvalidOperationException("Family Space requires Premium.");

        var existingMembership = await _repository.GetMembershipByUserIdAsync(userId, ct);
        if (existingMembership is not null)
            throw new InvalidOperationException("You already belong to a Family Space.");

        var now = DateTime.UtcNow;
        var space = new FamilySpace
        {
            Id = Guid.NewGuid(),
            Name = name.Trim(),
            CurrencyCode = currencyCode.Trim().ToUpperInvariant(),
            CreatedByUserId = userId,
            CreatedAt = now
        };

        var owner = new FamilyMember
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = space.Id,
            UserId = userId,
            Role = FamilyMemberRole.Owner,
            JoinedAt = now
        };

        _logger.LogInformation("Creating Family Space {FamilySpaceId} for user {UserId}", space.Id, userId);
        return await _repository.CreateWithOwnerAsync(space, owner, ct);
    }

    public async Task<FamilySpaceDto?> GetCurrentAsync(Guid userId, CancellationToken ct = default)
    {
        var membership = await _repository.GetMembershipByUserIdAsync(userId, ct);
        if (membership is null)
            return null;

        var space = await _repository.GetByIdAsync(membership.FamilySpaceId, ct);
        if (space is null)
            return null;

        return new FamilySpaceDto(
            space.Id,
            space.Name,
            space.CurrencyCode,
            space.IsReadOnly,
            membership.Role.ToString());
    }

    public async Task<FamilySpaceDto> UpdateAsync(
        Guid userId,
        string name,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidOperationException("Family Space name is required.");

        var member = await RequireMemberAsync(userId, ct);
        if (member.Role != FamilyMemberRole.Owner)
            throw new UnauthorizedAccessException("Only Family Space owners can edit household settings.");

        var space = await _repository.GetByIdAsync(member.FamilySpaceId, ct)
            ?? throw new InvalidOperationException("Family Space was not found.");

        if (space.IsReadOnly)
            throw new InvalidOperationException("Family Space is read-only while Premium is inactive.");

        space.Name = name.Trim();
        var updated = await _repository.UpdateAsync(space, ct);

        return new FamilySpaceDto(
            updated.Id,
            updated.Name,
            updated.CurrencyCode,
            updated.IsReadOnly,
            member.Role.ToString());
    }

    public async Task<FamilySpaceOverviewDto> GetOverviewAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await RequireMemberAsync(userId, ct);
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

        var budgets = await _budgets.ListByFamilySpaceAsync(member.FamilySpaceId, ct);
        var transactions = await _transactions.GetByFamilySpaceAndDateRangeAsync(
            member.FamilySpaceId,
            monthStart,
            monthEnd,
            ct);
        var recurring = await _recurringSchedules.ListByFamilySpaceAsync(member.FamilySpaceId, ct);

        var expensesByCategory = transactions
            .Where(t => t.Type == TransactionType.Expense)
            .GroupBy(t => t.Category, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                g => g.Key,
                g => g.Sum(t => t.Amount.Amount),
                StringComparer.OrdinalIgnoreCase);

        return new FamilySpaceOverviewDto(
            member.FamilySpaceId,
            budgets
                .OrderBy(b => b.Category)
                .Select(b =>
                {
                    var spent = expensesByCategory.GetValueOrDefault(b.Category, 0m);
                    var usagePercent = b.MonthlyLimit <= 0
                        ? 0
                        : (int)Math.Round(spent / b.MonthlyLimit * 100m, MidpointRounding.AwayFromZero);

                    return new FamilyBudgetOverviewDto(
                        b.Id,
                        b.Category,
                        b.MonthlyLimit,
                        spent,
                        usagePercent,
                        b.CurrencyCode);
                })
                .ToList(),
            transactions
                .OrderByDescending(t => t.Date)
                .Take(5)
                .Select(t => new FamilyActivityDto(
                    t.Id,
                    string.IsNullOrWhiteSpace(t.Counterparty) ? t.Category : t.Counterparty,
                    t.Category,
                    t.Type.ToString(),
                    t.Amount.Amount,
                    t.Amount.CurrencyCode,
                    t.Date))
                .ToList(),
            recurring
                .Where(s => s.IsActive)
                .OrderBy(s => s.NextRunAt)
                .Take(5)
                .Select(s => new FamilyRecurringOverviewDto(
                    s.Id,
                    string.IsNullOrWhiteSpace(s.Counterparty) ? $"{s.Category} recurring" : s.Counterparty,
                    s.Category,
                    s.Type.ToString(),
                    s.Amount.Amount,
                    s.Amount.CurrencyCode,
                    s.Cadence.ToString(),
                    s.NextRunAt))
                .ToList());
    }

    public async Task<FamilyInvite> InviteAsync(
        Guid inviterUserId,
        string email,
        FamilyMemberRole role,
        CancellationToken ct = default)
    {
        var inviter = await _repository.GetMembershipByUserIdAsync(inviterUserId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

        if (inviter.Role != FamilyMemberRole.Owner)
            throw new UnauthorizedAccessException("Only Family Space owners can invite members.");

        if (role == FamilyMemberRole.Owner)
            throw new InvalidOperationException("Invite members as Contributor or Viewer first, then promote after they join.");

        var familySpace = await _repository.GetByIdAsync(inviter.FamilySpaceId, ct);
        var now = DateTime.UtcNow;
        var invite = new FamilyInvite
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = inviter.FamilySpaceId,
            Email = NormalizeEmail(email),
            Role = role,
            InvitedByUserId = inviterUserId,
            CreatedAt = now,
            ExpiresAt = now.AddDays(14)
        };

        var result = await _repository.AddInviteAsync(invite, ct);
        await _outboxEvents.AddAsync(CreateInviteCreatedEvent(result, familySpace?.Name), ct);
        return result;
    }

    public async Task<IReadOnlyList<FamilyInviteDto>> GetPendingInvitesAsync(
        string email,
        CancellationToken ct = default)
    {
        var invites = await _repository.ListActiveInvitesByEmailAsync(NormalizeEmail(email), ct);
        var results = new List<FamilyInviteDto>(invites.Count);

        foreach (var invite in invites)
        {
            var space = await _repository.GetByIdAsync(invite.FamilySpaceId, ct);
            results.Add(new FamilyInviteDto(
                invite.Id,
                invite.FamilySpaceId,
                space?.Name ?? "Family Space",
                invite.Email,
                invite.Role.ToString(),
                invite.CreatedAt,
                invite.ExpiresAt));
        }

        return results;
    }

    public async Task<FamilyMember> AcceptInviteAsync(
        Guid userId,
        string email,
        Guid inviteId,
        CancellationToken ct = default)
    {
        var existingMembership = await _repository.GetMembershipByUserIdAsync(userId, ct);
        if (existingMembership is not null)
            throw new InvalidOperationException("You already belong to a Family Space.");

        var invite = await RequireUsableInviteAsync(inviteId, email, ct);
        var now = DateTime.UtcNow;
        invite.AcceptedAt = now;

        var member = new FamilyMember
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = invite.FamilySpaceId,
            UserId = userId,
            Role = invite.Role,
            JoinedAt = now
        };

        var result = await _repository.AddMemberAsync(member, ct);
        await _repository.UpdateInviteAsync(invite, ct);
        return result;
    }

    public async Task DeclineInviteAsync(
        Guid userId,
        string email,
        Guid inviteId,
        CancellationToken ct = default)
    {
        _ = userId;
        var invite = await RequireUsableInviteAsync(inviteId, email, ct);
        invite.DeclinedAt = DateTime.UtcNow;
        await _repository.UpdateInviteAsync(invite, ct);
    }

    public async Task<FamilyImportPreviewDto> PreviewImportAsync(
        Guid userId,
        FamilyImportPreviewRequestDto request,
        CancellationToken ct = default)
    {
        var member = await RequireContributorAsync(userId, ct);
        var categories = CreateCategoryFilter(request.Categories);
        var items = new List<FamilyImportItemDto>();
        var (from, to) = ResolveImportDateRange(request.From, request.To);

        if (request.IncludeTransactions)
        {
            var transactions = await _transactions.GetByUserIdAndDateRangeAsync(userId, from, to, ct);
            items.AddRange(transactions
                .Where(t => t.Scope == RecordScope.Personal && MatchesCategory(t.Category, categories))
                .Select(t => new FamilyImportItemDto(
                    "transaction",
                    t.Id,
                    string.IsNullOrWhiteSpace(t.Counterparty) ? t.Category : t.Counterparty,
                    t.Category,
                    t.Amount.Amount,
                    t.Amount.CurrencyCode)));
        }

        if (request.IncludeBudgets)
        {
            var budgets = await _budgets.ListByUserAsync(userId, ct);
            items.AddRange(budgets
                .Where(b => b.Scope == RecordScope.Personal && MatchesCategory(b.Category, categories))
                .Select(b => new FamilyImportItemDto(
                    "budget",
                    b.Id,
                    $"{b.Category} budget",
                    b.Category,
                    b.MonthlyLimit,
                    b.CurrencyCode)));
        }

        if (request.IncludeRecurringSchedules)
        {
            var schedules = await _recurringSchedules.ListAsync(userId, ct);
            items.AddRange(schedules
                .Where(s => s.Scope == RecordScope.Personal && MatchesCategory(s.Category, categories))
                .Select(s => new FamilyImportItemDto(
                    "recurringSchedule",
                    s.Id,
                    string.IsNullOrWhiteSpace(s.Counterparty) ? $"{s.Category} recurring" : s.Counterparty,
                    s.Category,
                    s.Amount.Amount,
                    s.Amount.CurrencyCode)));
        }

        return new FamilyImportPreviewDto(member.FamilySpaceId, ImportWarning, items);
    }

    public async Task<int> ImportAsync(
        Guid userId,
        FamilyImportRequestDto request,
        CancellationToken ct = default)
    {
        var member = await RequireContributorAsync(userId, ct);
        var imported = 0;

        foreach (var item in request.Items)
        {
            if (string.Equals(item.RecordType, "transaction", StringComparison.OrdinalIgnoreCase))
            {
                var transaction = await _transactions.GetByIdAsync(userId, item.RecordId, ct)
                    ?? throw new InvalidOperationException("Transaction was not found.");
                EnsurePersonalRecord(transaction.Scope, "Transaction");
                ShareRecord(transaction, member, userId);
                await _transactions.UpdateAsync(transaction, ct);
                imported++;
                continue;
            }

            if (string.Equals(item.RecordType, "budget", StringComparison.OrdinalIgnoreCase))
            {
                var budget = await _budgets.GetByIdAsync(item.RecordId, ct)
                    ?? throw new InvalidOperationException("Budget was not found.");
                if (budget.UserId != userId)
                    throw new UnauthorizedAccessException("Budget belongs to a different user.");

                EnsurePersonalRecord(budget.Scope, "Budget");
                ShareRecord(budget, member, userId);
                await _budgets.UpdateAsync(budget, ct);
                imported++;
                continue;
            }

            if (string.Equals(item.RecordType, "recurringSchedule", StringComparison.OrdinalIgnoreCase))
            {
                var schedule = await _recurringSchedules.GetByIdAsync(userId, item.RecordId, ct)
                    ?? throw new InvalidOperationException("Recurring schedule was not found.");
                EnsurePersonalRecord(schedule.Scope, "Recurring schedule");
                ShareRecord(schedule, member, userId);
                await _recurringSchedules.UpdateAsync(schedule, ct);
                imported++;
                continue;
            }

            throw new InvalidOperationException($"Unsupported import record type '{item.RecordType}'.");
        }

        return imported;
    }

    private async Task<FamilyInvite> RequireUsableInviteAsync(
        Guid inviteId,
        string email,
        CancellationToken ct)
    {
        var normalizedEmail = NormalizeEmail(email);
        var invite = await _repository.GetInviteAsync(inviteId, ct)
            ?? throw new InvalidOperationException("Family invite was not found.");

        if (!string.Equals(invite.Email, normalizedEmail, StringComparison.OrdinalIgnoreCase))
            throw new UnauthorizedAccessException("This invite belongs to a different email.");

        if (invite.AcceptedAt is not null || invite.DeclinedAt is not null || invite.ExpiresAt <= DateTime.UtcNow)
            throw new InvalidOperationException("Family invite is no longer active.");

        return invite;
    }

    private async Task<FamilyMember> RequireContributorAsync(Guid userId, CancellationToken ct)
    {
        var member = await RequireMemberAsync(userId, ct);

        if (member.Role == FamilyMemberRole.Viewer)
            throw new UnauthorizedAccessException("Viewer cannot share records.");

        return member;
    }

    private async Task<FamilyMember> RequireMemberAsync(Guid userId, CancellationToken ct) =>
        await _repository.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

    private static (DateTime From, DateTime To) ResolveImportDateRange(DateTime? from, DateTime? to)
    {
        if (from.HasValue && to.HasValue)
            return (from.Value, to.Value);

        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);
        return (from ?? monthStart, to ?? monthEnd);
    }

    private static HashSet<string> CreateCategoryFilter(IReadOnlyList<string>? categories) =>
        categories is { Count: > 0 }
            ? categories
                .Where(c => !string.IsNullOrWhiteSpace(c))
                .Select(c => c.Trim())
                .ToHashSet(StringComparer.OrdinalIgnoreCase)
            : [];

    private static bool MatchesCategory(string category, HashSet<string> categories) =>
        categories.Count == 0 || categories.Contains(category);

    private static void EnsurePersonalRecord(RecordScope scope, string label)
    {
        if (scope != RecordScope.Personal)
            throw new InvalidOperationException($"{label} is already shared with a Family Space.");
    }

    private static void ShareRecord(Transaction transaction, FamilyMember member, Guid sharedByUserId)
    {
        transaction.Scope = RecordScope.Family;
        transaction.FamilySpaceId = member.FamilySpaceId;
        transaction.SharedAt = DateTime.UtcNow;
        transaction.SharedByUserId = sharedByUserId;
    }

    private static void ShareRecord(Budget budget, FamilyMember member, Guid sharedByUserId)
    {
        budget.Scope = RecordScope.Family;
        budget.FamilySpaceId = member.FamilySpaceId;
        budget.SharedAt = DateTime.UtcNow;
        budget.SharedByUserId = sharedByUserId;
    }

    private static void ShareRecord(RecurringSchedule schedule, FamilyMember member, Guid sharedByUserId)
    {
        schedule.Scope = RecordScope.Family;
        schedule.FamilySpaceId = member.FamilySpaceId;
        schedule.SharedAt = DateTime.UtcNow;
        schedule.SharedByUserId = sharedByUserId;
    }

    private static OutboxEvent CreateInviteCreatedEvent(FamilyInvite invite, string? familySpaceName) => new()
    {
        Id = Guid.NewGuid(),
        AggregateId = invite.Id,
        EventType = OutboxEventType.FamilyInviteCreated,
        Payload = JsonSerializer.Serialize(new
        {
            InviteId = invite.Id,
            FamilySpaceId = invite.FamilySpaceId,
            Email = invite.Email,
            Role = invite.Role.ToString(),
            InvitedByUserId = invite.InvitedByUserId,
            FamilySpaceName = string.IsNullOrWhiteSpace(familySpaceName)
                ? "your Family Space"
                : familySpaceName,
            ExpiresAt = invite.ExpiresAt
        }, OutboxJsonOptions),
        CreatedAt = DateTime.UtcNow
    };

    private static string NormalizeEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new InvalidOperationException("Invite email is required.");

        return email.Trim().ToLowerInvariant();
    }
}
