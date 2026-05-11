using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class PushNotificationEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public PushNotificationEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task RegisterDeviceToken_StoresTokenForCurrentUser()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/v1/push/device-tokens",
            new { token = "fcm-token-123", platform = "android" });

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        _factory.PushDeviceTokenRepoMock.Verify(
            repo => repo.UpsertAsync(
                It.Is<PushDeviceToken>(token =>
                    token.UserId == UserId
                    && token.Token == "fcm-token-123"
                    && token.Platform == "android"
                    && token.IsActive),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task RegisterDeviceToken_WhenTokenIsBlank_ReturnsBadRequest()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/v1/push/device-tokens",
            new { token = " ", platform = "android" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        _factory.PushDeviceTokenRepoMock.Verify(
            repo => repo.UpsertAsync(It.IsAny<PushDeviceToken>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task RegisterDeviceToken_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/v1/push/device-tokens",
            new { token = "fcm-token-123", platform = "ios" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
