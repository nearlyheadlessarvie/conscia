using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceRepository
{
    Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default);
    Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default);
    Task<FamilySpace> CreateWithOwnerAsync(FamilySpace space, FamilyMember owner, CancellationToken ct = default);
    Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default);
    Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default);
    Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyInvite>> ListActiveInvitesByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default);
    Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default);
    Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default);
    Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default);
}
