# Story Demo Seed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated `story-demo` seed profile that creates one coherent local demo account with linked data across dashboard, budgets, transactions, alerts, recurring schedules, behavioral insights, purchase patterns, and budget trends.

**Architecture:** Keep `tools/Seeder` as the single entrypoint, but split it into a lightweight profile router plus focused seeding helpers for relational and Dynamo-backed datasets. The new `story-demo` path should be explicitly opt-in, rerunnable for the dedicated demo user, and should write all persisted “read model” rows directly instead of depending on background processors.

**Tech Stack:** .NET 8 console app, EF Core / PostgreSQL, DynamoDB Local, existing domain entities and repository table shapes

---

## File Structure

### Files to create

- `tools/Seeder/Profiles/SeedProfile.cs`
  Responsibility: defines the small set of supported seeding modes and keeps profile selection explicit.
- `tools/Seeder/Profiles/StoryDemoProfile.cs`
  Responsibility: owns the high-level orchestration for the `story-demo` seed.
- `tools/Seeder/Story/StoryDemoScenario.cs`
  Responsibility: stores the curated story constants and deterministic IDs/dates/categories for the demo account.
- `tools/Seeder/Story/StoryDemoRdsSeeder.cs`
  Responsibility: creates or refreshes the demo user, identity, subscription, and budgets in PostgreSQL.
- `tools/Seeder/Story/StoryDemoDynamoSeeder.cs`
  Responsibility: clears and rewrites the demo user’s Dynamo-backed data for transactions, alerts, weekly insights, purchase patterns, recurring schedules, and monthly category spends.
- `tools/Seeder/Story/StoryDemoConsoleReport.cs`
  Responsibility: prints which profile ran, which user was refreshed, and the main datasets seeded.
- `tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs`
  Responsibility: locks the scenario invariants that matter for the visual walkthrough.

### Files to modify

- `tools/Seeder/Program.cs`
  Responsibility: parse CLI args, choose the profile, build shared clients, and dispatch to the selected seeding flow.
- `tools/Seeder/Seeder.csproj`
  Responsibility: include the new source files if any project metadata needs updating.
- `README.md`
  Responsibility: document how to run the `story-demo` seed profile and which demo user to log into.

### Existing code and references to consult while implementing

- `src/Conscia.Infrastructure/Persistence/ConsciaDbContext.cs`
  Used for: user, identity, subscription, budget persistence shape.
- `src/Conscia.Domain/Entities/User.cs`
  Used for: demo user profile fields like locale, preferred currency, onboarding completion, and AI personality intensity.
- `src/Conscia.Domain/Entities/UserIdentity.cs`
  Used for: mock-auth-compatible email identity creation.
- `src/Conscia.Domain/Entities/Transaction.cs`
  Used for: transaction story data shape.
- `src/Conscia.Domain/Entities/RecurringSchedule.cs`
  Used for: recurring schedule story data.
- `src/Conscia.Domain/Entities/WeeklyInsights.cs`
  Used for: behavioral insights persistence shape.
- `src/Conscia.Domain/Entities/PurchasePattern.cs`
  Used for: summary/category/merchant pattern rows.
- `src/Conscia.Domain/Entities/MonthlyCategorySpend.cs`
  Used for: budget trends projection rows.
- `src/Conscia.Infrastructure/Repositories/WeeklyInsightsRepository.cs`
  Used for: table key shape for weekly insights.
- `src/Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`
  Used for: table key shape for purchase pattern summary/category/merchant rows.
- `src/Conscia.Infrastructure/Repositories/InAppAlertRepository.cs`
  Used for: alert persistence item shape.
- `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
  Used for: transaction item shape and key conventions.
- `src/Conscia.Infrastructure/Repositories/RecurringScheduleRepository.cs`
  Used for: recurring schedule item shape.
- `src/Conscia.Infrastructure/Repositories/MonthlyCategorySpendRepository.cs`
  Used for: projection key shape for monthly category spends.

---

### Task 1: Add explicit seed profile routing

**Files:**
- Create: `tools/Seeder/Profiles/SeedProfile.cs`
- Modify: `tools/Seeder/Program.cs`

- [ ] **Step 1: Write the failing profile-selection test as a scenario note**

Create `tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs` with:

```csharp
using Conscia.Tools.Seeder.Profiles;

namespace Conscia.Tests.Unit.Tools;

