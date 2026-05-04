using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IBehavioralInsightsService
{
    Task<BehavioralInsights?> GetBehavioralInsightsAsync(Guid userId, CancellationToken ct = default);
    Task CalculateAndStoreWeeklyInsightsAsync(Guid userId, DateTime weekStartDate, CancellationToken ct = default);
}