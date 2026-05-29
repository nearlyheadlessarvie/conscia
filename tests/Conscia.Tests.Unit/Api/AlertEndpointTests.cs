using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
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

        var response = await _client.GetAsync("/api/alerts");

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
        var response = await client.GetAsync("/api/alerts");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreateAlert_PersistsCurrentUserAlert()
    {
        _factory.AlertServiceMock
            .Setup(s => s.CreateAlertAsync(
                UserId,
                It.Is<InAppAlert>(a =>
                    a.AlertKey == "budget-nudge-dining"
                    && a.TriggerName == "budget_nudge"
                    && a.Title == "No budget for Dining yet"
                    && a.Category == "Dining"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Guid userId, InAppAlert alert, CancellationToken _) =>
            {
                alert.UserId = userId;
                return alert;
            });

        var response = await _client.PostAsJsonAsync("/api/alerts", new
        {
            id = "budget-nudge-dining",
            type = "budget_nudge",
            title = "No budget for Dining yet",
            message = "You logged an expense in Dining without a matching budget.",
            priority = 20,
            actionLabel = "Add budget",
            actionRoute = "/settings/budgets",
            category = "Dining",
            createdAt = DateTime.UtcNow
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        _factory.AlertServiceMock.Verify(s => s.CreateAlertAsync(
            UserId,
            It.Is<InAppAlert>(a =>
                a.AlertKey == "budget-nudge-dining"
                && a.TriggerName == "budget_nudge"
                && a.Title == "No budget for Dining yet"
                && a.Category == "Dining"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DismissAlert_PersistsCurrentUserDismissal()
    {
        _factory.AlertServiceMock
            .Setup(s => s.DismissAlertAsync(
                UserId,
                "budget-nudge-dining",
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var response = await _client.PostAsync("/api/alerts/budget-nudge-dining/dismiss", null);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        _factory.AlertServiceMock.Verify(s => s.DismissAlertAsync(
            UserId,
            "budget-nudge-dining",
            It.IsAny<CancellationToken>()), Times.Once);
    }
}
