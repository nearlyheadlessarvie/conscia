using Conscia.Application.Models;
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
    public required IReadOnlyList<InAppAlert> Alerts { get; init; }

    public static StoryDemoScenario Build(DateTime nowUtc)
    {
        nowUtc = DateTime.SpecifyKind(nowUtc, DateTimeKind.Utc);

        var userId = Guid.Parse("7aa7aa7a-1111-4444-8888-111111111111");
        var monthStart = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);

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

        var budgets = new List<Budget>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000001"), UserId = userId, Category = "Dining", MonthlyLimit = 4000m, CurrencyCode = "PHP" },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000002"), UserId = userId, Category = "Bills", MonthlyLimit = 12000m, CurrencyCode = "PHP" },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000003"), UserId = userId, Category = "Shopping", MonthlyLimit = 3500m, CurrencyCode = "PHP" }
        };

        var transactions = new List<Transaction>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Starbucks", Amount = new Money(280m, "PHP"), Date = nowUtc.AddDays(-2), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddDays(-2) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "OpenAI", Amount = new Money(300m, "PHP"), Date = nowUtc.AddDays(-4), CreatedAt = nowUtc.AddDays(-4) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000003"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Meralco", Amount = new Money(2195m, "PHP"), Date = nowUtc.AddDays(-6), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-6) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Uniqlo", Amount = new Money(1890m, "PHP"), Date = nowUtc.AddDays(-10), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddDays(-10) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000005"), UserId = userId, Type = TransactionType.Expense, Category = "Transportation", Counterparty = "Grab", Amount = new Money(420m, "PHP"), Date = nowUtc.AddDays(-11), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-11) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000006"), UserId = userId, Type = TransactionType.Income, Category = "Salary", Counterparty = "Employer", Amount = new Money(45000m, "PHP"), Date = monthStart, CreatedAt = monthStart }
        };

        var recurringSchedules = new List<RecurringSchedule>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Netflix", Amount = new Money(549m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(5), IsActive = true, CreatedAt = nowUtc.AddMonths(-3), UpdatedAt = nowUtc },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Globe", Amount = new Money(1499m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(8), IsActive = true, CreatedAt = nowUtc.AddMonths(-3), UpdatedAt = nowUtc }
        };

        var weeklyInsights = new List<WeeklyInsights>
        {
            new()
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
        };

        var purchaseSummary = new PurchasePatternSummary
        {
            UserId = userId,
            RegrettedAmount = 1890m,
            RegrettedCategory = "Shopping",
            AvgRegretRate = 0.33,
            PatternCount = 4,
            UpdatedAt = nowUtc
        };

        var categoryPatterns = new List<CategoryPattern>
        {
            new() { UserId = userId, Category = "Shopping", TotalSpend = 5420m, RegrettedSpend = 1890m, RegretRate = 0.35, TransactionCount = 6, ProjectedAnnual = 21680m, UpdatedAt = nowUtc },
            new() { UserId = userId, Category = "Dining", TotalSpend = 7930m, RegrettedSpend = 420m, RegretRate = 0.12, TransactionCount = 12, ProjectedAnnual = 31720m, UpdatedAt = nowUtc }
        };

        var merchantPatterns = new List<MerchantPattern>
        {
            new() { UserId = userId, Merchant = "Starbucks", VisitCount = 6, RegretCount = 2, RegretRate = 0.33, LastVisitDate = nowUtc.AddDays(-2).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc },
            new() { UserId = userId, Merchant = "Grab", VisitCount = 5, RegretCount = 1, RegretRate = 0.20, LastVisitDate = nowUtc.AddDays(-11).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc }
        };

        var monthlyCategorySpends = new List<MonthlyCategorySpend>
        {
            new() { UserId = userId, MonthKey = "2026-03", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2100m, TransactionCount = 7, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-04", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2650m, TransactionCount = 8, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-05", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 3180m, TransactionCount = 9, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-03", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 820m, TransactionCount = 2, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-04", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 980m, TransactionCount = 3, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-05", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 1140m, TransactionCount = 3, LastUpdatedAt = nowUtc }
        };

        var alerts = new List<InAppAlert>
        {
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000001"),
                UserId = userId,
                AlertKey = "budget-nudge-subscriptions",
                TriggerName = "budget_nudge",
                Title = "No budget for Subscriptions yet",
                Message = "You logged an expense in Subscriptions without a matching budget. Add one in Settings whenever you are ready.",
                Category = "Subscriptions",
                ActionLabel = "Add budget",
                ActionRoute = "/settings/budgets",
                CreatedAt = nowUtc.AddHours(-4),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            },
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000002"),
                UserId = userId,
                AlertKey = "reflection-follow-up-uniqlo",
                TriggerName = "reflection_follow_up",
                Title = "Worth revisiting that Uniqlo purchase?",
                Message = "You marked a recent expense with regret. A reflection can help you spot the pattern.",
                Counterparty = "Uniqlo",
                TransactionId = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"),
                ActionLabel = "Reflect",
                ActionRoute = "/transactions/7aa7aa7a-1111-4444-8888-400000000004",
                CreatedAt = nowUtc.AddHours(-2),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            }
        };

        return new StoryDemoScenario
        {
            User = user,
            Identity = identity,
            Budgets = budgets,
            Transactions = transactions,
            RecurringSchedules = recurringSchedules,
            WeeklyInsights = weeklyInsights,
            PurchaseSummary = purchaseSummary,
            CategoryPatterns = categoryPatterns,
            MerchantPatterns = merchantPatterns,
            MonthlyCategorySpends = monthlyCategorySpends,
            Alerts = alerts
        };
    }
}
