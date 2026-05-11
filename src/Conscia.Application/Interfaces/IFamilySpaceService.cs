using Conscia.Application.DTOs;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceService
{
    Task<FamilySpace> CreateAsync(Guid userId, string name, string currencyCode, CancellationToken ct = default);
    Task<FamilySpaceDto?> GetCurrentAsync(Guid userId, CancellationToken ct = default);
    Task<FamilyInvite> InviteAsync(Guid inviterUserId, string email, FamilyMemberRole role, CancellationToken ct = default);
    Task<FamilyMember> AcceptInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
    Task DeclineInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
}
