using System.Text.Json;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Caching.Memory;

namespace Conscia.Infrastructure.Services;

public class ExchangeRateService : IExchangeRateService
{
    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(24);

    public ExchangeRateService(HttpClient http, IMemoryCache cache)
    {
        _http = http;
        _cache = cache;
    }

    public async Task<decimal?> GetRateAsync(string fromCode, string toCode, CancellationToken ct)
    {
        if (string.Equals(fromCode, toCode, StringComparison.OrdinalIgnoreCase))
            return 1m;

        var cacheKey = $"fx:{fromCode.ToUpper()}";

        if (!_cache.TryGetValue(cacheKey, out Dictionary<string, decimal>? rates))
        {
            rates = await FetchRatesAsync(fromCode, ct);
            if (rates is not null)
                _cache.Set(cacheKey, rates, CacheTtl);
        }

        if (rates is null) return null;
        return rates.TryGetValue(toCode.ToUpper(), out var rate) ? rate : null;
    }

    private async Task<Dictionary<string, decimal>?> FetchRatesAsync(string fromCode, CancellationToken ct)
    {
        try
        {
            var response = await _http.GetAsync($"/v6/latest/{fromCode.ToUpper()}", ct);
            if (!response.IsSuccessStatusCode) return null;

            using var doc = await JsonDocument.ParseAsync(
                await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);

            if (!doc.RootElement.TryGetProperty("rates", out var ratesEl)) return null;

            var dict = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            foreach (var prop in ratesEl.EnumerateObject())
            {
                if (prop.Value.TryGetDecimal(out var val))
                    dict[prop.Name] = val;
            }
            return dict;
        }
        catch
        {
            return null;
        }
    }
}
