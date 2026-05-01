namespace Conscia.Application.Interfaces;

public interface ISessionCacheRepository
{
    Task SetAsync(string key, string value, TimeSpan? ttl = null, CancellationToken ct = default);
    Task<string?> GetAsync(string key, CancellationToken ct = default);
}