public class StoryDemoScenarioTests
{
    [Theory]
    [InlineData([], SeedProfile.Default)]
    [InlineData(new[] { "story-demo" }, SeedProfile.StoryDemo)]
    public void Parse_ReturnsExpectedProfile(string[] args, SeedProfile expected)
    {
        var profile = SeedProfileParser.Parse(args);
        Assert.Equal(expected, profile);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter StoryDemoScenarioTests`
Expected: FAIL because `SeedProfile` / `SeedProfileParser` do not exist yet

- [ ] **Step 3: Add the profile enum and parser**

Create `tools/Seeder/Profiles/SeedProfile.cs`:

```csharp
namespace Conscia.Tools.Seeder.Profiles;

public enum SeedProfile
{
    Default,
    StoryDemo,
}

public static class SeedProfileParser
{
    public static SeedProfile Parse(string[] args)
    {
        if (args.Length == 0) return SeedProfile.Default;

        return args[0].Trim().ToLowerInvariant() switch
        {
            "story-demo" => SeedProfile.StoryDemo,
            _ => throw new InvalidOperationException(
                $"Unknown seed profile '{args[0]}'. Supported profiles: default, story-demo.")
        };
    }
}
```

- [ ] **Step 4: Refactor `tools/Seeder/Program.cs` to use the parser**

Replace the current top of `tools/Seeder/Program.cs` with:

```csharp
using Conscia.Infrastructure.Persistence;
using Conscia.Tools.Seeder.Profiles;
using Conscia.Tools.Seeder.Story;
using Microsoft.EntityFrameworkCore;

var profile = SeedProfileParser.Parse(args);

Console.WriteLine("=== Conscia Seeder ===\n");
Console.WriteLine($"[Seeder] Profile: {profile}");

var dynamoConfig = new AmazonDynamoDBConfig
{
    ServiceURL = "http://localhost:8000",
    AuthenticationRegion = "us-east-1"
};
var dynamo = new AmazonDynamoDBClient(new BasicAWSCredentials("local", "local"), dynamoConfig);

var s3Config = new AmazonS3Config
{
    ServiceURL = "http://localhost:9000",
    ForcePathStyle = true,
    AuthenticationRegion = "us-east-1"
};
var s3 = new AmazonS3Client(new BasicAWSCredentials("minioadmin", "minioadmin"), s3Config);

var dbOptions = new DbContextOptionsBuilder<ConsciaDbContext>()
    .UseNpgsql("Host=localhost;Port=5432;Database=conscia;Username=conscia;Password=conscia_dev")
    .Options;
using var db = new ConsciaDbContext(dbOptions);

Console.WriteLine("[RDS] Ensuring database is created...");
await db.Database.EnsureCreatedAsync();

switch (profile)
{
    case SeedProfile.Default:
        Console.WriteLine("[Seeder] Default profile not yet expanded in this task.");
        break;
    case SeedProfile.StoryDemo:
        await StoryDemoProfile.RunAsync(db, dynamo, s3, CancellationToken.None);
        break;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dotnet test tests/Conscia.Tests.Unit --filter StoryDemoScenarioTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add tools/Seeder/Profiles/SeedProfile.cs tools/Seeder/Program.cs tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs
git commit -m "feat: add seeder profile routing"
```

### Task 2: Define the story-demo scenario data

**Files:**
- Create: `tools/Seeder/Story/StoryDemoScenario.cs`
- Modify: `tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs`

- [ ] **Step 1: Write the failing scenario invariant test**

Append this test to `tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs`:

```csharp
[Fact]
public void Build_CreatesSubscriptionsSpendingWithoutSubscriptionBudget()
{
    var scenario = StoryDemoScenario.Build(DateTime.Parse("2026-05-11T00:00:00Z"));

    Assert.Contains(scenario.Transactions, tx => tx.Category == "Subscriptions");
    Assert.DoesNotContain(scenario.Budgets, budget => budget.Category == "Subscriptions");
    Assert.True(scenario.MonthlyCategorySpends.Count >= 6);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter StoryDemoScenarioTests`
Expected: FAIL because `StoryDemoScenario` does not exist

- [ ] **Step 3: Add the scenario builder with deterministic IDs and core story data**

Create `tools/Seeder/Story/StoryDemoScenario.cs`:

```csharp
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Tools.Seeder.Story;

public sealed class StoryDemoScenario
{
    public required User User { get; init; }
    public required UserIdentity Identity { get; init; }
    public required IReadOnlyList<Budget> Budgets { get; init; }
    public required IReadOnlyList<Transaction> Transactions { get; init; }
    public required IReadOnlyList<RecurringSchedule> RecurringSchedules { get; init; }
    public required IReadOnlyList<WeeklyInsights> WeeklyInsights { get; init; }
    public required PurchasePatternSummary PurchaseSummary { get; init; }
    public required IReadOnlyList<CategoryPattern> CategoryPatterns { get; init; }
    public required IReadOnlyList<MerchantPattern> MerchantPatterns { get; init; }
    public required IReadOnlyList<MonthlyCategorySpend> MonthlyCategorySpends { get; init; }
    public required IReadOnlyList<Conscia.Application.Models.InAppAlert> Alerts { get; init; }

    public static StoryDemoScenario Build(DateTime nowUtc)
    {
        var userId = Guid.Parse("7aa7aa7a-1111-4444-8888-111111111111");

        var user = new User
        {
            Id = userId,
            Email = "story-demo@example.com",
            PreferredCurrency = "PHP",
            Locale = "en_PH",
            HasCompletedOnboarding = true,
            LocationSuggestionsEnabled = true,
            AiPersonalityIntensity = "balanced",
            SpendingPersonality = "balanced",
            IncomeRange = "mid",
            OccupationType = "employed",
            HouseholdSize = "solo",
            CreatedAt = nowUtc.AddMonths(-4)
        };

        var identity = new UserIdentity
        {
            Id = Guid.Parse("7aa7aa7a-1111-4444-8888-222222222222"),
            UserId = userId,
            Provider = AuthProvider.Email,
            ProviderSub = "story-demo@example.com",
            CreatedAt = nowUtc.AddMonths(-4)
        };

        // Fill the remaining lists in Task 3 after the test is red/green.
        return new StoryDemoScenario
        {
            User = user,
            Identity = identity,
            Budgets = [],
            Transactions = [],
            RecurringSchedules = [],
            WeeklyInsights = [],
            PurchaseSummary = new PurchasePatternSummary { UserId = userId, UpdatedAt = nowUtc },
            CategoryPatterns = [],
            MerchantPatterns = [],
            MonthlyCategorySpends = [],
            Alerts = []
        };
    }
}
```

- [ ] **Step 4: Fill the scenario with the curated story data**

Update the `return new StoryDemoScenario` block to include:

```csharp
Budgets =
[
    new Budget { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000001"), UserId = userId, Category = "Dining", MonthlyLimit = 4000m, CurrencyCode = "PHP" },
    new Budget { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000002"), UserId = userId, Category = "Bills", MonthlyLimit = 12000m, CurrencyCode = "PHP" },
    new Budget { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000003"), UserId = userId, Category = "Shopping", MonthlyLimit = 3500m, CurrencyCode = "PHP" }
],
Transactions =
[
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Starbucks", Amount = new Money(280m, "PHP"), Date = nowUtc.AddDays(-2), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddDays(-2) },
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "OpenAI", Amount = new Money(300m, "PHP"), Date = nowUtc.AddDays(-4), CreatedAt = nowUtc.AddDays(-4) },
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000003"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Meralco", Amount = new Money(2195m, "PHP"), Date = nowUtc.AddDays(-6), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-6) },
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Uniqlo", Amount = new Money(1890m, "PHP"), Date = nowUtc.AddDays(-10), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddDays(-10) },
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000005"), UserId = userId, Type = TransactionType.Expense, Category = "Transportation", Counterparty = "Grab", Amount = new Money(420m, "PHP"), Date = nowUtc.AddDays(-11), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-11) },
    new Transaction { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000006"), UserId = userId, Type = TransactionType.Income, Category = "Salary", Counterparty = "Employer", Amount = new Money(45000m, "PHP"), Date = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc), CreatedAt = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc) }
],
RecurringSchedules =
[
    new RecurringSchedule { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Netflix", Amount = new Money(549m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(5), IsActive = true },
    new RecurringSchedule { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Globe", Amount = new Money(1499m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(8), IsActive = true }
]
```

Also add:

```csharp
MonthlyCategorySpends =
[
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-03", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2100m, TransactionCount = 7, LastUpdatedAt = nowUtc },
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-04", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2650m, TransactionCount = 8, LastUpdatedAt = nowUtc },
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-05", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 3180m, TransactionCount = 9, LastUpdatedAt = nowUtc },
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-03", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 820m, TransactionCount = 2, LastUpdatedAt = nowUtc },
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-04", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 980m, TransactionCount = 3, LastUpdatedAt = nowUtc },
    new MonthlyCategorySpend { UserId = userId, MonthKey = "2026-05", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 1140m, TransactionCount = 3, LastUpdatedAt = nowUtc }
]
```

And fill `WeeklyInsights`, `PurchaseSummary`, `CategoryPatterns`, `MerchantPatterns`, and `Alerts` with the same coherent categories:

```csharp
WeeklyInsights =
[
    new WeeklyInsights
    {
        UserId = userId,
        WeekStartDate = new DateTime(2026, 05, 04, 0, 0, 0, DateTimeKind.Utc),
        Mood = FinancialMood.Balanced,
        WorthItPercentage = 71.43,
        WorthItCount = 5,
        TotalTransactionCount = 7,
        ImpulseTrends =
        [
            new CategoryTrend { Category = "Shopping", RegretRate = 0.60, TransactionCount = 5, Trend = TrendDirection.Worsening },
            new CategoryTrend { Category = "Dining", RegretRate = 0.30, TransactionCount = 8, Trend = TrendDirection.Steady },
            new CategoryTrend { Category = "Subscriptions", RegretRate = 0.10, TransactionCount = 3, Trend = TrendDirection.Improving }
        ]
    }
],
PurchaseSummary = new PurchasePatternSummary
{
    UserId = userId,
    RegrettedAmount = 1890m,
    RegrettedCategory = "Shopping",
    AvgRegretRate = 0.33,
    PatternCount = 4,
    UpdatedAt = nowUtc
},
CategoryPatterns =
[
    new CategoryPattern { UserId = userId, Category = "Shopping", TotalSpend = 5420m, RegrettedSpend = 1890m, RegretRate = 0.35, TransactionCount = 6, ProjectedAnnual = 21680m, UpdatedAt = nowUtc },
    new CategoryPattern { UserId = userId, Category = "Dining", TotalSpend = 7930m, RegrettedSpend = 420m, RegretRate = 0.12, TransactionCount = 12, ProjectedAnnual = 31720m, UpdatedAt = nowUtc }
],
MerchantPatterns =
[
    new MerchantPattern { UserId = userId, Merchant = "Starbucks", VisitCount = 6, RegretCount = 2, RegretRate = 0.33, LastVisitDate = nowUtc.AddDays(-2).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc },
    new MerchantPattern { UserId = userId, Merchant = "Grab", VisitCount = 5, RegretCount = 1, RegretRate = 0.20, LastVisitDate = nowUtc.AddDays(-11).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc }
],
Alerts =
[
    new Conscia.Application.Models.InAppAlert
    {
        Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000001"),
        UserId = userId,
        TriggerName = "budget_nudge",
        Title = "No budget for Subscriptions yet",
        Message = "You logged an expense in Subscriptions without a matching budget. Add one in Settings whenever you are ready.",
        CreatedAt = nowUtc.AddHours(-4),
        TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
    },
    new Conscia.Application.Models.InAppAlert
    {
        Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000002"),
        UserId = userId,
        TriggerName = "reflection_follow_up",
        Title = "Worth revisiting that Uniqlo purchase?",
        Message = "You marked a recent expense with regret. A reflection can help you spot the pattern.",
        CreatedAt = nowUtc.AddHours(-2),
        TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
    }
]
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dotnet test tests/Conscia.Tests.Unit --filter StoryDemoScenarioTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add tools/Seeder/Story/StoryDemoScenario.cs tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs
git commit -m "feat: add story demo scenario data"
```

### Task 3: Seed PostgreSQL story data safely

**Files:**
- Create: `tools/Seeder/Story/StoryDemoRdsSeeder.cs`
- Modify: `tools/Seeder/Profiles/StoryDemoProfile.cs`

- [ ] **Step 1: Write the failing RDS seeding test as an executable smoke target**

Create `tools/Seeder/Profiles/StoryDemoProfile.cs` with this temporary stub:

```csharp
using Amazon.DynamoDBv2;
using Amazon.S3;
using Conscia.Infrastructure.Persistence;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoProfile
{
    public static Task RunAsync(
        ConsciaDbContext db,
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        CancellationToken ct) =>
        throw new NotImplementedException("Story demo profile not implemented yet.");
}
```

- [ ] **Step 2: Run profile to verify it fails**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: FAIL with `NotImplementedException`

- [ ] **Step 3: Implement RDS refresh logic**

Create `tools/Seeder/Story/StoryDemoRdsSeeder.cs`:

```csharp
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoRdsSeeder
{
    public static async Task SeedAsync(ConsciaDbContext db, StoryDemoScenario scenario, CancellationToken ct)
    {
        var existingUser = await db.Users.SingleOrDefaultAsync(
            user => user.Email == scenario.User.Email,
            ct);

        if (existingUser is not null)
        {
            var existingUserId = existingUser.Id;

            var budgets = await db.Budgets.Where(budget => budget.UserId == existingUserId).ToListAsync(ct);
            var identities = await db.UserIdentities.Where(identity => identity.UserId == existingUserId).ToListAsync(ct);
            var subscriptions = await db.UserSubscriptions.Where(subscription => subscription.UserId == existingUserId).ToListAsync(ct);

            db.Budgets.RemoveRange(budgets);
            db.UserIdentities.RemoveRange(identities);
            db.UserSubscriptions.RemoveRange(subscriptions);
            db.Users.Remove(existingUser);
            await db.SaveChangesAsync(ct);
        }

        db.Users.Add(scenario.User);
        db.UserIdentities.Add(scenario.Identity);
        db.Budgets.AddRange(scenario.Budgets);
        db.UserSubscriptions.Add(new UserSubscription
        {
            Id = Guid.Parse("7aa7aa7a-1111-4444-8888-700000000001"),
            UserId = scenario.User.Id,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.iOS,
            ExpiresAt = DateTime.UtcNow.AddYears(1),
            OriginalTransactionId = "story-demo-premium"
        });

        await db.SaveChangesAsync(ct);
    }
}
```

- [ ] **Step 4: Wire the profile to call the RDS seeder first**

Update `tools/Seeder/Profiles/StoryDemoProfile.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.S3;
using Conscia.Infrastructure.Persistence;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoProfile
{
    public static async Task RunAsync(
        ConsciaDbContext db,
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        CancellationToken ct)
    {
        var scenario = StoryDemoScenario.Build(DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc));
        await StoryDemoRdsSeeder.SeedAsync(db, scenario, ct);
    }
}
```

- [ ] **Step 5: Run the profile to verify RDS seeding works**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: PASS through the RDS stage without throwing

- [ ] **Step 6: Commit**

```bash
git add tools/Seeder/Profiles/StoryDemoProfile.cs tools/Seeder/Story/StoryDemoRdsSeeder.cs
git commit -m "feat: seed story demo relational data"
```

### Task 4: Seed Dynamo-backed story data and overwrite reruns safely

**Files:**
- Create: `tools/Seeder/Story/StoryDemoDynamoSeeder.cs`
- Modify: `tools/Seeder/Profiles/StoryDemoProfile.cs`

- [ ] **Step 1: Write the failing Dynamo smoke expectation**

Add this line to the end of `StoryDemoProfile.RunAsync(...)` temporarily:

```csharp
throw new NotImplementedException("Dynamo story demo seeding not implemented yet.");
```

- [ ] **Step 2: Run profile to verify it fails after RDS seeding**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: FAIL with `NotImplementedException` after the relational work completes

- [ ] **Step 3: Implement Dynamo clear-and-reseed helpers**

Create `tools/Seeder/Story/StoryDemoDynamoSeeder.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoDynamoSeeder
{
    public static async Task SeedAsync(IAmazonDynamoDB dynamo, StoryDemoScenario scenario, CancellationToken ct)
    {
        await DeleteUserPartitionAsync(dynamo, "Transactions", $"USER#{scenario.User.Id}", ct);
        await DeleteUserPartitionAsync(dynamo, "WeeklyInsights", $"USER#{scenario.User.Id}", ct);
        await DeleteUserPartitionAsync(dynamo, "PurchasePatterns", $"USER#{scenario.User.Id}", ct);
        await DeleteUserPartitionAsync(dynamo, "InAppAlerts", $"USER#{scenario.User.Id}", ct);
        await DeleteUserPartitionAsync(dynamo, "RecurringSchedules", $"USER#{scenario.User.Id}", ct);
        await DeleteUserPartitionAsync(dynamo, "MonthlyCategorySpends", $"USER#{scenario.User.Id}", ct);

        foreach (var transaction in scenario.Transactions)
        {
            await dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = "Transactions",
                Item = TransactionItem(transaction)
            }, ct);
        }

        foreach (var weeklyInsights in scenario.WeeklyInsights)
        {
            await dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = "WeeklyInsights",
                Item = WeeklyInsightsItem(weeklyInsights)
            }, ct);
        }
    }
```

Continue the same file with the remaining writes:

```csharp
        await PutPurchasePatternsAsync(dynamo, scenario, ct);

        foreach (var alert in scenario.Alerts)
        {
            await dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = "InAppAlerts",
                Item = AlertItem(alert)
            }, ct);
        }

