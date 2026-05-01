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
        _factory.AlertRepoMock
            .Setup(r => r.GetByUserAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<InAppAlert>
            {
                new() { Id = Guid.NewGuid(), UserId = UserId, TriggerName = "BudgetWarning", Title = "Budget Warning", Message = "85% used" }
            });

        var response = await _client.GetAsync("/api/v1/alerts");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("BudgetWarning", body);
    }

    [Fact]
    public async Task ListAlerts_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/v1/alerts");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
