using Conscia.Application.Models;
using Conscia.Application.Constants;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Tools.Seeder.Story;

public sealed class StoryDemoScenario
{
    public required User User { get; init; }
    public required UserIdentity Identity { get; init; }
    public required IReadOnlyList<User> AdditionalUsers { get; init; }
    public required IReadOnlyList<UserIdentity> AdditionalIdentities { get; init; }
    public required UserSubscription Subscription { get; init; }
    public required FamilySpace FamilySpace { get; init; }
    public required IReadOnlyList<FamilyMember> FamilyMembers { get; init; }
    public required IReadOnlyList<FamilyInvite> FamilyInvites { get; init; }
    public required IReadOnlyList<Budget> Budgets { get; init; }
    public required IReadOnlyList<Transaction> Transactions { get; init; }
    public required IReadOnlyList<RecurringSchedule> RecurringSchedules { get; init; }
    public required IReadOnlyList<WeeklyInsights> WeeklyInsights { get; init; }
    public required PurchasePatternSummary PurchaseSummary { get; init; }
    public required IReadOnlyList<CategoryPattern> CategoryPatterns { get; init; }
    public required IReadOnlyList<MerchantPattern> MerchantPatterns { get; init; }
    public required IReadOnlyList<MonthlyCategorySpend> MonthlyCategorySpends { get; init; }
    public required ConscienceJourneyProgress ConscienceProgress { get; init; }
    public required IReadOnlyList<ConscienceJourneyEventRecord> ConscienceEvents { get; init; }
    public required IReadOnlyList<ConscienceBadgeProgress> ConscienceBadgeProgress { get; init; }
    public required IReadOnlyList<ConscienceQuestProgress> ConscienceQuestProgress { get; init; }
    public required IReadOnlyList<ConscienceMascotMoment> ConscienceMascotMoments { get; init; }
    public required IReadOnlyList<InAppAlert> Alerts { get; init; }

