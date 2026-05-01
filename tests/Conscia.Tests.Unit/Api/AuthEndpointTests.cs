using System.Net;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class AuthEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;

    public AuthEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Register_ValidCredentials_Returns201()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/auth/register", new
        {
            email = $"test-{Guid.NewGuid()}@example.com",
            password = "SecureP@ss123"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.True(body!.ContainsKey("accessToken"));
    }

    [Fact]
    public async Task Login_ValidCredentials_Returns200()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/auth/login", new
        {
            email = "alice@example.com",
            password = "password123"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Login_InvalidCredentials_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/auth/login", new
        {
            email = "nonexistent@example.com",
            password = "wrong"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Register_EmptyEmail_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/auth/register", new
        {
            email = "",
            password = "password123"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
