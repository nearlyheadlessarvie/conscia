using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class FamilySpaceService : IFamilySpaceService
{
    private readonly IFamilySpaceRepository _repository;
    private readonly ISubscriptionService _subscriptions;
    private readonly ILogger<FamilySpaceService> _logger;

    public FamilySpaceService(
        IFamilySpaceRepository repository,
        ISubscriptionService subscriptions,
        ILogger<FamilySpaceService> logger)
    {
        _repository = repository;
        _subscriptions = subscriptions;
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
}
