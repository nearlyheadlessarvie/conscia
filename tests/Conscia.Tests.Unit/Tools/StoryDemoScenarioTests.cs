using Conscia.Tools.Seeder.Profiles;
using Conscia.Tools.Seeder.Story;
using Microsoft.EntityFrameworkCore;
using Conscia.Infrastructure.Persistence;
using Conscia.Domain.Entities;

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
    public void Build_CreatesBothBudgetedAndUnbudgetedBudgetTrendExamples()
    {
        var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

        var diningBudget = Assert.Single(scenario.Budgets, budget => budget.Category == "Dining");
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
    public async Task SeedAsync_ReplacesOnlyTheStoryDemoRelationalSlice()
    {
        var options = new DbContextOptionsBuilder<ConsciaDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        await using var db = new ConsciaDbContext(options);
        await db.Database.EnsureCreatedAsync();

        var otherUserId = Guid.NewGuid();
        db.Users.Add(new User
        {
            Id = otherUserId,
            Email = "other@example.com",
            PreferredCurrency = "PHP",
            Locale = "en_PH"
        });

        var now = DateTime.Parse("2026-05-11T00:00:00Z");
        var scenario = StoryDemoScenario.Build(now);
        await StoryDemoRdsSeeder.SeedAsync(db, scenario, CancellationToken.None);

        db.Budgets.Add(new Budget
        {
            Id = Guid.NewGuid(),
            UserId = scenario.User.Id,
            Category = "Coffee",
            MonthlyLimit = 999m,
            CurrencyCode = "PHP"
        });
        await db.SaveChangesAsync();

        await StoryDemoRdsSeeder.SeedAsync(db, scenario, CancellationToken.None);

        Assert.Equal(2, await db.Users.CountAsync());
        Assert.Equal(1, await db.Users.CountAsync(u => u.Email == scenario.User.Email));
        Assert.Equal(1, await db.UserIdentities.CountAsync(ui => ui.UserId == scenario.User.Id));
        Assert.Equal(1, await db.UserSubscriptions.CountAsync(us => us.UserId == scenario.User.Id));
        Assert.Equal(scenario.Budgets.Count, await db.Budgets.CountAsync(b => b.UserId == scenario.User.Id));
        Assert.DoesNotContain(await db.Budgets.Where(b => b.UserId == scenario.User.Id).ToListAsync(), b => b.Category == "Coffee");
    }
}
