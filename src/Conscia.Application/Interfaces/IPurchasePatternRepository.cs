using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IPurchasePatternRepository
{
    Task<PurchasePatternSummary?> GetSummaryAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<CategoryPattern>> GetCategoriesAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<MerchantPattern>> GetMerchantsAsync(Guid userId, CancellationToken ct = default);
    Task UpsertManyAsync(Guid userId, PurchasePatternSummary summary, IEnumerable<CategoryPattern> categories, IEnumerable<MerchantPattern> merchants, CancellationToken ct = default);
}
