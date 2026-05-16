using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Tests.Unit.Infrastructure;

public sealed class InMemoryUserRepository : IUserRepository
{
    private readonly Dictionary<Guid, User> _users = [];
    private readonly List<UserIdentity> _identities = [];

    public IReadOnlyCollection<User> Users => _users.Values;
    public IReadOnlyCollection<UserIdentity> Identities => _identities;

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        Task.FromResult(_users.GetValueOrDefault(id));

    public Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default)
    {
        var identity = _identities.FirstOrDefault(i =>
            i.Provider == provider &&
            string.Equals(i.ProviderSub, providerSub, StringComparison.OrdinalIgnoreCase));

        return Task.FromResult(identity is null ? null : _users.GetValueOrDefault(identity.UserId));
    }

    public Task<User?> GetByEmailAsync(string email, CancellationToken ct = default)
    {
        var normalized = email.Trim().ToLowerInvariant();
        return Task.FromResult(_users.Values.FirstOrDefault(u =>
            string.Equals(u.Email, normalized, StringComparison.OrdinalIgnoreCase)));
    }

    public Task<User> AddAsync(User user, CancellationToken ct = default)
    {
        _users[user.Id] = user;
        return Task.FromResult(user);
    }

    public Task<User> UpdateAsync(User user, CancellationToken ct = default)
    {
        _users[user.Id] = user;
        return Task.FromResult(user);
    }

    public Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        _users.Remove(id);
        _identities.RemoveAll(i => i.UserId == id);
        return Task.CompletedTask;
    }

    public Task<UserIdentity> AddIdentityAsync(UserIdentity identity, CancellationToken ct = default)
    {
        _identities.RemoveAll(i =>
            i.Provider == identity.Provider &&
            string.Equals(i.ProviderSub, identity.ProviderSub, StringComparison.OrdinalIgnoreCase));
        _identities.Add(identity);
        return Task.FromResult(identity);
    }
}
