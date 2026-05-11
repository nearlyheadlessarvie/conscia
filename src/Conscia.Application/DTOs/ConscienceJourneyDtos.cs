namespace Conscia.Application.DTOs;

public record ConscienceJourneySummaryDto(
    int XpTotal,
    ConscienceLevelDto CurrentLevel,
    ConscienceLevelDto? NextLevel,
    int XpIntoLevel,
    int XpToNextLevel,
    int MomentumDays,
    int BestMomentumDays,
    IReadOnlyList<ConscienceQuestDto> WeeklyQuests,
    IReadOnlyList<ConscienceBadgeDto> Badges,
    ConscienceMascotMomentDto? RecentMascotMoment
);

public record ConscienceLevelDto(
    string Key,
    string Title,
    int RequiredXp
);

public record ConscienceQuestDto(
    string Key,
    string Title,
    string Description,
    int Progress,
    int Target,
    int XpReward,
    bool IsCompleted,
    DateTime? CompletedAt
);

public record ConscienceBadgeDto(
    string Key,
    string Title,
    string Description,
    int Progress,
    int Target,
    bool IsUnlocked,
    DateTime? UnlockedAt
);

public record ConscienceMascotMomentDto(
    string Key,
    string Persona,
    string Title,
    string Message,
    DateTime CreatedAt
);

public record RecordConscienceEventRequest(
    string EventType,
    string SourceId
);

public record ConscienceJourneyUpdateDto(
    ConscienceJourneySummaryDto Summary,
    int XpAwarded,
    bool WasDuplicate,
    bool LeveledUp,
    IReadOnlyList<string> CompletedQuestKeys,
    IReadOnlyList<string> UnlockedBadgeKeys,
    ConscienceMascotMomentDto? MascotMoment
);
