using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class SuggestionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public SuggestionEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns200_WithSuggestions()
    {
        var suggestions = new List<PurchaseSuggestionDto>
        {
            new("Starbucks", 6.50m, "USD", "Coffee", "3× this week")
        };
        var mock = new Mock<IPurchaseSuggestionService>();
        mock.Setup(s => s.GetSuggestionsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(suggestions);

        var client = _factory.WithWebHostBuilder(b =>
            b.ConfigureServices(s =>
                s.AddScoped<IPurchaseSuggestionService>(_ => mock.Object)))
            .CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken());

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<List<PurchaseSuggestionDto>>();
        Assert.NotNull(body);
        Assert.Single(body);
        Assert.Equal("Starbucks", body[0].Description);
        Assert.Equal(6.50m, body[0].Amount);
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns200_WithEmptyList()
    {
        var mock = new Mock<IPurchaseSuggestionService>();
        mock.Setup(s => s.GetSuggestionsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<PurchaseSuggestionDto>());

        var client = _factory.WithWebHostBuilder(b =>
            b.ConfigureServices(s =>
                s.AddScoped<IPurchaseSuggestionService>(_ => mock.Object)))
            .CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken());

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<List<PurchaseSuggestionDto>>();
        Assert.NotNull(body);
        Assert.Empty(body);
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns401_WhenUnauthenticated()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
