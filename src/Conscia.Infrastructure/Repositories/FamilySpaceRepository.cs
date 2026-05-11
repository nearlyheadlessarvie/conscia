using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class FamilySpaceRepository : IFamilySpaceRepository
{
    private readonly ConsciaDbContext _db;

    public FamilySpaceRepository(ConsciaDbContext db) => _db = db;

    public Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default) =>
        _db.FamilySpaces.FirstOrDefaultAsync(x => x.Id == familySpaceId, ct);

    public Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default) =>
        _db.FamilyMembers.FirstOrDefaultAsync(x => x.UserId == userId, ct);

    public async Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default) =>
        await _db.FamilyMembers
            .Where(x => x.FamilySpaceId == familySpaceId)
            .OrderBy(x => x.JoinedAt)
            .ToListAsync(ct);

    public async Task<FamilySpace> CreateWithOwnerAsync(
        FamilySpace space,
        FamilyMember owner,
        CancellationToken ct = default)
    {
        await _db.FamilySpaces.AddAsync(space, ct);
        await _db.FamilyMembers.AddAsync(owner, ct);
        await _db.SaveChangesAsync(ct);
        return space;
    }

    public async Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        invite.Email = NormalizeEmail(invite.Email);
        await _db.FamilyInvites.AddAsync(invite, ct);
        await _db.SaveChangesAsync(ct);
        return invite;
    }

    public Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default) =>
        _db.FamilyInvites.FirstOrDefaultAsync(x => x.Id == inviteId, ct);

    public Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default)
    {
        var email = NormalizeEmail(normalizedEmail);
        var now = DateTime.UtcNow;

        return _db.FamilyInvites
            .Where(x => x.Email == email
                && x.AcceptedAt == null
                && x.DeclinedAt == null
                && x.ExpiresAt > now)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(ct);
    }

    public async Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default)
    {
        await _db.FamilyMembers.AddAsync(member, ct);
        await _db.SaveChangesAsync(ct);
        return member;
    }

    public async Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        invite.Email = NormalizeEmail(invite.Email);
        _db.FamilyInvites.Update(invite);
        await _db.SaveChangesAsync(ct);
    }

    public async Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default)
    {
        _db.FamilyMembers.Update(member);
        await _db.SaveChangesAsync(ct);
    }

    public async Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default)
    {
        var member = await _db.FamilyMembers.FirstOrDefaultAsync(x => x.Id == memberId, ct);
        if (member is null)
            return;

        _db.FamilyMembers.Remove(member);
        await _db.SaveChangesAsync(ct);
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
