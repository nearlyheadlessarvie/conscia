using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.Models;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class AlertEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public AlertEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task ListAlerts_ReturnsAlerts()
    {
        _factory.AlertServiceMock
            .Setup(r => r.ListAlertsAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<InAppAlert>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    AlertKey = "repeated-regret-category-dining",
                    UserId = UserId,
                    TriggerName = "RepeatedRegretCategory",
                    Title = "Dining keeps turning into regret",
                    Message = "You have regretted 3 of your last 5 Dining purchases.",
                    ActionLabel = "See category trend",
                    ActionRoute = "/insights/categories/Dining",
                    Priority = 80,
                }
            });

        var response = await _client.GetAsync("/api/v1/alerts");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("RepeatedRegretCategory", body);
        Assert.Contains("repeated-regret-category-dining", body);
        Assert.Contains("/insights/categories/Dining", body);
    }

    [Fact]
    public async Task ListAlerts_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/v1/alerts");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
