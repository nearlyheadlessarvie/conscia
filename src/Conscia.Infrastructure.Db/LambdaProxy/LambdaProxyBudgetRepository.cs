using Amazon.Lambda;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public class LambdaProxyBudgetRepository : LambdaProxyRepository, IBudgetRepository
{
    public LambdaProxyBudgetRepository(IAmazonLambda lambda, string functionName)
        : base(lambda, functionName) { }

    public Task<Budget?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        InvokeAsync<Budget?>("Budget.GetById", new { Id = id }, ct);

    public Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default) =>
        InvokeAsync<IReadOnlyList<Budget>>("Budget.ListByUser", new { UserId = userId }, ct);

    public Task<IReadOnlyList<Budget>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default) =>
        InvokeAsync<IReadOnlyList<Budget>>("Budget.ListByFamilySpace", new { FamilySpaceId = familySpaceId }, ct);

    public Task<Budget> AddAsync(Budget budget, CancellationToken ct = default) =>
        InvokeAsync<Budget>("Budget.Add", budget, ct);

    public Task<Budget> UpdateAsync(Budget budget, CancellationToken ct = default) =>
        InvokeAsync<Budget>("Budget.Update", budget, ct);

    public async Task DeleteAsync(Guid id, CancellationToken ct = default) =>
        await InvokeAsync<object>("Budget.Delete", new { Id = id }, ct);
}
