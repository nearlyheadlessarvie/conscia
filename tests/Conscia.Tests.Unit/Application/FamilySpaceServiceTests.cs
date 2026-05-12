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
    private readonly Mock<IUserRepository> _users = new();

    private FamilySpaceService CreateService() =>
        new(
            _repo.Object,
            _subscriptions.Object,
            _outboxEvents.Object,
            _transactions.Object,
            _budgets.Object,
            _recurringSchedules.Object,
            _users.Object,
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
    public async Task UpdateAsync_OwnerRenamesFamilySpace()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var space = new FamilySpace
        {
            Id = familySpaceId,
            Name = "Old Household",
            CurrencyCode = "PHP",
            CreatedByUserId = ownerId
        };
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
        _repo.Setup(r => r.GetByIdAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(space);
        _repo.Setup(r => r.UpdateAsync(It.IsAny<FamilySpace>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilySpace updated, CancellationToken _) => updated);

        var result = await CreateService().UpdateAsync(ownerId, "  Santos Family  ");

        Assert.Equal("Santos Family", result.Name);
        Assert.Equal("PHP", result.CurrencyCode);
        Assert.Equal("Owner", result.Role);
        _repo.Verify(r => r.UpdateAsync(
            It.Is<FamilySpace>(s => s.Id == familySpaceId && s.Name == "Santos Family"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateAsync_NonOwnerCannotRenameFamilySpace()
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
            CreateService().UpdateAsync(contributorId, "New Name"));

        Assert.Equal("Only Family Space owners can edit household settings.", error.Message);
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
    public async Task GetPendingInvitesAsync_ReturnsActiveInvitesWithFamilySpaceNames()
    {
        var familySpaceId = Guid.NewGuid();
        var inviteId = Guid.NewGuid();
        _repo.Setup(r => r.ListActiveInvitesByEmailAsync("wife@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyInvite
                {
                    Id = inviteId,
                    FamilySpaceId = familySpaceId,
                    Email = "wife@example.com",
                    Role = FamilyMemberRole.Contributor,
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                    ExpiresAt = DateTime.UtcNow.AddDays(13)
                }
            ]);
        _repo.Setup(r => r.GetByIdAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilySpace
            {
                Id = familySpaceId,
                Name = "Santos Household",
                CurrencyCode = "PHP"
            });

        var invites = await CreateService().GetPendingInvitesAsync(" Wife@Example.com ");

        var invite = Assert.Single(invites);
        Assert.Equal(inviteId, invite.Id);
        Assert.Equal("Santos Household", invite.FamilySpaceName);
        Assert.Equal("Contributor", invite.Role);
        _repo.Verify(r => r.ListActiveInvitesByEmailAsync("wife@example.com", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetOutgoingInvitesAsync_OwnerReceivesActiveFamilyInvites()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var inviteId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
        _repo.Setup(r => r.GetByIdAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilySpace
            {
                Id = familySpaceId,
                Name = "Santos Household",
                CurrencyCode = "PHP"
            });
        _repo.Setup(r => r.ListActiveInvitesByFamilySpaceAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyInvite
                {
                    Id = inviteId,
                    FamilySpaceId = familySpaceId,
                    Email = "wife@example.com",
                    Role = FamilyMemberRole.Contributor,
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                    ExpiresAt = DateTime.UtcNow.AddDays(13)
                }
            ]);

        var invites = await CreateService().GetOutgoingInvitesAsync(ownerId);

        var invite = Assert.Single(invites);
        Assert.Equal(inviteId, invite.Id);
        Assert.Equal("Santos Household", invite.FamilySpaceName);
        Assert.Equal("wife@example.com", invite.Email);
        Assert.Equal("Contributor", invite.Role);
    }

    [Fact]
    public async Task GetOutgoingInvitesAsync_ContributorCannotListOutgoingInvites()
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
            CreateService().GetOutgoingInvitesAsync(contributorId));

        Assert.Equal("Only Family Space owners can manage invites.", error.Message);
    }

    [Fact]
    public async Task CancelInviteAsync_OwnerDeletesActiveInviteForTheirFamily()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var inviteId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
        _repo.Setup(r => r.GetInviteAsync(inviteId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyInvite
            {
                Id = inviteId,
                FamilySpaceId = familySpaceId,
                Email = "wife@example.com",
                Role = FamilyMemberRole.Contributor,
                ExpiresAt = DateTime.UtcNow.AddDays(1)
            });

        await CreateService().CancelInviteAsync(ownerId, inviteId);

        _repo.Verify(r => r.DeleteInviteAsync(inviteId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetMembersAsync_ReturnsFamilyRosterWithCurrentUserFlag()
    {
        var ownerId = Guid.NewGuid();
        var spouseId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var ownerMemberId = Guid.NewGuid();
        var spouseMemberId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                Id = ownerMemberId,
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
        _repo.Setup(r => r.ListMembersAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyMember
                {
                    Id = ownerMemberId,
                    UserId = ownerId,
                    FamilySpaceId = familySpaceId,
                    Role = FamilyMemberRole.Owner,
                    JoinedAt = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc)
                },
                new FamilyMember
                {
                    Id = spouseMemberId,
                    UserId = spouseId,
                    FamilySpaceId = familySpaceId,
                    Role = FamilyMemberRole.Contributor,
                    JoinedAt = new DateTime(2026, 5, 2, 0, 0, 0, DateTimeKind.Utc)
                }
            ]);
        _users.Setup(r => r.GetByIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = ownerId, Email = "owner@example.com" });
        _users.Setup(r => r.GetByIdAsync(spouseId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = spouseId, Email = "spouse@example.com" });

        var members = await CreateService().GetMembersAsync(ownerId);

        Assert.Equal(2, members.Count);
        Assert.True(members[0].IsCurrentUser);
        Assert.Equal("owner@example.com", members[0].Email);
        Assert.False(members[1].IsCurrentUser);
        Assert.Equal("Contributor", members[1].Role);
    }

    [Fact]
    public async Task UpdateMemberRoleAsync_OwnerChangesContributorToViewer()
    {
        var ownerId = Guid.NewGuid();
        var targetUserId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var targetMemberId = Guid.NewGuid();
        var targetMember = new FamilyMember
        {
            Id = targetMemberId,
            UserId = targetUserId,
            FamilySpaceId = familySpaceId,
            Role = FamilyMemberRole.Contributor,
            JoinedAt = DateTime.UtcNow
        };
        SetupOwner(ownerId, familySpaceId);
        _repo.Setup(r => r.ListMembersAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyMember { Id = Guid.NewGuid(), UserId = ownerId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Owner },
                targetMember
            ]);
        _users.Setup(r => r.GetByIdAsync(targetUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = targetUserId, Email = "member@example.com" });

        var updated = await CreateService().UpdateMemberRoleAsync(ownerId, targetMemberId, FamilyMemberRole.Viewer);

        Assert.Equal("Viewer", updated.Role);
        _repo.Verify(r => r.UpdateMemberAsync(
            It.Is<FamilyMember>(m => m.Id == targetMemberId && m.Role == FamilyMemberRole.Viewer),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateMemberRoleAsync_CannotChangeOwnerRole()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var ownerMemberId = Guid.NewGuid();
        SetupOwner(ownerId, familySpaceId, ownerMemberId);
        _repo.Setup(r => r.ListMembersAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyMember { Id = ownerMemberId, UserId = ownerId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Owner }
            ]);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().UpdateMemberRoleAsync(ownerId, ownerMemberId, FamilyMemberRole.Viewer));

        Assert.Equal("Owner role changes require ownership transfer.", error.Message);
        _repo.Verify(r => r.UpdateMemberAsync(It.IsAny<FamilyMember>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task RemoveMemberAsync_OwnerRemovesContributor()
    {
        var ownerId = Guid.NewGuid();
        var targetUserId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var targetMemberId = Guid.NewGuid();
        SetupOwner(ownerId, familySpaceId);
        _repo.Setup(r => r.ListMembersAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyMember { Id = Guid.NewGuid(), UserId = ownerId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Owner },
                new FamilyMember { Id = targetMemberId, UserId = targetUserId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Contributor }
            ]);

        await CreateService().RemoveMemberAsync(ownerId, targetMemberId);

        _repo.Verify(r => r.DeleteMemberAsync(targetMemberId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RemoveMemberAsync_CannotRemoveOwner()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var ownerMemberId = Guid.NewGuid();
        SetupOwner(ownerId, familySpaceId, ownerMemberId);
        _repo.Setup(r => r.ListMembersAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyMember { Id = ownerMemberId, UserId = ownerId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Owner }
            ]);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().RemoveMemberAsync(ownerId, ownerMemberId));

        Assert.Equal("Owners must transfer ownership before leaving or being removed.", error.Message);
        _repo.Verify(r => r.DeleteMemberAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task LeaveAsync_ContributorDeletesOwnMembership()
    {
        var userId = Guid.NewGuid();
        var memberId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                Id = memberId,
                UserId = userId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });

        await CreateService().LeaveAsync(userId);

        _repo.Verify(r => r.DeleteMemberAsync(memberId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task LeaveAsync_OwnerCannotLeaveWithoutTransfer()
    {
        var ownerId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var ownerMemberId = Guid.NewGuid();
        SetupOwner(ownerId, familySpaceId, ownerMemberId);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().LeaveAsync(ownerId));

        Assert.Equal("Owners must transfer ownership before leaving or being removed.", error.Message);
        _repo.Verify(r => r.DeleteMemberAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task GetOverviewAsync_MemberReceivesSharedBudgetsActivityAndRecurringItems()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });
        _budgets.Setup(r => r.ListByFamilySpaceAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Budget
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.NewGuid(),
                    Category = "Dining",
                    MonthlyLimit = 4000m,
                    CurrencyCode = "PHP",
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _transactions.Setup(r => r.GetByFamilySpaceAndDateRangeAsync(
                familySpaceId,
                It.IsAny<DateTime>(),
                It.IsAny<DateTime>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.NewGuid(),
                    Type = TransactionType.Expense,
                    Amount = new Money(280m, "PHP"),
                    Category = "Dining",
                    Counterparty = "Starbucks",
                    Date = now.AddDays(-1),
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                },
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.NewGuid(),
                    Type = TransactionType.Income,
                    Amount = new Money(15000m, "PHP"),
                    Category = "Contribution",
                    Counterparty = "Freelance Client",
                    Date = now.AddDays(-2),
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _recurringSchedules.Setup(r => r.ListByFamilySpaceAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new RecurringSchedule
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.NewGuid(),
                    Type = TransactionType.Expense,
                    Amount = new Money(2499m, "PHP"),
                    Category = "Bills",
                    Counterparty = "Home internet",
                    StartDate = now.AddMonths(-1),
                    Cadence = RecurringCadence.Monthly,
                    NextRunAt = now.AddDays(5),
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);

        var overview = await CreateService().GetOverviewAsync(userId);

        Assert.Equal(familySpaceId, overview.FamilySpaceId);
        var budget = Assert.Single(overview.Budgets);
        Assert.Equal("Dining", budget.Category);
        Assert.Equal(4000m, budget.MonthlyLimit);
        Assert.Equal(280m, budget.SpentThisMonth);
        Assert.Equal(7, budget.UsagePercent);
        Assert.Equal(2, overview.RecentActivity.Count);
        Assert.Equal("Starbucks", overview.RecentActivity[0].Label);
        Assert.Equal("Home internet", Assert.Single(overview.RecurringItems).Label);
    }

    [Fact]
    public async Task GetOverviewAsync_UserWithoutFamilyThrows()
    {
        var userId = Guid.NewGuid();
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            CreateService().GetOverviewAsync(userId));

        Assert.Equal("You do not belong to a Family Space.", error.Message);
    }

    private static bool PayloadHasEmail(string payload, string email)
    {
        using var document = JsonDocument.Parse(payload);
        return document.RootElement.GetProperty("email").GetString() == email;
    }

    private void SetupOwner(Guid ownerId, Guid familySpaceId, Guid? memberId = null)
    {
        _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                Id = memberId ?? Guid.NewGuid(),
                UserId = ownerId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Owner
            });
    }
}
