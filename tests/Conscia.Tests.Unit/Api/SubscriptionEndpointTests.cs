using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.Models;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class SubscriptionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public SubscriptionEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Status_ReturnsLifetimeFields_WhenEffectiveStatusIsLifetime()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.GetEffectiveStatusAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EffectiveSubscriptionStatus
            {
                Tier = SubscriptionTier.Premium,
                IsActive = true,
                IsLifetime = true,
                Source = "lifetime"
            });

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken());

        var response = await client.GetAsync("/api/subscriptions/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"source\":\"lifetime\"", body);
        Assert.Contains("\"isLifetime\":true", body);
    }
}
