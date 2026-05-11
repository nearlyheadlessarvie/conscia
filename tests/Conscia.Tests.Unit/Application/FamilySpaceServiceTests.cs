using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using System.Text.Json;

namespace Conscia.Tests.Unit.Application;

public class FamilySpaceServiceTests
{
    private readonly Mock<IFamilySpaceRepository> _repo = new();
    private readonly Mock<ISubscriptionService> _subscriptions = new();
    private readonly Mock<IOutboxEventRepository> _outboxEvents = new();

    private FamilySpaceService CreateService() =>
        new(_repo.Object, _subscriptions.Object, _outboxEvents.Object, NullLogger<FamilySpaceService>.Instance);

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

    private static bool PayloadHasEmail(string payload, string email)
    {
        using var document = JsonDocument.Parse(payload);
        return document.RootElement.GetProperty("email").GetString() == email;
    }
}
