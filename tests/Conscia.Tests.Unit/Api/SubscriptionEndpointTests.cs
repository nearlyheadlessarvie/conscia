using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class SubscriptionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public SubscriptionEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task GetStatus_NoSubscription_ReturnsFree()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.GetStatusAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var response = await _client.GetAsync("/api/subscriptions/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("Free", body);
    }

    [Fact]
    public async Task GetStatus_PremiumSubscription_ReturnsPremium()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.GetStatusAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserSubscription
            {
                Id = Guid.NewGuid(), UserId = UserId,
                Tier = SubscriptionTier.Premium, Platform = Platform.iOS,
                ExpiresAt = DateTime.UtcNow.AddYears(1)
            });

        var response = await _client.GetAsync("/api/subscriptions/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("Premium", body);
    }

    [Fact]
    public async Task VerifyiOS_EmptyToken_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/subscriptions/verify/ios", new
        {
            token = ""
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
