using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoRdsSeeder
{
    public static async Task SeedAsync(
        ConsciaDbContext db,
        StoryDemoScenario scenario,
        CancellationToken ct)
    {
        var existingUserIds = await db.Users
            .Where(u => u.Id == scenario.User.Id || u.Email == scenario.User.Email)
            .Select(u => u.Id)
            .ToListAsync(ct);

        if (existingUserIds.Count > 0)
        {
            var existingBudgets = await db.Budgets
                .Where(b => existingUserIds.Contains(b.UserId))
                .ToListAsync(ct);
            db.Budgets.RemoveRange(existingBudgets);

            var existingSubscriptions = await db.UserSubscriptions
                .Where(s => existingUserIds.Contains(s.UserId))
                .ToListAsync(ct);
            db.UserSubscriptions.RemoveRange(existingSubscriptions);

            var existingIdentities = await db.UserIdentities
                .Where(i => existingUserIds.Contains(i.UserId))
                .ToListAsync(ct);
            db.UserIdentities.RemoveRange(existingIdentities);

            var existingUsers = await db.Users
                .Where(u => existingUserIds.Contains(u.Id))
                .ToListAsync(ct);
            db.Users.RemoveRange(existingUsers);

            await db.SaveChangesAsync(ct);
        }

        db.Users.Add(scenario.User);
        db.UserIdentities.Add(scenario.Identity);
        db.UserSubscriptions.Add(scenario.Subscription);
        db.Budgets.AddRange(scenario.Budgets);

        await db.SaveChangesAsync(ct);
    }
}
