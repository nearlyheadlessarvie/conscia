using Amazon.Lambda;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public class LambdaProxyFamilySpaceRepository : LambdaProxyRepository, IFamilySpaceRepository
{
    public LambdaProxyFamilySpaceRepository(IAmazonLambda lambda, string functionName)
        : base(lambda, functionName) { }

    public Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default) =>
        InvokeAsync<FamilySpace?>("FamilySpace.GetById", new { FamilySpaceId = familySpaceId }, ct);

    public Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default) =>
        InvokeAsync<FamilyMember?>("FamilySpace.GetMembershipByUserId", new { UserId = userId }, ct);

    public Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default) =>
        InvokeAsync<IReadOnlyList<FamilyMember>>("FamilySpace.ListMembers", new { FamilySpaceId = familySpaceId }, ct);

    public Task<FamilySpace> CreateWithOwnerAsync(FamilySpace space, FamilyMember owner, CancellationToken ct = default) =>
        InvokeAsync<FamilySpace>("FamilySpace.CreateWithOwner", new { Space = space, Owner = owner }, ct);

    public Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default) =>
        InvokeAsync<FamilyInvite>("FamilySpace.AddInvite", invite, ct);

    public Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default) =>
        InvokeAsync<FamilyInvite?>("FamilySpace.GetInvite", new { InviteId = inviteId }, ct);

    public Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default) =>
        InvokeAsync<FamilyInvite?>("FamilySpace.GetActiveInviteByEmail", new { Email = normalizedEmail }, ct);

    public Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default) =>
        InvokeAsync<FamilyMember>("FamilySpace.AddMember", member, ct);

    public async Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default) =>
        await InvokeAsync<object>("FamilySpace.UpdateInvite", invite, ct);

    public async Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default) =>
        await InvokeAsync<object>("FamilySpace.UpdateMember", member, ct);

    public async Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default) =>
        await InvokeAsync<object>("FamilySpace.DeleteMember", new { MemberId = memberId }, ct);
}
