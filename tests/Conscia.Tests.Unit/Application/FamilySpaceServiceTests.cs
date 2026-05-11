using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using System.Text.Json;

namespace Conscia.Tests.Unit.Application;

public class FamilySpaceServiceTests
{
    private readonly Mock<IFamilySpaceRepository> _repo = new();
    private readonly Mock<ISubscriptionService> _subscriptions = new();
    private readonly Mock<IOutboxEventRepository> _outboxEvents = new();
    private readonly Mock<ITransactionRepository> _transactions = new();
    private readonly Mock<IBudgetRepository> _budgets = new();
    private readonly Mock<IRecurringScheduleRepository> _recurringSchedules = new();

    private FamilySpaceService CreateService() =>
        new(
            _repo.Object,
            _subscriptions.Object,
            _outboxEvents.Object,
            _transactions.Object,
            _budgets.Object,
            _recurringSchedules.Object,
            NullLogger<FamilySpaceService>.Instance);

    [Fact]
    public async Task CreateAsync_PremiumUserWithoutFamily_CreatesSpaceAndOwnerMembership()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);
        _repo.Setup(r => r.CreateWithOwnerAsync(
                It.IsAny<FamilySpace>(),
                It.IsAny<FamilyMember>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilySpace space, FamilyMember _, CancellationToken _) => space);

        var result = await CreateService().CreateAsync(userId, "Santos Household", "PHP");

        Assert.Equal("Santos Household", result.Name);
        Assert.Equal("PHP", result.CurrencyCode);
        _repo.Verify(r => r.CreateWithOwnerAsync(
            It.Is<FamilySpace>(s => s.CreatedByUserId == userId && !s.IsReadOnly),
            It.Is<FamilyMember>(m => m.UserId == userId && m.Role == FamilyMemberRole.Owner),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_FreeUser_ThrowsUpgradeRequired()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("Family Space requires Premium.", error.Message);
    }

    [Fact]
    public async Task CreateAsync_UserAlreadyInFamily_Throws()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = Guid.NewGuid() });

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("You already belong to a Family Space.", error.Message);
    }

    [Fact]
    public async Task InviteAsync_OwnerCreatesPendingInviteAndOutboxEvent()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
        _repo.Setup(r => r.AddInviteAsync(It.IsAny<FamilyInvite>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyInvite invite, CancellationToken _) => invite);
        _outboxEvents.Setup(r => r.AddAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((OutboxEvent evt, CancellationToken _) => evt);

        var invite = await CreateService().InviteAsync(ownerId, " Wife@Example.com ", FamilyMemberRole.Contributor);

        Assert.Equal("wife@example.com", invite.Email);
        Assert.Equal(FamilyMemberRole.Contributor, invite.Role);
        Assert.Equal(familySpaceId, invite.FamilySpaceId);
        Assert.True(invite.ExpiresAt > DateTime.UtcNow.AddDays(13));
        _outboxEvents.Verify(r => r.AddAsync(
            It.Is<OutboxEvent>(evt =>
                evt.AggregateId == invite.Id &&
                evt.EventType == OutboxEventType.FamilyInviteCreated &&
                PayloadHasEmail(evt.Payload, "wife@example.com")),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task InviteAsync_ContributorCannotInvite()
    {
        var contributorId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(contributorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = contributorId,
                FamilySpaceId = Guid.NewGuid(),
                Role = FamilyMemberRole.Contributor
            });

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            CreateService().InviteAsync(contributorId, "wife@example.com", FamilyMemberRole.Contributor));

        Assert.Equal("Only Family Space owners can invite members.", error.Message);
        _outboxEvents.Verify(r => r.AddAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task AcceptInviteAsync_ValidInvite_AddsMemberAndMarksInviteAccepted()
    {
        var userId = Guid.NewGuid();
        var inviteId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var invite = new FamilyInvite
        {
            Id = inviteId,
            FamilySpaceId = familySpaceId,
            Email = "wife@example.com",
            Role = FamilyMemberRole.Contributor,
            ExpiresAt = DateTime.UtcNow.AddDays(1)
        };
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);
        _repo.Setup(r => r.GetInviteAsync(inviteId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(invite);
        _repo.Setup(r => r.AddMemberAsync(It.IsAny<FamilyMember>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember member, CancellationToken _) => member);

        var member = await CreateService().AcceptInviteAsync(userId, " Wife@Example.com ", inviteId);

        Assert.Equal(familySpaceId, member.FamilySpaceId);
        Assert.Equal(userId, member.UserId);
        Assert.Equal(FamilyMemberRole.Contributor, member.Role);
        Assert.NotNull(invite.AcceptedAt);
        _repo.Verify(r => r.UpdateInviteAsync(invite, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task PreviewImportAsync_ContributorPreviewsOnlyPersonalRecordsMatchingCategory()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var from = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc);
        var to = new DateTime(2026, 5, 31, 23, 59, 59, DateTimeKind.Utc);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Contributor });
        _transactions.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, from, to, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = TransactionType.Expense,
                    Amount = new Money(280m, "PHP"),
                    Category = "Dining",
                    Counterparty = "Starbucks",
                    Date = from.AddDays(1),
                    Scope = RecordScope.Personal
                },
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = TransactionType.Expense,
                    Amount = new Money(1200m, "PHP"),
                    Category = "Dining",
                    Counterparty = "Family dinner",
                    Date = from.AddDays(2),
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _budgets.Setup(r => r.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Budget
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Dining",
                    MonthlyLimit = 4000m,
                    CurrencyCode = "PHP",
                    Scope = RecordScope.Personal
                },
                new Budget
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Category = "Bills",
                    MonthlyLimit = 12000m,
                    CurrencyCode = "PHP",
                    Scope = RecordScope.Personal
                }
            ]);
        _recurringSchedules.Setup(r => r.ListAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new RecurringSchedule
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = TransactionType.Expense,
                    Amount = new Money(1800m, "PHP"),
                    Category = "Dining",
                    Counterparty = "Coffee subscription",
                    StartDate = from,
                    Cadence = RecurringCadence.Monthly,
                    NextRunAt = from,
                    Scope = RecordScope.Personal
                }
            ]);

        var preview = await CreateService().PreviewImportAsync(userId, new FamilyImportPreviewRequestDto(
            IncludeTransactions: true,
            IncludeBudgets: true,
            IncludeRecurringSchedules: true,
            From: from,
            To: to,
            Categories: ["Dining"]));

        Assert.Equal(familySpaceId, preview.FamilySpaceId);
        Assert.Contains("visible to your Family Space", preview.Warning);
        Assert.Equal(3, preview.Items.Count);
        Assert.Contains(preview.Items, i => i.RecordType == "transaction" && i.Label == "Starbucks" && i.Amount == 280m);
        Assert.Contains(preview.Items, i => i.RecordType == "budget" && i.Label == "Dining budget" && i.Amount == 4000m);
        Assert.Contains(preview.Items, i => i.RecordType == "recurringSchedule" && i.Label == "Coffee subscription" && i.Amount == 1800m);
        Assert.DoesNotContain(preview.Items, i => i.Label == "Family dinner" || i.Category == "Bills");
    }

    [Fact]
    public async Task PreviewImportAsync_ViewerCannotPreviewImport()
    {
        var userId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = Guid.NewGuid(),
                Role = FamilyMemberRole.Viewer
            });

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            CreateService().PreviewImportAsync(userId, new FamilyImportPreviewRequestDto(
                IncludeTransactions: true,
                IncludeBudgets: false,
                IncludeRecurringSchedules: false,
                From: null,
                To: null,
                Categories: [])));

        Assert.Equal("Viewer cannot share records.", error.Message);
    }

    [Fact]
    public async Task ImportAsync_ContributorMarksSelectedPersonalRecordsAsFamily()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var budgetId = Guid.NewGuid();
        var recurringScheduleId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Contributor });
        _transactions.Setup(r => r.GetByIdAsync(userId, transactionId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Transaction
            {
                Id = transactionId,
                UserId = userId,
                Type = TransactionType.Expense,
                Amount = new Money(280m, "PHP"),
                Category = "Dining",
                Date = DateTime.UtcNow,
                Scope = RecordScope.Personal
            });
        _budgets.Setup(r => r.GetByIdAsync(budgetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget
            {
                Id = budgetId,
                UserId = userId,
                Category = "Dining",
                MonthlyLimit = 4000m,
                CurrencyCode = "PHP",
                Scope = RecordScope.Personal
            });
        _recurringSchedules.Setup(r => r.GetByIdAsync(userId, recurringScheduleId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RecurringSchedule
            {
                Id = recurringScheduleId,
                UserId = userId,
                Type = TransactionType.Income,
                Amount = new Money(15000m, "PHP"),
                Category = "Salary",
                StartDate = DateTime.UtcNow,
                Cadence = RecurringCadence.Monthly,
                NextRunAt = DateTime.UtcNow,
                Scope = RecordScope.Personal
            });

        var imported = await CreateService().ImportAsync(userId, new FamilyImportRequestDto([
            new FamilyImportSelectionDto("transaction", transactionId),
            new FamilyImportSelectionDto("budget", budgetId),
            new FamilyImportSelectionDto("recurringSchedule", recurringScheduleId)
        ]));

        Assert.Equal(3, imported);
        _transactions.Verify(r => r.UpdateAsync(
            It.Is<Transaction>(t =>
                t.Scope == RecordScope.Family &&
                t.FamilySpaceId == familySpaceId &&
                t.SharedByUserId == userId &&
                t.SharedAt.HasValue),
            It.IsAny<CancellationToken>()), Times.Once);
        _budgets.Verify(r => r.UpdateAsync(
            It.Is<Budget>(b =>
                b.Scope == RecordScope.Family &&
                b.FamilySpaceId == familySpaceId &&
                b.SharedByUserId == userId &&
                b.SharedAt.HasValue),
            It.IsAny<CancellationToken>()), Times.Once);
        _recurringSchedules.Verify(r => r.UpdateAsync(
            It.Is<RecurringSchedule>(s =>
                s.Scope == RecordScope.Family &&
                s.FamilySpaceId == familySpaceId &&
                s.SharedByUserId == userId &&
                s.SharedAt.HasValue),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    private static bool PayloadHasEmail(string payload, string email)
    {
        using var document = JsonDocument.Parse(payload);
        return document.RootElement.GetProperty("email").GetString() == email;
    }
}
