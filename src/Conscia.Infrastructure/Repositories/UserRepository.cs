using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly ConsciaDbContext _db;

    public UserRepository(ConsciaDbContext db) => _db = db;

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _db.Users.FindAsync([id], ct);

    public async Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default) =>
        await _db.Users.FirstOrDefaultAsync(
            u => _db.UserIdentities.Any(i => i.UserId == u.Id && i.Provider == provider && i.ProviderSub == providerSub),
            ct);

    public async Task<User?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        await _db.Users.FirstOrDefaultAsync(u => u.Email == email, ct);

    public async Task<User> AddAsync(User user, CancellationToken ct = default)
    {
        _db.Users.Add(user);
        await _db.SaveChangesAsync(ct);
        return user;
    }

    public async Task<User> UpdateAsync(User user, CancellationToken ct = default)
    {
        _db.Users.Update(user);
        await _db.SaveChangesAsync(ct);
        return user;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var user = await _db.Users.FindAsync([id], ct);
        if (user is not null)
        {
            _db.Users.Remove(user);
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task<UserIdentity> AddIdentityAsync(UserIdentity identity, CancellationToken ct = default)
    {
        _db.UserIdentities.Add(identity);
        await _db.SaveChangesAsync(ct);
        return identity;
    }
}
