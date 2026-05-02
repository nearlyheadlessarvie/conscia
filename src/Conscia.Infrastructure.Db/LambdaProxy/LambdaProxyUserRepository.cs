using Amazon.Lambda;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public class LambdaProxyUserRepository : LambdaProxyRepository, IUserRepository
{
    public LambdaProxyUserRepository(IAmazonLambda lambda, string functionName)
        : base(lambda, functionName) { }

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        InvokeAsync<User?>("User.GetById", new { Id = id }, ct);

    public Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default) =>
        InvokeAsync<User?>("User.GetByProvider", new { Provider = provider.ToString(), ProviderSub = providerSub }, ct);

    public Task<User?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        InvokeAsync<User?>("User.GetByEmail", new { Email = email }, ct);

    public Task<User> AddAsync(User user, CancellationToken ct = default) =>
        InvokeAsync<User>("User.Add", user, ct);

    public Task<User> UpdateAsync(User user, CancellationToken ct = default) =>
        InvokeAsync<User>("User.Update", user, ct);

    public async Task DeleteAsync(Guid id, CancellationToken ct = default) =>
        await InvokeAsync<object>("User.Delete", new { Id = id }, ct);

    public Task<UserIdentity> AddIdentityAsync(UserIdentity identity, CancellationToken ct = default) =>
        InvokeAsync<UserIdentity>("UserIdentity.Add", identity, ct);
}