        foreach (var schedule in scenario.RecurringSchedules)
        {
            await dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = "RecurringSchedules",
                Item = RecurringScheduleItem(schedule)
            }, ct);
        }

        foreach (var projection in scenario.MonthlyCategorySpends)
        {
            await dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = "MonthlyCategorySpends",
                Item = MonthlySpendItem(projection)
            }, ct);
        }
    }
```

Add the delete helper and the key item mappers using the exact repository conventions:

```csharp
    private static async Task DeleteUserPartitionAsync(
        IAmazonDynamoDB dynamo,
        string tableName,
        string partitionKey,
        CancellationToken ct)
    {
        Dictionary<string, AttributeValue>? lastKey = null;

        do
        {
            var response = await dynamo.QueryAsync(new QueryRequest
            {
                TableName = tableName,
                KeyConditionExpression = "PK = :pk",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(partitionKey)
                },
                ExclusiveStartKey = lastKey
            }, ct);

            foreach (var item in response.Items)
            {
                await dynamo.DeleteItemAsync(new DeleteItemRequest
                {
                    TableName = tableName,
                    Key = new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = item["PK"],
                        ["SK"] = item["SK"]
                    }
                }, ct);
            }

            lastKey = response.LastEvaluatedKey;
        }
        while (lastKey is { Count: > 0 });
    }
