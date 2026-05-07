using Conscia.Application.DTOs;
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

    public async Task<User> UpdateProfileAsync(Guid id, UserProfileUpdateDto dto, CancellationToken ct = default)
    {
        var user = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"User {id} not found");

        if (dto.PreferredCurrency is not null) user.PreferredCurrency = dto.PreferredCurrency;
        if (dto.Locale is not null) user.Locale = dto.Locale;
        if (dto.SpendingPersonality is not null) user.SpendingPersonality = dto.SpendingPersonality;
        if (dto.IncomeRange is not null) user.IncomeRange = dto.IncomeRange;
        if (dto.OccupationType is not null) user.OccupationType = dto.OccupationType;
        if (dto.HouseholdSize is not null) user.HouseholdSize = dto.HouseholdSize;

        return await _repo.UpdateAsync(user, ct);
    }

    public async Task DeleteAccountAsync(Guid id, CancellationToken ct = default)
    {
        await _repo.DeleteAsync(id, ct);
    }
}
