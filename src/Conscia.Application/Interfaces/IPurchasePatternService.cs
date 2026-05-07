using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IPurchasePatternService
{
    Task<InsightsSummaryDto?> GetSummaryAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<CategoryStatDto>> GetCategoriesAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<MerchantStatDto>> GetMerchantsAsync(Guid userId, CancellationToken ct = default);
    Task<CategoryDetailDto?> GetCategoryDetailAsync(Guid userId, string category, CancellationToken ct = default);
    Task<MerchantDetailDto?> GetMerchantDetailAsync(Guid userId, string merchant, CancellationToken ct = default);
}
