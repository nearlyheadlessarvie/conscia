using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Models;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class UtteranceEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public UtteranceEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task ParseUtterance_Returns200_ForPremiumUser()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _factory.AIServiceMock
            .Setup(s => s.ParseUtteranceAsync("I spent 5 dollars on coffee", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UtteranceParseResult("coffee", 5.00m, "Coffee"));

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Premium"));

        var response = await client.PostAsJsonAsync("/api/transactions/parse-utterance", new
        {
            transcript = "I spent 5 dollars on coffee"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("coffee", body);
        Assert.Contains("Coffee", body);
    }

    [Fact]
    public async Task ParseUtterance_Returns200_WhenTokenTierIsStaleButSubscriptionIsPremium()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _factory.AIServiceMock
            .Setup(s => s.ParseUtteranceAsync("I spent 5 dollars on coffee", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UtteranceParseResult("coffee", 5.00m, "Coffee"));

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Free"));

        var response = await client.PostAsJsonAsync("/api/transactions/parse-utterance", new
        {
            transcript = "I spent 5 dollars on coffee"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ParseUtterance_Returns403_ForFreeUser()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Free"));

        var response = await client.PostAsJsonAsync("/api/transactions/parse-utterance", new
        {
            transcript = "I spent 5 dollars on coffee"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task ParseUtterance_Returns401_WhenUnauthenticated()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/transactions/parse-utterance", new
        {
            transcript = "I spent 5 dollars on coffee"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ParseUtterance_Returns400_WhenTranscriptIsEmpty()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Premium"));

        var response = await client.PostAsJsonAsync("/api/transactions/parse-utterance", new
        {
            transcript = "   "
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
