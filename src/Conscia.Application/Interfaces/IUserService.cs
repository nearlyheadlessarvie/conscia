using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IUserService
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByCognitoSubAsync(string cognitoSub, CancellationToken ct = default);
    Task<User> UpdateProfileAsync(Guid id, string? preferredCurrency, string? locale, CancellationToken ct = default);
}
