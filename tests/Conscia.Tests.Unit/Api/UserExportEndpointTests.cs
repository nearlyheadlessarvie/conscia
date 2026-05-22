using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class UserExportEndpointTests : IClassFixture<TestWebAppFactory>
{
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;

    public UserExportEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task ExportUserData_IncludesCurrentUserOwnedDatasets()
    {
        var transactionId = Guid.NewGuid();
        var now = new DateTime(2026, 5, 11, 8, 0, 0, DateTimeKind.Utc);

        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = UserId,
                Email = "alice@example.com",
                PreferredCurrency = "PHP",
                Locale = "en-PH",
                CreatedAt = now,
                SpendingPersonality = "balanced",
                IncomeRange = "mid",
                OccupationType = "employed",
                HouseholdSize = "solo",
                HasCompletedOnboarding = true,
                AiPersonalityIntensity = "playful"
            });

        _factory.TransactionServiceMock
            .Setup(s => s.ListAsync(UserId, 1, 10000, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<Transaction>
            {
                Items =
                [
                    new()
                    {
                        Id = transactionId,
                        UserId = UserId,
                        Type = TransactionType.Expense,
                        Amount = new Money(280, "PHP"),
                        Category = "Dining",
                        Counterparty = "Starbucks",
                        Date = now,
                        RegretLevel = RegretLevel.NotSure
                    }
                ],
                TotalCount = 1,
                Page = 1,
                PageSize = 10000
            });

        _factory.BudgetServiceMock
            .Setup(s => s.ListStatusesByUserAsync(UserId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new BudgetStatus
            {
                Id = Guid.NewGuid(),
                UserId = UserId,
                Category = "Dining",
                MonthlyLimit = 4000,
                CurrentSpend = 280,
                CurrencyCode = "PHP"
            }]);

        _factory.RecurringScheduleServiceMock
            .Setup(s => s.ListAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new RecurringSchedule
            {
                Id = Guid.NewGuid(),
                UserId = UserId,
                Type = TransactionType.Income,
                Amount = new Money(1000, "PHP"),
                Category = "Salary",
                Cadence = RecurringCadence.Monthly,
                StartDate = now,
                NextRunAt = now.AddMonths(1)
            }]);

        _factory.AlertServiceMock
            .Setup(s => s.ListAlertsAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new InAppAlert
            {
                UserId = UserId,
                TriggerName = "RepeatedRegretCategory",
                Title = "Shopping is heating up",
                Message = "Pause before the next purchase.",
                Priority = 80,
                CreatedAt = now
            }]);

        _factory.WeeklyInsightsRepoMock
            .Setup(r => r.GetByUserIdAsync(UserId, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new WeeklyInsights
            {
                UserId = UserId,
                WeekStartDate = now.Date,
                Mood = FinancialMood.Balanced,
                WorthItPercentage = 71,
                WorthItCount = 5,
                TotalTransactionCount = 7
            }]);

        _factory.PurchasePatternRepoMock
            .Setup(r => r.GetSummaryAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PurchasePatternSummary
            {
                UserId = UserId,
                RegrettedAmount = 1890,
                RegrettedCategory = "Shopping",
                AvgRegretRate = 0.33,
                PatternCount = 4,
                UpdatedAt = now
            });

        _factory.PurchasePatternRepoMock
            .Setup(r => r.GetCategoriesAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new CategoryPattern
            {
                UserId = UserId,
                Category = "Shopping",
                TotalSpend = 5400,
                RegrettedSpend = 1890,
                RegretRate = 0.35,
                TransactionCount = 6,
                ProjectedAnnual = 21600,
                UpdatedAt = now
            }]);

        _factory.PurchasePatternRepoMock
            .Setup(r => r.GetMerchantsAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new MerchantPattern
            {
                UserId = UserId,
                Merchant = "Starbucks",
                VisitCount = 6,
                RegretCount = 2,
                RegretRate = 0.33,
                LastVisitDate = "2026-05-09",
                UpdatedAt = now
            }]);

        _factory.MonthlyCategorySpendRepoMock
            .Setup(r => r.ListByUserAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new MonthlyCategorySpend
            {
                UserId = UserId,
                MonthKey = "2026-05",
                Category = "Dining",
                NormalizedCategory = "dining",
                CurrencyCode = "PHP",
                TotalExpenseAmount = 280,
                TransactionCount = 1,
                LastUpdatedAt = now
            }]);

        _factory.AIInteractionRepoMock
            .Setup(r => r.ListByUserAsync(UserId, null, null, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new AIInteraction
            {
                Id = Guid.NewGuid(),
                UserId = UserId,
                TransactionId = transactionId,
                InteractionType = "pre_purchase",
                AngelMsg = "Save it.",
                DevilMsg = "Spend it.",
                NeutralMsg = "Think it through.",
                CreatedAt = now
            }]);

        _factory.ConscienceJourneyRepoMock
            .Setup(r => r.GetProgressAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ConscienceJourneyProgress
            {
                UserId = UserId,
                XpTotal = 125,
                MomentumDays = 4,
                BestMomentumDays = 6,
                UpdatedAt = now
            });

        _factory.ConscienceJourneyRepoMock
            .Setup(r => r.GetBadgeProgressAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new ConscienceBadgeProgress
            {
                UserId = UserId,
                BadgeKey = "reflection_starter",
                Progress = 1,
                Target = 1,
                UnlockedAt = now,
                UpdatedAt = now
            }]);

        _factory.ConscienceJourneyRepoMock
            .Setup(r => r.ListQuestProgressAsync(UserId, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new ConscienceQuestProgress
            {
                UserId = UserId,
                WeekStart = DateOnly.FromDateTime(now),
                QuestKey = "reflect_three_purchases",
                Progress = 1,
                Target = 3,
                UpdatedAt = now
            }]);

        _factory.ConscienceJourneyRepoMock
            .Setup(r => r.ListEventsAsync(UserId, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new ConscienceJourneyEventRecord
            {
                UserId = UserId,
                EventType = "reflection_completed",
                SourceId = transactionId.ToString(),
                XpAwarded = 20,
                CreatedAt = now
            }]);

        _factory.ConscienceJourneyRepoMock
            .Setup(r => r.ListMascotMomentsAsync(UserId, 100, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new ConscienceMascotMoment
            {
                UserId = UserId,
                Key = "steady_saver",
                Persona = "angel",
                Title = "Nice pause",
                Message = "That reflection counted.",
                CreatedAt = now
            }]);

        _factory.PushDeviceTokenRepoMock
            .Setup(r => r.GetActiveByUserAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([new PushDeviceToken
            {
                UserId = UserId,
                Token = "secret-device-token",
                Platform = "android",
                CreatedAt = now,
                UpdatedAt = now,
                LastSeenAt = now,
                IsActive = true
            }]);

        var response = await _client.GetAsync("/api/users/me/export");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        await using var stream = await response.Content.ReadAsStreamAsync();
        using var document = await JsonDocument.ParseAsync(stream);
        var root = document.RootElement;

        Assert.Equal("balanced", root.GetProperty("profile").GetProperty("spendingPersonality").GetString());
        Assert.NotEmpty(root.GetProperty("transactions").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("budgets").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("recurringSchedules").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("alerts").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("insights").GetProperty("weekly").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("insights").GetProperty("purchasePatterns").GetProperty("categories").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("insights").GetProperty("monthlyCategorySpends").EnumerateArray());
        Assert.NotEmpty(root.GetProperty("aiInteractions").EnumerateArray());
        Assert.Equal(125, root.GetProperty("conscienceJourney").GetProperty("progress").GetProperty("xpTotal").GetInt32());
        Assert.NotEmpty(root.GetProperty("conscienceJourney").GetProperty("events").EnumerateArray());

        var device = root.GetProperty("pushNotificationDevices").EnumerateArray().Single();
        Assert.Equal("android", device.GetProperty("platform").GetString());
        Assert.False(device.TryGetProperty("token", out _));
    }

    [Fact]
    public async Task ExportUserData_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/users/me/export");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
