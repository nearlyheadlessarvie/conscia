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
        Assert.True(scenario.MonthlyCategorySpends.Count >= 6);
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
