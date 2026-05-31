using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _repo;
    private readonly ITransactionRepository _transactions;
    private readonly IUserIdentityDeletionService _identityDeletion;
    private readonly IUserDataErasureService _dataErasure;

    public UserService(
        IUserRepository repo,
        ITransactionRepository transactions,
        IUserIdentityDeletionService identityDeletion,
        IUserDataErasureService dataErasure)
    {
        _repo = repo;
        _transactions = transactions;
        _identityDeletion = identityDeletion;
        _dataErasure = dataErasure;
    }

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _repo.GetByIdAsync(id, ct);

    public Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default) =>
        _repo.GetByProviderAsync(provider, providerSub, ct);

    public async Task<User> UpdateProfileAsync(Guid id, UserProfileUpdateDto dto, CancellationToken ct = default)
    {
        var user = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"User {id} not found");

        if (dto.PreferredCurrency is not null
            && !string.Equals(dto.PreferredCurrency, user.PreferredCurrency, StringComparison.OrdinalIgnoreCase))
        {
            var (transactions, _) = await _transactions.QueryByUserAsync(
                id,
                null,
                null,
                null,
                1,
                null,
                ct);

            if (transactions.Count > 0)
                throw new InvalidOperationException(
                    "Default currency is locked after your first transaction.");

            user.PreferredCurrency = dto.PreferredCurrency;
        }
        if (dto.ProfilePictureKey is not null &&
            !dto.ProfilePictureKey.StartsWith($"profile-pictures/{id}/", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Profile picture key must belong to the current user.");
        }

        if (dto.DisplayName is not null) user.DisplayName = dto.DisplayName.Trim();
        if (dto.ProfilePictureKey is not null) user.ProfilePictureKey = dto.ProfilePictureKey;
        if (dto.Locale is not null) user.Locale = dto.Locale;
        if (dto.SpendingPersonality is not null) user.SpendingPersonality = dto.SpendingPersonality;
        if (dto.IncomeRange is not null) user.IncomeRange = dto.IncomeRange;
        if (dto.OccupationType is not null) user.OccupationType = dto.OccupationType;
        if (dto.HouseholdSize is not null) user.HouseholdSize = dto.HouseholdSize;
        if (dto.HasCompletedOnboarding.HasValue) user.HasCompletedOnboarding = dto.HasCompletedOnboarding.Value;
        if (dto.AiPersonalityIntensity is not null) user.AiPersonalityIntensity = dto.AiPersonalityIntensity;

        return await _repo.UpdateAsync(user, ct);
    }

    public async Task DeleteAccountAsync(Guid id, CancellationToken ct = default)
    {
        var user = await _repo.GetByIdAsync(id, ct);
        if (user is null)
        {
            return;
        }

        await _identityDeletion.DeleteUserAsync(user, ct);
        await _dataErasure.EraseUserDataAsync(id, ct);
        await _repo.DeleteAsync(id, ct);
    }
}
