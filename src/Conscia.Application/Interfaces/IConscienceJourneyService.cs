using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IConscienceJourneyService
{
    Task<ConscienceJourneySummaryDto> GetJourneyAsync(Guid userId, CancellationToken ct = default);
    Task<ConscienceJourneyUpdateDto> RecordEventAsync(
        Guid userId,
        string eventType,
        string sourceId,
        CancellationToken ct = default);
}
