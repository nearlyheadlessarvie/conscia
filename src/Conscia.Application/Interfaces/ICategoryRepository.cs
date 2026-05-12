using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ICategoryRepository
{
    Task<ManagedCategory?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<ManagedCategory?> GetByNormalizedNameAsync(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName,
        CancellationToken ct = default);
    Task<IReadOnlyList<ManagedCategory>> ListPersonalAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<ManagedCategory>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default);
    Task<ManagedCategory> AddAsync(ManagedCategory category, CancellationToken ct = default);
    Task<ManagedCategory> UpdateAsync(ManagedCategory category, CancellationToken ct = default);
}
