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

    private readonly IFamilySpaceRepository _repository;
    private readonly ISubscriptionService _subscriptions;
    private readonly IOutboxEventRepository _outboxEvents;
    private readonly ILogger<FamilySpaceService> _logger;

    public FamilySpaceService(
        IFamilySpaceRepository repository,
        ISubscriptionService subscriptions,
        IOutboxEventRepository outboxEvents,
        ILogger<FamilySpaceService> logger)
    {
        _repository = repository;
        _subscriptions = subscriptions;
        _outboxEvents = outboxEvents;
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
        await _outboxEvents.AddAsync(CreateInviteCreatedEvent(result), ct);
        return result;
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

    private static OutboxEvent CreateInviteCreatedEvent(FamilyInvite invite) => new()
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
