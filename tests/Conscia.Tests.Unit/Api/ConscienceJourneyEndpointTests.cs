using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Constants;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class ConscienceJourneyEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public ConscienceJourneyEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task GetJourney_ReturnsSummary()
    {
        _factory.ConscienceJourneyServiceMock
            .Setup(s => s.GetJourneyAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Summary());

        var response = await _client.GetAsync("/api/v1/conscience-journey");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("Impulse Spotter", body);
        Assert.Contains("reflect_three_purchases", body);
    }

    [Fact]
    public async Task RecordEvent_ReturnsUpdatedJourney()
    {
        _factory.ConscienceJourneyServiceMock
            .Setup(s => s.RecordEventAsync(
                UserId,
                ConscienceEventTypes.ReflectionCompleted,
                "tx-1",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Update(xpAwarded: 20, wasDuplicate: false));

        var response = await _client.PostAsJsonAsync("/api/v1/conscience-journey/events", new
        {
            eventType = ConscienceEventTypes.ReflectionCompleted,
            sourceId = "tx-1"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"xpAwarded\":20", body);
        Assert.Contains("\"wasDuplicate\":false", body);
    }

    [Fact]
    public async Task RecordEvent_Duplicate_ReturnsCurrentJourneyWithoutAward()
    {
        _factory.ConscienceJourneyServiceMock
            .Setup(s => s.RecordEventAsync(
                UserId,
                ConscienceEventTypes.ReflectionCompleted,
                "tx-1",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Update(xpAwarded: 0, wasDuplicate: true));

        var response = await _client.PostAsJsonAsync("/api/v1/conscience-journey/events", new
        {
            eventType = ConscienceEventTypes.ReflectionCompleted,
            sourceId = "tx-1"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"xpAwarded\":0", body);
        Assert.Contains("\"wasDuplicate\":true", body);
    }

    [Fact]
    public async Task RecordEvent_UnsupportedEvent_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/conscience-journey/events", new
        {
            eventType = "money_farmed",
            sourceId = "bad-1"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetJourney_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/conscience-journey");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static ConscienceJourneySummaryDto Summary() =>
        new(
            XpTotal: 125,
            CurrentLevel: new ConscienceLevelDto("impulse_spotter", "Impulse Spotter", 100),
            NextLevel: new ConscienceLevelDto("budget_guardian", "Budget Guardian", 300),
            XpIntoLevel: 25,
            XpToNextLevel: 175,
            MomentumDays: 4,
            BestMomentumDays: 6,
            WeeklyQuests:
            [
                new ConscienceQuestDto(
                    "reflect_three_purchases",
                    "Reflect on 3 purchases",
                    "Turn recent decisions into useful signal.",
                    Progress: 1,
                    Target: 3,
                    XpReward: 30,
                    IsCompleted: false,
                    CompletedAt: null)
            ],
            Badges: [],
            RecentMascotMoment: null);

    private static ConscienceJourneyUpdateDto Update(int xpAwarded, bool wasDuplicate) =>
        new(
            Summary(),
            xpAwarded,
            wasDuplicate,
            LeveledUp: false,
            CompletedQuestKeys: [],
            UnlockedBadgeKeys: [],
            MascotMoment: null);
}
