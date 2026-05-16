using Conscia.Tools.Seeder.Profiles;
using Conscia.Tools.Seeder.Story;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Tests.Unit.Tools;

public class StoryDemoScenarioTests
{
    [Theory]
    [InlineData(new string[0], SeedProfile.Default)]
    [InlineData(new[] { "story-demo" }, SeedProfile.StoryDemo)]
    public void Parse_ReturnsExpectedProfile(string[] args, SeedProfile expected)
    {
        var profile = SeedProfileParser.Parse(args);

        Assert.Equal(expected, profile);
    }

    [Fact]
    public void Build_CreatesSubscriptionsSpendingWithoutSubscriptionBudget()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        Assert.Contains(scenario.Transactions, tx => tx.Category == "Subscriptions");
        Assert.DoesNotContain(scenario.Budgets, budget => budget.Category == "Subscriptions");
        Assert.Equal("story-demo-premium", scenario.Subscription.OriginalTransactionId);
        Assert.Equal(2, scenario.WeeklyInsights.Count);
        Assert.Contains(scenario.WeeklyInsights, insight => insight.WeekStartDate == new DateTime(2026, 05, 11, 0, 0, 0, DateTimeKind.Utc));
        Assert.Contains(scenario.WeeklyInsights, insight => insight.WorthItCount == 3);
        Assert.True(scenario.MonthlyCategorySpends.Count >= 6);
    }

    [Fact]
    public void Build_CreatesRichThreeMonthWalkthroughData()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        Assert.True(scenario.Transactions.Count >= 18);
        Assert.True(scenario.Transactions.Select(tx => tx.Date.ToString("yyyy-MM")).Distinct().Count() >= 3);
        Assert.Contains(scenario.Transactions, tx => tx.RecurringScheduleId.HasValue);
        Assert.Contains(scenario.RecurringSchedules, schedule => schedule.Cadence == RecurringCadence.Weekly);
        Assert.Contains(scenario.CategoryPatterns, pattern => pattern.Category == "Subscriptions");
        Assert.Contains(scenario.MerchantPatterns, pattern => pattern.Merchant == "OpenAI");
    }

    [Fact]
    public void Build_UsesScopeInsteadOfFamilyPrefixedCategories()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        Assert.DoesNotContain(scenario.Budgets, budget => budget.Category.StartsWith("Family "));
        Assert.DoesNotContain(scenario.Transactions, tx => tx.Category.StartsWith("Family "));
        Assert.Contains(
            scenario.Transactions,
            tx => tx.Category == "Dining" && tx.Scope == RecordScope.Family);
    }

    [Fact]
    public void Build_CreatesBothBudgetedAndUnbudgetedBudgetTrendExamples()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        var diningBudget = Assert.Single(
            scenario.Budgets,
            budget => budget.Category == "Dining" && budget.Scope == RecordScope.Personal);
        var diningCurrentMonth = Assert.Single(
            scenario.MonthlyCategorySpends,
            spend => spend.Category == "Dining" && spend.MonthKey == "2026-05");
        var subscriptionsCurrentMonth = Assert.Single(
            scenario.MonthlyCategorySpends,
            spend => spend.Category == "Subscriptions" && spend.MonthKey == "2026-05");

        Assert.True(diningCurrentMonth.TotalExpenseAmount / diningBudget.MonthlyLimit >= 0.80m);
        Assert.DoesNotContain(scenario.Budgets, budget => budget.Category == "Subscriptions");
        Assert.True(subscriptionsCurrentMonth.TotalExpenseAmount > 0m);
    }

    [Fact]
    public void Build_CreatesAlertVarietyForNotificationDemo()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        Assert.Contains(scenario.Alerts, alert => alert.TriggerName == "budget_nudge");
        Assert.Contains(scenario.Alerts, alert => alert.TriggerName == "ReflectionFollowUp");
        Assert.Contains(scenario.Alerts, alert => alert.TriggerName == "NotSureStreak");
        Assert.Contains(scenario.Alerts, alert => alert.TriggerName == "CoolingOffSuggestion");
        Assert.Contains(scenario.Alerts, alert => alert.TriggerName == "recurring_transaction_created");
    }

    [Fact]
    public void Build_CreatesConscienceJourneyDemoData()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        Assert.Equal(scenario.User.Id, scenario.ConscienceProgress.UserId);
        Assert.InRange(scenario.ConscienceProgress.XpTotal, 400, 999);
        Assert.True(scenario.ConscienceProgress.MomentumDays > 0);
        Assert.Contains(
            scenario.ConscienceQuestProgress,
            quest => quest.QuestKey == "reflect_three_purchases"
                && quest.CompletedAt.HasValue
                && quest.XpAwarded == 15);
        Assert.Contains(
            scenario.ConscienceBadgeProgress,
            badge => badge.BadgeKey == "first_reflection" && badge.UnlockedAt.HasValue);
        Assert.Contains(
            scenario.ConscienceBadgeProgress,
            badge => badge.BadgeKey == "budget_rescuer" && badge.Progress == 0);
        Assert.Contains(
            scenario.ConscienceMascotMoments,
            moment => moment.Key == "pause_before_purchase" && moment.Persona == "both");
        Assert.Contains(
            scenario.ConscienceEvents,
            evt => evt.EventType == "reflection_completed" && evt.SourceId == scenario.Transactions[0].Id.ToString());
    }

    // Dynamo-backed seeding is covered by local seeder smoke runs because it needs DynamoDB Local.
}
