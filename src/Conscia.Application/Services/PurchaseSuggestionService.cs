using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Application.Services;

public class PurchaseSuggestionService : IPurchaseSuggestionService
{
    private readonly ITransactionRepository _repo;

    public PurchaseSuggestionService(ITransactionRepository repo)
    {
        _repo = repo;
    }

    public async Task<IReadOnlyList<PurchaseSuggestionDto>> GetSuggestionsAsync(
        Guid userId, CancellationToken ct = default)
    {
        var cutoff = DateTime.UtcNow.AddDays(-90);
        var transactions = await _repo.GetByUserIdAndDateRangeAsync(
            userId, cutoff, DateTime.UtcNow, ct);

        if (transactions.Count < 10)
            return Array.Empty<PurchaseSuggestionDto>();

        var now = DateTime.UtcNow;

        return transactions
            .Where(t => !string.IsNullOrWhiteSpace(t.Merchant))
            .GroupBy(t => t.Merchant!.Trim().ToLowerInvariant())
            .Where(g => g.Count() >= 2)
            .Select(g =>
            {
                var items = g.ToList();
                var mostRecent = items.Max(t => t.Date);
                var daysSince = (now - mostRecent).TotalDays;
                var recencyWeight = Math.Max(0.1, 1.0 - daysSince / 90.0 * 0.9);
                var score = items.Count * recencyWeight;

                var amounts = items.Select(t => t.Amount.Amount).OrderBy(a => a).ToList();
                var median = amounts.Count % 2 == 0
                    ? (amounts[amounts.Count / 2 - 1] + amounts[amounts.Count / 2]) / 2
                    : amounts[amounts.Count / 2];

                var withinWeek = items.Any(t => (now - t.Date).TotalDays <= 7);
                var label = withinWeek
                    ? $"{items.Count}× this week"
                    : $"{items.Count}× this month";

                var topCategory = items
                    .GroupBy(t => t.Category)
                    .OrderByDescending(cg => cg.Count())
                    .First().Key;

                return new
                {
                    Score = score,
                    Dto = new PurchaseSuggestionDto(
                        items.First().Merchant!.Trim(),
                        median,
                        items.First().Amount.CurrencyCode,
                        topCategory,
                        label)
                };
            })
            .OrderByDescending(x => x.Score)
            .Take(5)
            .Select(x => x.Dto)
            .ToList();
    }
}
