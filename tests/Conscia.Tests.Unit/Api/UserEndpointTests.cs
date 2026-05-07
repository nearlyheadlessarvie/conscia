using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Domain.Entities;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class UserEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private readonly string _token;

    public UserEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _token = factory.GenerateTestToken();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);
    }

    [Fact]
    public async Task GetMe_Authenticated_ReturnsUser()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = userId, Email = "alice@example.com", PreferredCurrency = "USD", Locale = "en-US" });

        var response = await _client.GetAsync("/api/v1/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("alice@example.com", body);
    }

    [Fact]
    public async Task GetMe_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/v1/users/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateMe_ValidPayload_Returns200()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.UpdateProfileAsync(userId, It.Is<UserProfileUpdateDto>(d => d.PreferredCurrency == "EUR"), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = userId, Email = "alice@example.com", PreferredCurrency = "EUR", Locale = "en-US" });

        var response = await _client.PutAsJsonAsync("/api/v1/users/me", new
        {
            preferredCurrency = "EUR"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("EUR", body);
    }

    [Fact]
    public async Task UpdateMe_LocationSuggestionsEnabled_Returns200()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.UpdateProfileAsync(
                userId,
                It.Is<UserProfileUpdateDto>(d => d.LocationSuggestionsEnabled == true),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = userId,
                Email = "alice@example.com",
                PreferredCurrency = "USD",
                Locale = "en-US",
                LocationSuggestionsEnabled = true
            });

        var response = await _client.PutAsJsonAsync("/api/v1/users/me", new
        {
            locationSuggestionsEnabled = true
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"locationSuggestionsEnabled\":true", body);
    }
}
