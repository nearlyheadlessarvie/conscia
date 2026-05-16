using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IUserSubscriptionRepository
{
    Task<UserSubscription?> GetLatestByUserAsync(Guid userId, CancellationToken ct = default);
    Task<UserSubscription?> GetByOriginalTransactionIdAsync(string originalTransactionId, CancellationToken ct = default);
    Task<UserSubscription> AddAsync(UserSubscription subscription, CancellationToken ct = default);
    Task<UserSubscription> UpdateAsync(UserSubscription subscription, CancellationToken ct = default);
}
