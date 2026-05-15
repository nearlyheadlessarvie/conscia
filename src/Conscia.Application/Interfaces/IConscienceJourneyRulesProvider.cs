using Conscia.Application.Constants;

namespace Conscia.Application.Interfaces;

public interface IConscienceJourneyRulesProvider
{
    IReadOnlyList<string> SupportedEventTypes { get; }
    IReadOnlyDictionary<string, int> XpByEventType { get; }
    IReadOnlyList<ConscienceLevelRule> Levels { get; }
    IReadOnlyList<ConscienceQuestRule> WeeklyQuests { get; }
    IReadOnlyList<ConscienceBadgeRule> Badges { get; }
    IReadOnlyList<ConscienceMascotMomentRule> MascotMoments { get; }
}
