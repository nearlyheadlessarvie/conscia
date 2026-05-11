using Conscia.Application.Constants;

namespace Conscia.Tests.Unit.Application;

public class ConscienceJourneyRulesTests
{
    [Fact]
    public void SupportedEventTypes_AllHaveXpRules()
    {
        foreach (var eventType in ConscienceJourneyRules.SupportedEventTypes)
        {
            Assert.True(
                ConscienceJourneyRules.XpByEventType.ContainsKey(eventType),
                $"Missing XP rule for {eventType}");
            Assert.True(
                ConscienceJourneyRules.XpByEventType[eventType] > 0,
                $"XP rule for {eventType} should be positive");
        }
    }

    [Fact]
    public void XpRules_DoNotContainUnsupportedEvents()
    {
        foreach (var eventType in ConscienceJourneyRules.XpByEventType.Keys)
        {
            Assert.Contains(eventType, ConscienceJourneyRules.SupportedEventTypes);
        }
    }

    [Fact]
    public void BadgeKeys_AreUnique()
    {
        var keys = ConscienceJourneyRules.Badges.Select(b => b.Key).ToList();

        Assert.Equal(keys.Count, keys.Distinct(StringComparer.Ordinal).Count());
    }

    [Fact]
    public void QuestKeys_AreUnique()
    {
        var keys = ConscienceJourneyRules.WeeklyQuests.Select(q => q.Key).ToList();

        Assert.Equal(keys.Count, keys.Distinct(StringComparer.Ordinal).Count());
    }

    [Fact]
    public void WeeklyQuestRewards_AreSmallBonusXp()
    {
        var rewards = ConscienceJourneyRules.WeeklyQuests
            .ToDictionary(quest => quest.Key, quest => quest.XpReward);

        Assert.Equal(15, rewards["reflect_three_purchases"]);
        Assert.Equal(10, rewards["check_before_purchase"]);
        Assert.Equal(15, rewards["review_regret_pattern"]);
    }

    [Fact]
    public void Levels_AreOrderedByRequiredXp()
    {
        var requiredXp = ConscienceJourneyRules.Levels.Select(l => l.RequiredXp).ToList();

        Assert.Equal(requiredXp.OrderBy(x => x).ToList(), requiredXp);
        Assert.Equal(0, requiredXp.First());
    }

    [Fact]
    public void Levels_UseSteeperMvpProgression()
    {
        var levels = ConscienceJourneyRules.Levels
            .Select(level => (level.Key, level.RequiredXp))
            .ToList();

        Assert.Equal(
            [
                ("awakening", 0),
                ("impulse_spotter", 120),
                ("budget_guardian", 400),
                ("conscience_captain", 1000),
                ("money_monk", 2200)
            ],
            levels);
    }
}
