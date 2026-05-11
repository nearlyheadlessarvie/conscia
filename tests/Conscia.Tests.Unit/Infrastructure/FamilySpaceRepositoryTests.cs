using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tests.Unit.Infrastructure;

public class FamilySpaceRepositoryTests : EfCoreTestBase
{
    private readonly FamilySpaceRepository _repo;

    public FamilySpaceRepositoryTests() => _repo = new FamilySpaceRepository(Db);

    [Fact]
    public async Task CreateWithOwnerAsync_CreatesSpaceAndMembership()
    {
        var userId = Guid.NewGuid();
        var space = new FamilySpace
        {
            Id = Guid.NewGuid(),
            Name = "Santos Household",
            CurrencyCode = "PHP",
            CreatedByUserId = userId
        };
        var owner = new FamilyMember
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = space.Id,
            UserId = userId,
            Role = FamilyMemberRole.Owner
        };

        var result = await _repo.CreateWithOwnerAsync(space, owner);

        Assert.Equal(space.Id, result.Id);
        Assert.NotNull(await _repo.GetByIdAsync(space.Id));

        var membership = await _repo.GetMembershipByUserIdAsync(userId);
        Assert.NotNull(membership);
        Assert.Equal(FamilyMemberRole.Owner, membership!.Role);
    }

    [Fact]
    public async Task ListMembersAsync_ReturnsOnlyFamilyMembersInJoinOrder()
    {
        var familySpaceId = Guid.NewGuid();
        var otherFamilySpaceId = Guid.NewGuid();

        await _repo.CreateWithOwnerAsync(
            new FamilySpace { Id = familySpaceId, Name = "Santos Household", CurrencyCode = "PHP", CreatedByUserId = Guid.NewGuid() },
            new FamilyMember { Id = Guid.NewGuid(), FamilySpaceId = familySpaceId, UserId = Guid.NewGuid(), Role = FamilyMemberRole.Owner, JoinedAt = new DateTime(2026, 5, 1) });
        await _repo.AddMemberAsync(new FamilyMember { Id = Guid.NewGuid(), FamilySpaceId = familySpaceId, UserId = Guid.NewGuid(), Role = FamilyMemberRole.Contributor, JoinedAt = new DateTime(2026, 5, 2) });
        await _repo.CreateWithOwnerAsync(
            new FamilySpace { Id = otherFamilySpaceId, Name = "Other Household", CurrencyCode = "PHP", CreatedByUserId = Guid.NewGuid() },
            new FamilyMember { Id = Guid.NewGuid(), FamilySpaceId = otherFamilySpaceId, UserId = Guid.NewGuid(), Role = FamilyMemberRole.Owner, JoinedAt = new DateTime(2026, 5, 3) });

        var members = await _repo.ListMembersAsync(familySpaceId);

        Assert.Equal(2, members.Count);
        Assert.All(members, member => Assert.Equal(familySpaceId, member.FamilySpaceId));
        Assert.Equal(FamilyMemberRole.Owner, members[0].Role);
        Assert.Equal(FamilyMemberRole.Contributor, members[1].Role);
    }

    [Fact]
    public async Task GetActiveInviteByEmailAsync_ReturnsLatestUnexpiredInvite()
    {
        var email = "wife@example.com";
        await _repo.AddInviteAsync(new FamilyInvite
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = Guid.NewGuid(),
            Email = email,
            Role = FamilyMemberRole.Contributor,
            InvitedByUserId = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow.AddDays(-2),
            ExpiresAt = DateTime.UtcNow.AddDays(5)
        });
        var latest = await _repo.AddInviteAsync(new FamilyInvite
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = Guid.NewGuid(),
            Email = email,
            Role = FamilyMemberRole.Viewer,
            InvitedByUserId = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow.AddDays(-1),
            ExpiresAt = DateTime.UtcNow.AddDays(6)
        });

        var result = await _repo.GetActiveInviteByEmailAsync(email);

        Assert.NotNull(result);
        Assert.Equal(latest.Id, result!.Id);
        Assert.Equal(FamilyMemberRole.Viewer, result.Role);
    }
}
