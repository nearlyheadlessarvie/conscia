using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class ExchangeRateEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;

    public ExchangeRateEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task GetRate_ReturnsOk_WhenRateAvailable()
    {
        _factory.ExchangeRateServiceMock
            .Setup(s => s.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()))
            .ReturnsAsync(1.0857m);

        var response = await _client.GetAsync("/api/exchange-rates/EUR/USD");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("1.0857", body);
        Assert.Contains("EUR", body);
        Assert.Contains("USD", body);
    }

    [Fact]
    public async Task GetRate_Returns404_WhenRateUnavailable()
    {
        _factory.ExchangeRateServiceMock
            .Setup(s => s.GetRateAsync("EUR", "XYZ", It.IsAny<CancellationToken>()))
            .ReturnsAsync((decimal?)null);

        var response = await _client.GetAsync("/api/exchange-rates/EUR/XYZ");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetRate_Returns401_WhenUnauthenticated()
    {
        var anonClient = _factory.CreateClient();
        var response = await anonClient.GetAsync("/api/exchange-rates/EUR/USD");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
