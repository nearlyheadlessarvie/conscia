using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IConscienceJourneyRepository
{
    Task<ConscienceJourneyProgress?> GetProgressAsync(Guid userId, CancellationToken ct = default);
    Task UpsertProgressAsync(ConscienceJourneyProgress progress, CancellationToken ct = default);
    Task<bool> TryInsertEventAsync(ConscienceJourneyEventRecord record, CancellationToken ct = default);
    Task<IReadOnlyList<ConscienceJourneyEventRecord>> ListEventsAsync(Guid userId, int limit = 1000, CancellationToken ct = default);
    Task<IReadOnlyList<ConscienceBadgeProgress>> GetBadgeProgressAsync(Guid userId, CancellationToken ct = default);
    Task UpsertBadgeProgressAsync(ConscienceBadgeProgress progress, CancellationToken ct = default);
    Task<IReadOnlyList<ConscienceQuestProgress>> GetQuestProgressAsync(Guid userId, DateOnly weekStart, CancellationToken ct = default);
    Task<IReadOnlyList<ConscienceQuestProgress>> ListQuestProgressAsync(Guid userId, int limit = 1000, CancellationToken ct = default);
    Task UpsertQuestProgressAsync(ConscienceQuestProgress progress, CancellationToken ct = default);
    Task<ConscienceMascotMoment?> GetRecentMascotMomentAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<ConscienceMascotMoment>> ListMascotMomentsAsync(Guid userId, int limit = 100, CancellationToken ct = default);
    Task AddMascotMomentAsync(ConscienceMascotMoment moment, CancellationToken ct = default);
}
