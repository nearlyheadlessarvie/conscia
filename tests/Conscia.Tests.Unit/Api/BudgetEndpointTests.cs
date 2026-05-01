using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class BudgetEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public BudgetEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task CreateBudget_ValidPayload_Returns201()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.CreateAsync(UserId, "Food", 500m, "USD", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget
            {
                Id = Guid.NewGuid(), UserId = UserId, Category = "Food",
                MonthlyLimit = 500m, CurrencyCode = "USD"
            });

        var response = await _client.PostAsJsonAsync("/api/v1/budgets", new
        {
            category = "Food",
            monthlyLimit = 500,
            currencyCode = "USD"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task ListBudgets_ReturnsArray()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.ListByUserAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Id = Guid.NewGuid(), Category = "Food", MonthlyLimit = 500, CurrentSpend = 200, CurrencyCode = "USD" }
            });

        var response = await _client.GetAsync("/api/v1/budgets");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetBudget_NotFound_Returns404()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.GetByIdAsync(UserId, It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Budget?)null);

        var response = await _client.GetAsync($"/api/v1/budgets/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteBudget_OwnerMismatch_Returns403()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.DeleteAsync(UserId, It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UnauthorizedAccessException());

        var response = await _client.DeleteAsync($"/api/v1/budgets/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CreateBudget_ZeroLimit_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/budgets", new
        {
            category = "Food",
            monthlyLimit = 0,
            currencyCode = "USD"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
