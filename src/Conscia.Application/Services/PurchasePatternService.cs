using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using System.Linq;

namespace Conscia.Application.Services;

public class PurchasePatternService : IPurchasePatternService
{
    private readonly IPurchasePatternRepository _repo;
    private readonly ITransactionRepository _txRepo;

    public PurchasePatternService(IPurchasePatternRepository repo, ITransactionRepository txRepo)
    {
        _repo = repo;
        _txRepo = txRepo;
    }

    public async Task<InsightsSummaryDto?> GetSummaryAsync(Guid userId, CancellationToken ct = default)
    {
        var summary = await _repo.GetSummaryAsync(userId, ct);
        if (summary is null) return null;

        return new InsightsSummaryDto(
            summary.RegrettedAmount,
            summary.RegrettedCategory,
            summary.AvgRegretRate,
            summary.PatternCount,
            summary.UpdatedAt
        );
    }

    public async Task<IReadOnlyList<CategoryStatDto>> GetCategoriesAsync(Guid userId, CancellationToken ct = default)
    {
        var categories = await _repo.GetCategoriesAsync(userId, ct);
        return categories
            .OrderByDescending(c => c.RegretRate)
            .Select(c => new CategoryStatDto(c.Category, c.TotalSpend, c.RegrettedSpend,
                c.RegretRate, c.TransactionCount, c.ProjectedAnnual))
            .ToList();
    }

    public async Task<IReadOnlyList<MerchantStatDto>> GetMerchantsAsync(Guid userId, CancellationToken ct = default)
    {
        var merchants = await _repo.GetMerchantsAsync(userId, ct);
        return merchants
            .OrderByDescending(m => m.RegretRate)
            .Select(m => new MerchantStatDto(m.Merchant, m.VisitCount, m.RegretCount,
                m.RegretRate, m.LastVisitDate))
            .ToList();
    }

    public async Task<CategoryDetailDto?> GetCategoryDetailAsync(Guid userId, string category, CancellationToken ct = default)
    {
        var categories = await _repo.GetCategoriesAsync(userId, ct);
        var match = categories.FirstOrDefault(c =>
            string.Equals(c.Category, category, StringComparison.OrdinalIgnoreCase));

        if (match is null) return null;

        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);
        var transactions = await _txRepo.GetByUserIdAndDateRangeAsync(userId, from, to, ct);

        var recent = transactions
            .Where(t => string.Equals(t.Category, category, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(t => t.Date)
            .Take(10)
            .Select(t => new TransactionSummaryDto(t.Id, t.Amount.Amount, t.Amount.CurrencyCode,
                t.Category, t.Counterparty, t.Date, t.RegretLevel?.ToString()))
            .ToList();

        var stats = new CategoryStatDto(match.Category, match.TotalSpend, match.RegrettedSpend,
            match.RegretRate, match.TransactionCount, match.ProjectedAnnual);

        return new CategoryDetailDto(stats, recent);
    }

    public async Task<MerchantDetailDto?> GetMerchantDetailAsync(Guid userId, string merchant, CancellationToken ct = default)
    {
        var merchants = await _repo.GetMerchantsAsync(userId, ct);
        var match = merchants.FirstOrDefault(m =>
            string.Equals(m.Merchant, merchant, StringComparison.OrdinalIgnoreCase));

        if (match is null) return null;

        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);
        var transactions = await _txRepo.GetByUserIdAndDateRangeAsync(userId, from, to, ct);

        var recent = transactions
            .Where(t => string.Equals(t.Counterparty, merchant, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(t => t.Date)
            .Take(10)
            .Select(t => new TransactionSummaryDto(t.Id, t.Amount.Amount, t.Amount.CurrencyCode,
                t.Category, t.Counterparty, t.Date, t.RegretLevel?.ToString()))
            .ToList();

        var stats = new MerchantStatDto(match.Merchant, match.VisitCount, match.RegretCount,
            match.RegretRate, match.LastVisitDate);

        return new MerchantDetailDto(stats, recent);
    }
}
