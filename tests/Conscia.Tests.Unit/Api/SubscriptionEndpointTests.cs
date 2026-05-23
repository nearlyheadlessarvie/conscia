using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
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
                Status = SubscriptionStatus.Active,
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

    [Fact]
    public async Task AppleNotification_MissingSignedPayload_Returns400()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/subscriptions/apple/notifications", new { });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AppleNotification_ValidPayload_DelegatesToService()
    {
        _factory.AppleServerNotificationVerifierMock
            .Setup(v => v.VerifyAndDecodeAsync("signed-payload", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AppleServerNotification(
                "DID_RENEW",
                null,
                DateTime.UtcNow,
                new AppleServerNotificationData("PROD", "orig-123", DateTime.UtcNow.AddDays(30), null)));

        _factory.SubscriptionServiceMock
            .Setup(s => s.ProcessAppleServerNotificationAsync(It.IsAny<AppleServerNotification>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/subscriptions/apple/notifications", new
        {
            signedPayload = "signed-payload"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        _factory.SubscriptionServiceMock.Verify(
            s => s.ProcessAppleServerNotificationAsync(
                It.Is<AppleServerNotification>(n => n.NotificationType == "DID_RENEW" && n.Data.OriginalTransactionId == "orig-123"),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