```

Then add the concrete mapper methods:

```csharp
    private static Dictionary<string, AttributeValue> TransactionItem(Transaction transaction) =>
        new()
        {
            ["PK"] = new($"USER#{transaction.UserId}"),
            ["SK"] = new($"DATE#{transaction.Date:O}#TX#{transaction.Id}"),
            ["Id"] = new(transaction.Id.ToString()),
            ["UserId"] = new(transaction.UserId.ToString()),
            ["Type"] = new(transaction.Type.ToString()),
            ["Amount"] = new() { N = transaction.Amount.Amount.ToString("G") },
            ["CurrencyCode"] = new(transaction.Amount.CurrencyCode),
            ["Category"] = new(transaction.Category),
            ["Date"] = new(transaction.Date.ToString("O")),
            ["CreatedAt"] = new(transaction.CreatedAt.ToString("O")),
            ["GSI1SK"] = new($"{transaction.Category}#{transaction.Date:O}")
        };

    private static Dictionary<string, AttributeValue> WeeklyInsightsItem(WeeklyInsights insights) =>
        new()
        {
            ["PK"] = new($"USER#{insights.UserId}"),
            ["SK"] = new($"WEEK#{insights.WeekStartDate:yyyy-MM-dd}"),
            ["UserId"] = new(insights.UserId.ToString()),
            ["WeekStartDate"] = new(insights.WeekStartDate.ToString("O")),
            ["Mood"] = new(insights.Mood.ToString()),
            ["WorthItPercentage"] = new() { N = insights.WorthItPercentage.ToString("F2") },
            ["WorthItCount"] = new() { N = insights.WorthItCount.ToString() },
            ["TotalTransactionCount"] = new() { N = insights.TotalTransactionCount.ToString() },
            ["ImpulseTrends"] = new() { S = JsonSerializer.Serialize(insights.ImpulseTrends) }
        };

    private static Dictionary<string, AttributeValue> AlertItem(Conscia.Application.Models.InAppAlert alert)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{alert.UserId}"),
            ["SK"] = new($"ALERT#{alert.CreatedAt:O}"),
            ["Id"] = new(alert.Id.ToString()),
            ["UserId"] = new(alert.UserId.ToString()),
            ["TriggerName"] = new(alert.TriggerName),
            ["Title"] = new(alert.Title),
            ["Message"] = new(alert.Message),
            ["CreatedAt"] = new(alert.CreatedAt.ToString("O")),
            ["TTL"] = new() { N = alert.TTL.ToString() }
        };

        if (alert.AlertKey is { Length: > 0 }) item["AlertKey"] = new(alert.AlertKey);
        if (alert.ActionLabel is not null) item["ActionLabel"] = new(alert.ActionLabel);
        if (alert.ActionRoute is not null) item["ActionRoute"] = new(alert.ActionRoute);
        if (alert.Category is not null) item["Category"] = new(alert.Category);
        if (alert.Counterparty is not null) item["Counterparty"] = new(alert.Counterparty);
        if (alert.TransactionId.HasValue) item["TransactionId"] = new(alert.TransactionId.Value.ToString());

        return item;
    }

    private static Dictionary<string, AttributeValue> RecurringScheduleItem(RecurringSchedule schedule)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{schedule.UserId}"),
            ["SK"] = new($"RECURRING#{schedule.Id}"),
            ["Id"] = new(schedule.Id.ToString()),
            ["UserId"] = new(schedule.UserId.ToString()),
            ["Type"] = new(schedule.Type.ToString()),
            ["Amount"] = new() { N = schedule.Amount.Amount.ToString("G") },
            ["CurrencyCode"] = new(schedule.Amount.CurrencyCode),
            ["Category"] = new(schedule.Category),
            ["StartDate"] = new(schedule.StartDate.ToString("O")),
            ["Cadence"] = new(schedule.Cadence.ToString()),
            ["NextRunAt"] = new(schedule.NextRunAt.ToString("O")),
            ["IsActive"] = new() { BOOL = schedule.IsActive },
            ["CreatedAt"] = new(schedule.CreatedAt.ToString("O")),
            ["UpdatedAt"] = new(schedule.UpdatedAt.ToString("O"))
        };

        if (schedule.Counterparty is not null) item["Counterparty"] = new(schedule.Counterparty);
        if (schedule.EndDate.HasValue) item["EndDate"] = new(schedule.EndDate.Value.ToString("O"));

        return item;
    }

    private static Dictionary<string, AttributeValue> MonthlySpendItem(MonthlyCategorySpend projection) =>
        new()
        {
            ["PK"] = new($"USER#{projection.UserId}"),
            ["SK"] = new($"MONTH#{projection.MonthKey}#CAT#{projection.NormalizedCategory}"),
            ["UserId"] = new(projection.UserId.ToString()),
            ["MonthKey"] = new(projection.MonthKey),
            ["Category"] = new(projection.Category),
            ["NormalizedCategory"] = new(projection.NormalizedCategory),
            ["CurrencyCode"] = new(projection.CurrencyCode),
            ["TotalExpenseAmount"] = new() { N = projection.TotalExpenseAmount.ToString("G") },
            ["TransactionCount"] = new() { N = projection.TransactionCount.ToString() },
            ["LastUpdatedAt"] = new(projection.LastUpdatedAt.ToString("O"))
        };

    private static async Task PutPurchasePatternsAsync(
        IAmazonDynamoDB dynamo,
        StoryDemoScenario scenario,
        CancellationToken ct)
    {
        var requests = new List<WriteRequest>
        {
            new()
            {
                PutRequest = new PutRequest
                {
                    Item = new Dictionary<string, AttributeValue>
                    {
                        ["PK"] = new($"USER#{scenario.User.Id}"),
                        ["SK"] = new("SUMMARY"),
                        ["RegrettedAmount"] = new() { N = scenario.PurchaseSummary.RegrettedAmount.ToString("G") },
                        ["RegrettedCategory"] = new(scenario.PurchaseSummary.RegrettedCategory),
                        ["AvgRegretRate"] = new() { N = scenario.PurchaseSummary.AvgRegretRate.ToString("F4") },
                        ["PatternCount"] = new() { N = scenario.PurchaseSummary.PatternCount.ToString() },
                        ["UpdatedAt"] = new(scenario.PurchaseSummary.UpdatedAt.ToString("O"))
                    }
                }
            }
        };

        requests.AddRange(scenario.CategoryPatterns.Select(category => new WriteRequest
        {
            PutRequest = new PutRequest
            {
                Item = new Dictionary<string, AttributeValue>
                {
                    ["PK"] = new($"USER#{scenario.User.Id}"),
                    ["SK"] = new($"CAT#{category.Category}"),
                    ["Category"] = new(category.Category),
                    ["TotalSpend"] = new() { N = category.TotalSpend.ToString("G") },
                    ["RegrettedSpend"] = new() { N = category.RegrettedSpend.ToString("G") },
                    ["RegretRate"] = new() { N = category.RegretRate.ToString("F4") },
                    ["TransactionCount"] = new() { N = category.TransactionCount.ToString() },
                    ["ProjectedAnnual"] = new() { N = category.ProjectedAnnual.ToString("G") },
                    ["UpdatedAt"] = new(category.UpdatedAt.ToString("O"))
                }
            }
        }));

        requests.AddRange(scenario.MerchantPatterns.Select(merchant => new WriteRequest
        {
            PutRequest = new PutRequest
            {
                Item = new Dictionary<string, AttributeValue>
                {
                    ["PK"] = new($"USER#{scenario.User.Id}"),
                    ["SK"] = new($"MER#{merchant.Merchant}"),
                    ["Merchant"] = new(merchant.Merchant),
                    ["VisitCount"] = new() { N = merchant.VisitCount.ToString() },
                    ["RegretCount"] = new() { N = merchant.RegretCount.ToString() },
                    ["RegretRate"] = new() { N = merchant.RegretRate.ToString("F4") },
                    ["LastVisitDate"] = new(merchant.LastVisitDate),
                    ["UpdatedAt"] = new(merchant.UpdatedAt.ToString("O"))
                }
            }
        }));

        await dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
        {
            RequestItems = new Dictionary<string, List<WriteRequest>>
            {
                ["PurchasePatterns"] = requests
            }
        }, ct);
    }
