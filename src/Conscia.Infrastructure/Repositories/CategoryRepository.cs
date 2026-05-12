using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class CategoryRepository : ICategoryRepository
{
    private readonly ConsciaDbContext _db;

    public CategoryRepository(ConsciaDbContext db) => _db = db;

    public async Task<ManagedCategory?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _db.ManagedCategories.FindAsync([id], ct);

    public async Task<ManagedCategory?> GetByNormalizedNameAsync(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName,
        CancellationToken ct = default)
    {
        var query = _db.ManagedCategories.Where(c =>
            c.Scope == scope &&
            c.Type == type &&
            c.NormalizedName == normalizedName);

        query = scope == RecordScope.Family
            ? query.Where(c => c.FamilySpaceId == familySpaceId)
            : query.Where(c => c.UserId == userId && c.FamilySpaceId == null);

        return await query.FirstOrDefaultAsync(ct);
    }

    public async Task<IReadOnlyList<ManagedCategory>> ListPersonalAsync(Guid userId, CancellationToken ct = default) =>
        await _db.ManagedCategories
            .Where(c => c.Scope == RecordScope.Personal && c.UserId == userId)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<ManagedCategory>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default) =>
        await _db.ManagedCategories
            .Where(c => c.Scope == RecordScope.Family && c.FamilySpaceId == familySpaceId)
            .ToListAsync(ct);

    public async Task<ManagedCategory> AddAsync(ManagedCategory category, CancellationToken ct = default)
    {
        _db.ManagedCategories.Add(category);
        await _db.SaveChangesAsync(ct);
        return category;
    }

    public async Task<ManagedCategory> UpdateAsync(ManagedCategory category, CancellationToken ct = default)
    {
        _db.ManagedCategories.Update(category);
        await _db.SaveChangesAsync(ct);
        return category;
    }
}
