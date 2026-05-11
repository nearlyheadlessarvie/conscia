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
        await EnsureSharedConsciaSchemaAsync(db, ct);

        var demoUserIds = new[] { scenario.User.Id }
            .Concat(scenario.AdditionalUsers.Select(u => u.Id))
            .ToList();
        var demoEmails = new[] { scenario.User.Email }
            .Concat(scenario.AdditionalUsers.Select(u => u.Email))
            .ToList();

        var existingUserIds = await db.Users
            .Where(u =>
                demoUserIds.Contains(u.Id) ||
                demoEmails.Contains(u.Email))
            .Select(u => u.Id)
            .ToListAsync(ct);

        if (existingUserIds.Count > 0)
        {
            var existingFamilySpaceIds = await db.FamilyMembers
                .Where(m => existingUserIds.Contains(m.UserId))
                .Select(m => m.FamilySpaceId)
                .Distinct()
                .ToListAsync(ct);

            if (existingFamilySpaceIds.Count > 0)
            {
                var existingInvites = await db.FamilyInvites
                    .Where(i => existingFamilySpaceIds.Contains(i.FamilySpaceId))
                    .ToListAsync(ct);
                db.FamilyInvites.RemoveRange(existingInvites);

                var existingMembers = await db.FamilyMembers
                    .Where(m => existingFamilySpaceIds.Contains(m.FamilySpaceId))
                    .ToListAsync(ct);
                db.FamilyMembers.RemoveRange(existingMembers);

                var existingSpaces = await db.FamilySpaces
                    .Where(s => existingFamilySpaceIds.Contains(s.Id))
                    .ToListAsync(ct);
                db.FamilySpaces.RemoveRange(existingSpaces);
            }

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
        db.Users.AddRange(scenario.AdditionalUsers);
        db.UserIdentities.Add(scenario.Identity);
        db.UserIdentities.AddRange(scenario.AdditionalIdentities);
        db.UserSubscriptions.Add(scenario.Subscription);
        db.FamilySpaces.Add(scenario.FamilySpace);
        db.FamilyMembers.AddRange(scenario.FamilyMembers);
        db.FamilyInvites.AddRange(scenario.FamilyInvites);
        db.Budgets.AddRange(scenario.Budgets);

        await db.SaveChangesAsync(ct);
    }

    private static async Task EnsureSharedConsciaSchemaAsync(ConsciaDbContext db, CancellationToken ct)
    {
        // Story-demo databases may have been created through EnsureCreated before
        // Shared Conscia existed, so keep this profile self-healing for local demos.
        await db.Database.ExecuteSqlRawAsync(
            """
            ALTER TABLE budgets ADD COLUMN IF NOT EXISTS "Scope" text NOT NULL DEFAULT 'Personal';
            ALTER TABLE budgets ADD COLUMN IF NOT EXISTS "FamilySpaceId" uuid NULL;
            ALTER TABLE budgets ADD COLUMN IF NOT EXISTS "SharedAt" timestamp with time zone NULL;
            ALTER TABLE budgets ADD COLUMN IF NOT EXISTS "SharedByUserId" uuid NULL;

            CREATE TABLE IF NOT EXISTS family_spaces (
                "Id" uuid NOT NULL,
                "Name" character varying(120) NOT NULL,
                "CurrencyCode" character varying(3) NOT NULL,
                "CreatedByUserId" uuid NOT NULL,
                "CreatedAt" timestamp with time zone NOT NULL,
                "PremiumGraceEndsAt" timestamp with time zone NULL,
                "IsReadOnly" boolean NOT NULL DEFAULT false,
                CONSTRAINT "PK_family_spaces" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS family_members (
                "Id" uuid NOT NULL,
                "FamilySpaceId" uuid NOT NULL,
                "UserId" uuid NOT NULL,
                "Role" character varying(30) NOT NULL,
                "JoinedAt" timestamp with time zone NOT NULL,
                CONSTRAINT "PK_family_members" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS family_invites (
                "Id" uuid NOT NULL,
                "FamilySpaceId" uuid NOT NULL,
                "Email" character varying(256) NOT NULL,
                "Role" character varying(30) NOT NULL,
                "InvitedByUserId" uuid NOT NULL,
                "CreatedAt" timestamp with time zone NOT NULL,
                "ExpiresAt" timestamp with time zone NOT NULL,
                "AcceptedAt" timestamp with time zone NULL,
                "DeclinedAt" timestamp with time zone NULL,
                CONSTRAINT "PK_family_invites" PRIMARY KEY ("Id")
            );

            CREATE INDEX IF NOT EXISTS "IX_budgets_FamilySpaceId" ON budgets ("FamilySpaceId");
            CREATE INDEX IF NOT EXISTS "IX_family_spaces_CreatedByUserId" ON family_spaces ("CreatedByUserId");
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_family_members_UserId" ON family_members ("UserId");
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_family_members_FamilySpaceId_UserId" ON family_members ("FamilySpaceId", "UserId");
            CREATE INDEX IF NOT EXISTS "IX_family_invites_Email" ON family_invites ("Email");
            CREATE INDEX IF NOT EXISTS "IX_family_invites_FamilySpaceId_Email" ON family_invites ("FamilySpaceId", "Email");
            """,
            ct);
    }
}
