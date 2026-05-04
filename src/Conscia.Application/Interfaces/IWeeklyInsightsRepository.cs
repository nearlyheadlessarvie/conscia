using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IWeeklyInsightsRepository
{
    Task<WeeklyInsights?> GetLatestByUserIdAsync(Guid userId, CancellationToken ct = default);
    Task<WeeklyInsights?> GetByUserIdAndWeekAsync(Guid userId, DateTime weekStartDate, CancellationToken ct = default);
    Task UpsertAsync(WeeklyInsights insights, CancellationToken ct = default);
    Task<List<WeeklyInsights>> GetByUserIdAsync(Guid userId, int limit = 10, CancellationToken ct = default);
}