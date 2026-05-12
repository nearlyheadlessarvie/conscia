using Amazon.Lambda;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public class LambdaProxyCategoryRepository : LambdaProxyRepository, ICategoryRepository
{
    public LambdaProxyCategoryRepository(IAmazonLambda lambda, string functionName)
        : base(lambda, functionName) { }

    public Task<ManagedCategory?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        InvokeAsync<ManagedCategory?>("Category.GetById", new { Id = id }, ct);

    public Task<ManagedCategory?> GetByNormalizedNameAsync(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName,
        CancellationToken ct = default) =>
        InvokeAsync<ManagedCategory?>(
            "Category.GetByNormalizedName",
            new { UserId = userId, FamilySpaceId = familySpaceId, Scope = scope, Type = type, NormalizedName = normalizedName },
            ct);

    public Task<IReadOnlyList<ManagedCategory>> ListPersonalAsync(Guid userId, CancellationToken ct = default) =>
        InvokeAsync<IReadOnlyList<ManagedCategory>>("Category.ListPersonal", new { UserId = userId }, ct);

    public Task<IReadOnlyList<ManagedCategory>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default) =>
        InvokeAsync<IReadOnlyList<ManagedCategory>>("Category.ListByFamilySpace", new { FamilySpaceId = familySpaceId }, ct);

    public Task<ManagedCategory> AddAsync(ManagedCategory category, CancellationToken ct = default) =>
        InvokeAsync<ManagedCategory>("Category.Add", category, ct);

    public Task<ManagedCategory> UpdateAsync(ManagedCategory category, CancellationToken ct = default) =>
        InvokeAsync<ManagedCategory>("Category.Update", category, ct);
}
