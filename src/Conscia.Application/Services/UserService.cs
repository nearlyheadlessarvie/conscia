using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _repo;

    public UserService(IUserRepository repo) => _repo = repo;

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _repo.GetByIdAsync(id, ct);

    public Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default) =>
        _repo.GetByProviderAsync(provider, providerSub, ct);

    public async Task<User> UpdateProfileAsync(Guid id, string? preferredCurrency, string? locale, CancellationToken ct = default)
    {
        var user = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"User {id} not found");

        if (preferredCurrency is not null)
            user.PreferredCurrency = preferredCurrency;
        if (locale is not null)
            user.Locale = locale;

        return await _repo.UpdateAsync(user, ct);
    }

    public async Task DeleteAccountAsync(Guid id, CancellationToken ct = default)
    {
        await _repo.DeleteAsync(id, ct);
    }
}
