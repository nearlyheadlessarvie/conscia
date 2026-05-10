using Conscia.Tools.Seeder.Profiles;
using Conscia.Tools.Seeder.Story;

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
        Assert.True(scenario.MonthlyCategorySpends.Count >= 6);
    }
}
