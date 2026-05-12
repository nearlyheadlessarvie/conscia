using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
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

        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
    }

    [Fact]
    public async Task CreateBudget_ValidPayload_Returns201()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.CreateAsync(UserId, It.Is<CreateBudgetDto>(dto =>
                dto.Category == "Food" &&
                dto.MonthlyLimit == 500m &&
                dto.CurrencyCode == "USD"), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget
            {
                Id = Guid.NewGuid(), UserId = UserId, Category = "Food",
                MonthlyLimit = 500m, CurrencyCode = "USD"
            });
        _factory.BudgetServiceMock
            .Setup(s => s.GetStatusByIdAsync(UserId, It.IsAny<Guid>(), null, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Guid requestUserId, Guid budgetId, DateTime? now, CancellationToken cancellationToken) => new BudgetStatus
            {
                Id = budgetId,
                UserId = requestUserId,
                Category = "Food",
                MonthlyLimit = 500m,
                CurrentSpend = 0m,
                CurrencyCode = "USD"
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
            .Setup(s => s.ListStatusesByUserAsync(UserId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<BudgetStatus>
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
            .Setup(s => s.GetStatusByIdAsync(UserId, It.IsAny<Guid>(), null, It.IsAny<CancellationToken>()))
            .ReturnsAsync((BudgetStatus?)null);

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

    [Fact]
    public async Task CreateBudget_FreeUserDuringOnboarding_AllowsFifthStarterBudget()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = UserId,
                Email = "alice@example.com",
                HasCompletedOnboarding = false
            });
        _factory.BudgetServiceMock
            .Setup(s => s.ListByUserAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Id = Guid.NewGuid(), UserId = UserId, Category = "Groceries", MonthlyLimit = 274m, CurrencyCode = "USD" },
                new() { Id = Guid.NewGuid(), UserId = UserId, Category = "Bills", MonthlyLimit = 196m, CurrencyCode = "USD" },
                new() { Id = Guid.NewGuid(), UserId = UserId, Category = "Dining", MonthlyLimit = 176m, CurrencyCode = "USD" },
                new() { Id = Guid.NewGuid(), UserId = UserId, Category = "Transport", MonthlyLimit = 137m, CurrencyCode = "USD" },
            });
        _factory.BudgetServiceMock
            .Setup(s => s.CreateAsync(UserId, It.Is<CreateBudgetDto>(dto =>
                dto.Category == "Shopping" &&
                dto.MonthlyLimit == 98m &&
                dto.CurrencyCode == "USD"), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Budget
            {
                Id = Guid.NewGuid(),
                UserId = UserId,
                Category = "Shopping",
                MonthlyLimit = 98m,
                CurrencyCode = "USD"
            });
        _factory.BudgetServiceMock
            .Setup(s => s.GetStatusByIdAsync(UserId, It.IsAny<Guid>(), null, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Guid requestUserId, Guid budgetId, DateTime? now, CancellationToken cancellationToken) => new BudgetStatus
            {
                Id = budgetId,
                UserId = requestUserId,
                Category = "Shopping",
                MonthlyLimit = 98m,
                CurrentSpend = 0m,
                CurrencyCode = "USD"
            });

        var response = await _client.PostAsJsonAsync("/api/v1/budgets", new
        {
            category = "Shopping",
            monthlyLimit = 98,
            currencyCode = "USD"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