```

- [ ] **Step 4: Wire the profile to call the Dynamo seeder and remove the temporary throw**

Update `tools/Seeder/Profiles/StoryDemoProfile.cs`:

```csharp
public static async Task RunAsync(
    ConsciaDbContext db,
    IAmazonDynamoDB dynamo,
    IAmazonS3 s3,
    CancellationToken ct)
{
    var scenario = StoryDemoScenario.Build(DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc));
    await StoryDemoRdsSeeder.SeedAsync(db, scenario, ct);
    await StoryDemoDynamoSeeder.SeedAsync(dynamo, scenario, ct);
}
```

- [ ] **Step 5: Run the profile to verify it completes**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: PASS and return to the prompt without exceptions

- [ ] **Step 6: Commit**

```bash
git add tools/Seeder/Story/StoryDemoDynamoSeeder.cs tools/Seeder/Profiles/StoryDemoProfile.cs
git commit -m "feat: seed story demo dynamo data"
```

### Task 5: Add console reporting and README usage notes

**Files:**
- Create: `tools/Seeder/Story/StoryDemoConsoleReport.cs`
- Modify: `tools/Seeder/Profiles/StoryDemoProfile.cs`
- Modify: `README.md`

- [ ] **Step 1: Write the failing UX expectation as a manual check**

After the current profile completes, note that it does not clearly tell the user which account to log into or what was seeded.

- [ ] **Step 2: Run the profile to verify the output is insufficient**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: PASS but without a clear summary of seeded datasets or login identity

- [ ] **Step 3: Add the console report helper**

Create `tools/Seeder/Story/StoryDemoConsoleReport.cs`:

```csharp
namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoConsoleReport
{
    public static void Write(StoryDemoScenario scenario)
    {
        Console.WriteLine("[StoryDemo] Seed complete");
        Console.WriteLine($"[StoryDemo] User: {scenario.User.Email}");
        Console.WriteLine($"[StoryDemo] Currency/Locale: {scenario.User.PreferredCurrency} / {scenario.User.Locale}");
        Console.WriteLine($"[StoryDemo] Budgets: {scenario.Budgets.Count}");
        Console.WriteLine($"[StoryDemo] Transactions: {scenario.Transactions.Count}");
        Console.WriteLine($"[StoryDemo] Recurring schedules: {scenario.RecurringSchedules.Count}");
        Console.WriteLine($"[StoryDemo] Alerts: {scenario.Alerts.Count}");
        Console.WriteLine($"[StoryDemo] Weekly insights: {scenario.WeeklyInsights.Count}");
        Console.WriteLine($"[StoryDemo] Monthly category spend rows: {scenario.MonthlyCategorySpends.Count}");
        Console.WriteLine("[StoryDemo] Login with story-demo@example.com / password123");
    }
}
```

- [ ] **Step 4: Call the report at the end of the profile and document usage**

Update `tools/Seeder/Profiles/StoryDemoProfile.cs`:

```csharp
await StoryDemoRdsSeeder.SeedAsync(db, scenario, ct);
await StoryDemoDynamoSeeder.SeedAsync(dynamo, scenario, ct);
StoryDemoConsoleReport.Write(scenario);
```

Update `README.md` in the setup and seeded-account sections:

```md
# Rich visual walkthrough data
dotnet run --project tools/Seeder -- story-demo
```

And add a seeded test account row:

```md
| `story-demo@example.com` | `password123` | Premium | Rich emulator walkthrough |
```

- [ ] **Step 5: Run the profile to verify the output is clear**

Run: `dotnet run --project tools/Seeder -- story-demo`
Expected: PASS and output includes:

- `[StoryDemo] Seed complete`
- `story-demo@example.com`
- counts for budgets, transactions, alerts, and projections

- [ ] **Step 6: Commit**

```bash
git add tools/Seeder/Story/StoryDemoConsoleReport.cs tools/Seeder/Profiles/StoryDemoProfile.cs README.md
git commit -m "docs: add story demo seed usage"
```

### Task 6: End-to-end verification on local services

**Files:**
- No code changes unless verification reveals a mismatch

- [ ] **Step 1: Run the full story-demo seed**

Run:

```bash
dotnet run --project tools/Seeder -- story-demo
```

Expected: PASS with the final console report

- [ ] **Step 2: Verify the API can see the seeded relational and Dynamo data**

Run:

```bash
dotnet run --project src/Conscia.Api
```

In a second terminal, authenticate as the story-demo user through the mock auth flow and call:

```bash
curl http://localhost:5000/api/v1/insights/behavioral
curl http://localhost:5000/api/v1/budgets
curl http://localhost:5000/api/v1/alerts
curl http://localhost:5000/api/v1/transactions
```

Expected:

- behavioral insights returns mood, impulse trends, and `budgetTrends`
- budgets returns Dining/Bills/Shopping
- alerts contains a `budget_nudge`
- transactions returns a populated list

- [ ] **Step 3: Verify the emulator walkthrough manually**

Open the Flutter app and log in as:

```text
story-demo@example.com
password123
```

Check these visual states:

- dashboard shows alerts, budget cards, reflection prompt, recent transactions, and budget trends
- budgets screen shows active budgets and leaves Subscriptions unbudgeted
- transactions list/detail show varied categories and regret states
- insights screens are non-empty

- [ ] **Step 4: Commit any verification-driven fixes**

If code changes were required during verification:

```bash
git add <changed files>
git commit -m "fix: polish story demo seed verification gaps"
```

If no code changes were required, skip this commit.

---

## Self-Review

- Spec coverage:
  - explicit opt-in `story-demo` profile: Task 1
  - dedicated demo identity and rerunnable refresh: Tasks 2, 3, and 4
  - visual states across dashboard/budgets/transactions/insights/assistant/recurring: Tasks 2 and 4
  - direct persistence of weekly insights, purchase patterns, and monthly spend projection: Task 4
  - clear console output and README guidance: Task 5
  - local verification flow: Task 6
- Placeholder scan:
  - no `TBD`, `TODO`, or “implement later” placeholders remain
- Type consistency:
  - the plan uses `StoryDemoScenario`, `StoryDemoProfile`, `StoryDemoRdsSeeder`, `StoryDemoDynamoSeeder`, and `StoryDemoConsoleReport` consistently