    public static StoryDemoScenario Build(DateTime nowUtc)
    {
        nowUtc = DateTime.SpecifyKind(nowUtc, DateTimeKind.Utc);

        var userId = Guid.Parse("7aa7aa7a-1111-4444-8888-111111111111");
        var spouseId = Guid.Parse("7aa7aa7a-1111-4444-8888-111111111112");
        var viewerId = Guid.Parse("7aa7aa7a-1111-4444-8888-111111111113");
        var familySpaceId = Guid.Parse("7aa7aa7a-1111-4444-8888-700000000001");
        var monthStart = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var currentWeekStart = GetStartOfWeek(nowUtc);
        var previousWeekStart = currentWeekStart.AddDays(-7);

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

        var spouse = new User
        {
            Id = spouseId,
            Email = "story-spouse@example.com",
            PreferredCurrency = "PHP",
            Locale = "en_PH",
            HasCompletedOnboarding = true,
            LocationSuggestionsEnabled = true,
            AiPersonalityIntensity = "balanced",
            HouseholdSize = "family",
            CreatedAt = nowUtc.AddMonths(-3)
        };

        var viewer = new User
        {
            Id = viewerId,
            Email = "story-viewer@example.com",
            PreferredCurrency = "PHP",
            Locale = "en_PH",
            HasCompletedOnboarding = true,
            AiPersonalityIntensity = "mild",
            HouseholdSize = "family",
            CreatedAt = nowUtc.AddMonths(-2)
        };

        var additionalIdentities = new List<UserIdentity>
        {
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-222222222223"),
                UserId = spouseId,
                Provider = AuthProvider.Email,
                ProviderSub = "story-spouse@example.com",
                CreatedAt = nowUtc.AddMonths(-3)
            },
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-222222222224"),
                UserId = viewerId,
                Provider = AuthProvider.Email,
                ProviderSub = "story-viewer@example.com",
                CreatedAt = nowUtc.AddMonths(-2)
            }
        };

        var subscription = new UserSubscription
        {
            Id = Guid.Parse("7aa7aa7a-1111-4444-8888-250000000001"),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.iOS,
            OriginalTransactionId = "story-demo-premium"
        };

        var familySpace = new FamilySpace
        {
            Id = familySpaceId,
            Name = "Santos Household",
            CurrencyCode = "PHP",
            CreatedByUserId = userId,
            CreatedAt = nowUtc.AddMonths(-1)
        };

        var familyMembers = new List<FamilyMember>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-710000000001"), FamilySpaceId = familySpaceId, UserId = userId, Role = FamilyMemberRole.Owner, JoinedAt = nowUtc.AddMonths(-1) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-710000000002"), FamilySpaceId = familySpaceId, UserId = spouseId, Role = FamilyMemberRole.Contributor, JoinedAt = nowUtc.AddDays(-18) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-710000000003"), FamilySpaceId = familySpaceId, UserId = viewerId, Role = FamilyMemberRole.Viewer, JoinedAt = nowUtc.AddDays(-12) }
        };

        var familyInvites = new List<FamilyInvite>
        {
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-720000000001"),
                FamilySpaceId = familySpaceId,
                Email = "story-cousin@example.com",
                Role = FamilyMemberRole.Viewer,
                InvitedByUserId = userId,
                CreatedAt = nowUtc.AddDays(-1),
                ExpiresAt = nowUtc.AddDays(13)
            }
        };

        var budgets = new List<Budget>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000001"), UserId = userId, Category = "Dining", MonthlyLimit = 4000m, CurrencyCode = "PHP" },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000002"), UserId = userId, Category = "Bills", MonthlyLimit = 12000m, CurrencyCode = "PHP" },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000003"), UserId = userId, Category = "Shopping", MonthlyLimit = 3500m, CurrencyCode = "PHP" },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000004"), UserId = userId, Category = "Dining", MonthlyLimit = 6500m, CurrencyCode = "PHP", Scope = RecordScope.Family, FamilySpaceId = familySpaceId, SharedAt = nowUtc.AddDays(-16), SharedByUserId = userId },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-300000000005"), UserId = userId, Category = "Groceries", MonthlyLimit = 14000m, CurrencyCode = "PHP", Scope = RecordScope.Family, FamilySpaceId = familySpaceId, SharedAt = nowUtc.AddDays(-16), SharedByUserId = userId }
        };

        var transactions = new List<Transaction>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Starbucks", Amount = new Money(280m, "PHP"), Date = nowUtc.AddDays(-2), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddDays(-2) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "OpenAI", Amount = new Money(300m, "PHP"), Date = nowUtc.AddDays(-4), CreatedAt = nowUtc.AddDays(-4) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000003"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Meralco", Amount = new Money(2195m, "PHP"), Date = nowUtc.AddDays(-6), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-6) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Uniqlo", Amount = new Money(1890m, "PHP"), Date = nowUtc.AddDays(-10), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddDays(-10) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000005"), UserId = userId, Type = TransactionType.Expense, Category = "Transportation", Counterparty = "Grab", Amount = new Money(420m, "PHP"), Date = nowUtc.AddDays(-11), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-11) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000006"), UserId = userId, Type = TransactionType.Income, Category = "Salary", Counterparty = "Employer", Amount = new Money(45000m, "PHP"), Date = monthStart, CreatedAt = monthStart },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000007"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Wildflour", Amount = new Money(980m, "PHP"), Date = nowUtc.AddDays(-14), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddDays(-14) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000008"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Shopee", Amount = new Money(1250m, "PHP"), Date = nowUtc.AddDays(-18), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddDays(-18) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000009"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Spotify", Amount = new Money(149m, "PHP"), Date = nowUtc.AddDays(-22), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-22) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000010"), UserId = userId, Type = TransactionType.Expense, Category = "Gift", Counterparty = "National Book Store", Amount = new Money(640m, "PHP"), Date = nowUtc.AddDays(-27), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-27) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000011"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Starbucks", Amount = new Money(310m, "PHP"), Date = nowUtc.AddMonths(-1).AddDays(-3), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddMonths(-1).AddDays(-3) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000012"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Maynilad", Amount = new Money(740m, "PHP"), Date = nowUtc.AddMonths(-1).AddDays(-7), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddMonths(-1).AddDays(-7) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000013"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Uniqlo", Amount = new Money(1530m, "PHP"), Date = nowUtc.AddMonths(-1).AddDays(-13), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddMonths(-1).AddDays(-13) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000014"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "OpenAI", Amount = new Money(300m, "PHP"), Date = nowUtc.AddMonths(-1).AddDays(-18), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddMonths(-1).AddDays(-18) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000015"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Jollibee", Amount = new Money(265m, "PHP"), Date = nowUtc.AddMonths(-2).AddDays(-5), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddMonths(-2).AddDays(-5) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000016"), UserId = userId, Type = TransactionType.Expense, Category = "Transportation", Counterparty = "Grab", Amount = new Money(380m, "PHP"), Date = nowUtc.AddMonths(-2).AddDays(-9), RegretLevel = RegretLevel.NotSure, CreatedAt = nowUtc.AddMonths(-2).AddDays(-9) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000017"), UserId = userId, Type = TransactionType.Expense, Category = "Shopping", Counterparty = "Zara", Amount = new Money(2100m, "PHP"), Date = nowUtc.AddMonths(-2).AddDays(-15), RegretLevel = RegretLevel.Regret, CreatedAt = nowUtc.AddMonths(-2).AddDays(-15) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000018"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Netflix", Amount = new Money(549m, "PHP"), Date = nowUtc.AddMonths(-2).AddDays(-20), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddMonths(-2).AddDays(-20) }
        };

        var recurringSchedules = new List<RecurringSchedule>
        {
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000001"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Netflix", Amount = new Money(549m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(5), IsActive = true, CreatedAt = nowUtc.AddMonths(-3), UpdatedAt = nowUtc },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000002"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Globe", Amount = new Money(1499m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = nowUtc.AddMonths(-3), NextRunAt = nowUtc.AddDays(8), IsActive = true, CreatedAt = nowUtc.AddMonths(-3), UpdatedAt = nowUtc },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000003"), UserId = userId, Type = TransactionType.Income, Category = "Salary", Counterparty = "Freelance Client", Amount = new Money(3500m, "PHP"), Cadence = RecurringCadence.Weekly, StartDate = nowUtc.AddMonths(-1), NextRunAt = nowUtc.AddDays(4), IsActive = true, CreatedAt = nowUtc.AddMonths(-1), UpdatedAt = nowUtc, LastGeneratedAt = nowUtc.AddDays(-3) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-500000000005"), UserId = userId, Type = TransactionType.Expense, Category = "Bills", Counterparty = "Home internet", Amount = new Money(1899m, "PHP"), Cadence = RecurringCadence.Monthly, StartDate = monthStart, NextRunAt = monthStart.AddMonths(1).AddDays(4), IsActive = true, CreatedAt = monthStart, UpdatedAt = nowUtc, Scope = RecordScope.Family, FamilySpaceId = familySpaceId, SharedAt = monthStart, SharedByUserId = userId }
        };

        transactions.AddRange(
        [
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000019"), UserId = userId, Type = TransactionType.Income, Category = "Salary", Counterparty = "Freelance Client", Amount = new Money(3500m, "PHP"), Date = nowUtc.AddDays(-3), RecurringScheduleId = recurringSchedules[2].Id, RecurringOccurrenceDate = nowUtc.AddDays(-3), CreatedAt = nowUtc.AddDays(-3) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000020"), UserId = userId, Type = TransactionType.Expense, Category = "Subscriptions", Counterparty = "Netflix", Amount = new Money(549m, "PHP"), Date = nowUtc.AddMonths(-1).AddDays(-20), RegretLevel = RegretLevel.WorthIt, RecurringScheduleId = recurringSchedules[0].Id, RecurringOccurrenceDate = nowUtc.AddMonths(-1).AddDays(-20), CreatedAt = nowUtc.AddMonths(-1).AddDays(-20) },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000022"), UserId = userId, Type = TransactionType.Expense, Category = "Groceries", Counterparty = "Landers", Amount = new Money(3840m, "PHP"), Date = nowUtc.AddDays(-5), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-5), Scope = RecordScope.Family, FamilySpaceId = familySpaceId, SharedAt = nowUtc.AddDays(-5), SharedByUserId = userId },
            new() { Id = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000023"), UserId = userId, Type = TransactionType.Expense, Category = "Dining", Counterparty = "Manam", Amount = new Money(2460m, "PHP"), Date = nowUtc.AddDays(-8), RegretLevel = RegretLevel.WorthIt, CreatedAt = nowUtc.AddDays(-8), Scope = RecordScope.Family, FamilySpaceId = familySpaceId, SharedAt = nowUtc.AddDays(-8), SharedByUserId = userId }
        ]);

        var weeklyInsights = new List<WeeklyInsights>
        {
            new()
            {
                UserId = userId,
                WeekStartDate = currentWeekStart,
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
            },
            new()
            {
                UserId = userId,
                WeekStartDate = previousWeekStart,
                Mood = FinancialMood.Cautious,
                WorthItPercentage = 57.14,
                WorthItCount = 3,
                TotalTransactionCount = 7,
                ImpulseTrends =
                [
                    new CategoryTrend { Category = "Shopping", RegretRate = 0.72, TransactionCount = 4, Trend = TrendDirection.Worsening },
                    new CategoryTrend { Category = "Dining", RegretRate = 0.42, TransactionCount = 6, Trend = TrendDirection.Steady },
                    new CategoryTrend { Category = "Subscriptions", RegretRate = 0.20, TransactionCount = 2, Trend = TrendDirection.Steady }
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
            new() { UserId = userId, Category = "Dining", TotalSpend = 7930m, RegrettedSpend = 420m, RegretRate = 0.12, TransactionCount = 12, ProjectedAnnual = 31720m, UpdatedAt = nowUtc },
            new() { UserId = userId, Category = "Subscriptions", TotalSpend = 1838m, RegrettedSpend = 0m, RegretRate = 0.00, TransactionCount = 7, ProjectedAnnual = 7352m, UpdatedAt = nowUtc }
        };

        var merchantPatterns = new List<MerchantPattern>
        {
            new() { UserId = userId, Merchant = "Starbucks", VisitCount = 6, RegretCount = 2, RegretRate = 0.33, LastVisitDate = nowUtc.AddDays(-2).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc },
            new() { UserId = userId, Merchant = "Grab", VisitCount = 5, RegretCount = 1, RegretRate = 0.20, LastVisitDate = nowUtc.AddDays(-11).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc },
            new() { UserId = userId, Merchant = "OpenAI", VisitCount = 3, RegretCount = 0, RegretRate = 0.00, LastVisitDate = nowUtc.AddDays(-4).ToString("yyyy-MM-dd"), UpdatedAt = nowUtc }
        };

        var monthlyCategorySpends = new List<MonthlyCategorySpend>
        {
            new() { UserId = userId, MonthKey = "2026-03", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2100m, TransactionCount = 7, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-04", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 2650m, TransactionCount = 8, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-05", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 3400m, TransactionCount = 9, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-03", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 820m, TransactionCount = 2, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-04", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 980m, TransactionCount = 3, LastUpdatedAt = nowUtc },
            new() { UserId = userId, MonthKey = "2026-05", Category = "Subscriptions", NormalizedCategory = "subscriptions", CurrencyCode = "PHP", TotalExpenseAmount = 1140m, TransactionCount = 3, LastUpdatedAt = nowUtc }
        };

        var conscienceEvents = new List<ConscienceJourneyEventRecord>
        {
            new() { UserId = userId, EventType = ConscienceEventTypes.ReflectionCompleted, SourceId = transactions[0].Id.ToString(), XpAwarded = 20, CreatedAt = nowUtc.AddDays(-2).AddHours(1) },
            new() { UserId = userId, EventType = ConscienceEventTypes.ReflectionCompleted, SourceId = transactions[2].Id.ToString(), XpAwarded = 20, CreatedAt = nowUtc.AddDays(-6).AddHours(1) },
            new() { UserId = userId, EventType = ConscienceEventTypes.ReflectionCompleted, SourceId = transactions[3].Id.ToString(), XpAwarded = 20, CreatedAt = nowUtc.AddDays(-10).AddHours(1) },
            new() { UserId = userId, EventType = ConscienceEventTypes.PrePurchaseChecked, SourceId = "prepurchase:dining:test-001", XpAwarded = 20, CreatedAt = nowUtc.AddHours(-5) },
            new() { UserId = userId, EventType = ConscienceEventTypes.InsightReviewed, SourceId = $"insights:{DateOnly.FromDateTime(currentWeekStart):yyyy-MM-dd}", XpAwarded = 10, CreatedAt = nowUtc.AddHours(-4) },
            new() { UserId = userId, EventType = ConscienceEventTypes.RegretPatternReviewed, SourceId = "pattern:shopping:2026-05", XpAwarded = 25, CreatedAt = nowUtc.AddHours(-3) },
            new() { UserId = userId, EventType = ConscienceEventTypes.FamilyInviteSent, SourceId = familyInvites[0].Id.ToString(), XpAwarded = 15, CreatedAt = nowUtc.AddDays(-1) }
        };

        var conscienceProgress = new ConscienceJourneyProgress
        {
            UserId = userId,
            XpTotal = 500,
            MomentumDays = 6,
            BestMomentumDays = 9,
            LastMomentumDate = DateOnly.FromDateTime(nowUtc.Date),
            UpdatedAt = nowUtc
        };

        var currentWeek = DateOnly.FromDateTime(currentWeekStart);
        var conscienceQuestProgress = new List<ConscienceQuestProgress>
        {
            new() { UserId = userId, WeekStart = currentWeek, QuestKey = "reflect_three_purchases", Progress = 3, Target = 3, XpAwarded = 15, CompletedAt = nowUtc.AddHours(-8), UpdatedAt = nowUtc },
            new() { UserId = userId, WeekStart = currentWeek, QuestKey = "check_before_purchase", Progress = 1, Target = 1, XpAwarded = 10, CompletedAt = nowUtc.AddHours(-5), UpdatedAt = nowUtc },
            new() { UserId = userId, WeekStart = currentWeek, QuestKey = "review_regret_pattern", Progress = 1, Target = 1, XpAwarded = 15, CompletedAt = nowUtc.AddHours(-3), UpdatedAt = nowUtc },
            new() { UserId = userId, WeekStart = currentWeek, QuestKey = "send_family_invite", Progress = 1, Target = 1, XpAwarded = 10, CompletedAt = nowUtc.AddDays(-1), UpdatedAt = nowUtc },
            new() { UserId = userId, WeekStart = currentWeek, QuestKey = "add_family_expense", Progress = 1, Target = 1, XpAwarded = 15, CompletedAt = nowUtc.AddDays(-5), UpdatedAt = nowUtc }
        };

        var conscienceBadgeProgress = new List<ConscienceBadgeProgress>
        {
            new() { UserId = userId, BadgeKey = "first_reflection", Progress = 1, Target = 1, UnlockedAt = nowUtc.AddDays(-10).AddHours(1), UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "pause_before_purchase", Progress = 1, Target = 1, UnlockedAt = nowUtc.AddHours(-5), UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "budget_rescuer", Progress = 0, Target = 1, UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "regret_pattern_spotted", Progress = 1, Target = 1, UnlockedAt = nowUtc.AddHours(-3), UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "worth_it_week", Progress = 3, Target = 5, UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "family_founder", Progress = 1, Target = 1, UnlockedAt = nowUtc.AddDays(-1), UpdatedAt = nowUtc },
            new() { UserId = userId, BadgeKey = "family_planner", Progress = 1, Target = 1, UnlockedAt = nowUtc.AddDays(-8), UpdatedAt = nowUtc }
        };

        var conscienceMascotMoments = new List<ConscienceMascotMoment>
        {
            new()
            {
                UserId = userId,
                Key = "pause_before_purchase",
                Persona = "both",
                Title = "You paused before buying.",
                Message = "Impulse and Reason both got a seat at the table.",
                CreatedAt = nowUtc.AddHours(-5)
            },
            new()
            {
                UserId = userId,
                Key = "regret_pattern_spotted",
                Persona = "devil",
                Title = "Pattern spotted.",
                Message = "The little devil has been detected. Suspiciously charming, still useful.",
                CreatedAt = nowUtc.AddHours(-3)
            },
            new()
            {
                UserId = userId,
                Key = "first_reflection",
                Persona = "angel",
                Title = "That is a real conscience rep.",
                Message = "One reflection logged. Tiny halo gains, big awareness energy.",
                CreatedAt = nowUtc.AddDays(-10).AddHours(1)
            }
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
                TriggerName = "ReflectionFollowUp",
                Title = "Worth revisiting that Uniqlo purchase?",
                Message = "You marked a recent expense with regret. A reflection can help you spot the pattern.",
                Counterparty = "Uniqlo",
                TransactionId = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"),
                ActionLabel = "Reflect",
                ActionRoute = "/transactions/7aa7aa7a-1111-4444-8888-400000000004",
                CreatedAt = nowUtc.AddHours(-2),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            },
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000003"),
                UserId = userId,
                AlertKey = "not-sure-streak",
                TriggerName = "NotSureStreak",
                Title = "You keep landing on not sure",
                Message = "Three of your recent rated purchases ended in Not sure. It may be time to slow down and check the pattern.",
                Priority = 50,
                ActionLabel = "Open insights",
                ActionRoute = "/insights",
                CreatedAt = nowUtc.AddHours(-6),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            },
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000004"),
                UserId = userId,
                AlertKey = "cooling-off-suggestion",
                TriggerName = "CoolingOffSuggestion",
                Title = "Your regret pattern is heating up",
                Message = "You have logged a few recent regrets. A quick cooling-off pause could help before the next purchase.",
                Priority = 100,
                ActionLabel = "Review recent purchases",
                ActionRoute = "/transactions/7aa7aa7a-1111-4444-8888-400000000004",
                TransactionId = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000004"),
                Category = "Shopping",
                Counterparty = "Uniqlo",
                CreatedAt = nowUtc.AddHours(-1),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            },
            new()
            {
                Id = Guid.Parse("7aa7aa7a-1111-4444-8888-600000000005"),
                UserId = userId,
                AlertKey = $"recurring:{Guid.Parse("7aa7aa7a-1111-4444-8888-500000000003"):N}:{nowUtc.AddDays(-3):O}",
                TriggerName = "recurring_transaction_created",
                Title = "Recurring income added",
                Message = "Freelance Client was added automatically.",
                Priority = 30,
                ActionLabel = "View transaction",
                ActionRoute = "/transactions/7aa7aa7a-1111-4444-8888-400000000019",
                TransactionId = Guid.Parse("7aa7aa7a-1111-4444-8888-400000000019"),
                Category = "Salary",
                Counterparty = "Freelance Client",
                CreatedAt = nowUtc.AddHours(-3),
                TTL = new DateTimeOffset(nowUtc.AddDays(7)).ToUnixTimeSeconds()
            }
        };

        return new StoryDemoScenario
        {
            User = user,
            Identity = identity,
            AdditionalUsers = [spouse, viewer],
            AdditionalIdentities = additionalIdentities,
            Subscription = subscription,
            FamilySpace = familySpace,
            FamilyMembers = familyMembers,
            FamilyInvites = familyInvites,
            Budgets = budgets,
            Transactions = transactions,
            RecurringSchedules = recurringSchedules,
            WeeklyInsights = weeklyInsights,
            PurchaseSummary = purchaseSummary,
            CategoryPatterns = categoryPatterns,
            MerchantPatterns = merchantPatterns,
            MonthlyCategorySpends = monthlyCategorySpends,
            ConscienceProgress = conscienceProgress,
            ConscienceEvents = conscienceEvents,
            ConscienceBadgeProgress = conscienceBadgeProgress,
            ConscienceQuestProgress = conscienceQuestProgress,
            ConscienceMascotMoments = conscienceMascotMoments,
            Alerts = alerts
        };
    }

    private static DateTime GetStartOfWeek(DateTime date)
    {
        var diff = (7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7;
        return date.AddDays(-diff).Date;
    }
}
