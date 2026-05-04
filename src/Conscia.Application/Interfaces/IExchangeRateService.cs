namespace Conscia.Application.Interfaces;

public interface IExchangeRateService
{
    /// <summary>
    /// Returns the exchange rate to convert <paramref name="fromCode"/> → <paramref name="toCode"/>.
    /// Returns null if the pair is unavailable (API down or unsupported code).
    /// </summary>
    Task<decimal?> GetRateAsync(string fromCode, string toCode, CancellationToken ct);
}
