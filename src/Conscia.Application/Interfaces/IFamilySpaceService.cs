using Conscia.Application.DTOs;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceService
{
    Task<FamilySpace> CreateAsync(Guid userId, string name, string currencyCode, CancellationToken ct = default);
    Task<FamilySpaceDto> UpdateAsync(Guid userId, string name, CancellationToken ct = default);
    Task<FamilySpaceDto?> GetCurrentAsync(Guid userId, CancellationToken ct = default);
    Task<FamilySpaceOverviewDto> GetOverviewAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyMemberDto>> GetMembersAsync(Guid userId, CancellationToken ct = default);
    Task<FamilyInvite> InviteAsync(Guid inviterUserId, string email, FamilyMemberRole role, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyInviteDto>> GetPendingInvitesAsync(string email, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyInviteDto>> GetOutgoingInvitesAsync(Guid userId, CancellationToken ct = default);
    Task<FamilyMember> AcceptInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
    Task DeclineInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
    Task CancelInviteAsync(Guid userId, Guid inviteId, CancellationToken ct = default);
    Task<FamilyMemberDto> UpdateMemberRoleAsync(Guid userId, Guid memberId, FamilyMemberRole role, CancellationToken ct = default);
    Task<FamilyMemberDto> TransferOwnershipAsync(Guid userId, Guid memberId, CancellationToken ct = default);
    Task RemoveMemberAsync(Guid userId, Guid memberId, CancellationToken ct = default);
    Task LeaveAsync(Guid userId, CancellationToken ct = default);
}
