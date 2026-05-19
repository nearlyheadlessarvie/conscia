using Conscia.Application.Interfaces;

namespace Conscia.Application.Constants;

public sealed class HardcodedJourneyRulesProvider : IConscienceJourneyRulesProvider
{
    public IReadOnlyList<string> SupportedEventTypes => ConscienceJourneyRules.SupportedEventTypes;
    public IReadOnlyDictionary<string, int> XpByEventType => ConscienceJourneyRules.XpByEventType;
    public IReadOnlyList<ConscienceLevelRule> Levels => ConscienceJourneyRules.Levels;
    public IReadOnlyList<ConscienceQuestRule> WeeklyQuests => ConscienceJourneyRules.WeeklyQuests;
    public IReadOnlyList<ConscienceBadgeRule> Badges => ConscienceJourneyRules.Badges;
    public IReadOnlyList<ConscienceMascotMomentRule> MascotMoments => ConscienceJourneyRules.MascotMoments;
}
