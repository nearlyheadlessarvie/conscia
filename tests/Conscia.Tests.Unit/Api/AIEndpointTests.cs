using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class AIEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public AIEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task PrePurchase_ValidRequest_Returns200()
    {
        _factory.BudgetServiceMock
            .Setup(s => s.ListStatusesByUserAsync(UserId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<BudgetStatus>
            {
                new() { Category = "Electronics", MonthlyLimit = 500, CurrentSpend = 200, CurrencyCode = "USD" }
            });

        _factory.TransactionServiceMock
            .Setup(s => s.ListAsync(UserId, 1, 100, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<Transaction> { Items = new List<Transaction>(), Page = 1, PageSize = 100, TotalCount = 0 });

        _factory.AIServiceMock
            .Setup(s => s.GeneratePrePurchaseResponseAsync(It.IsAny<AIContext>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AIResponse
            {
                DevilMessage = "You deserve this!",
                AngelMessage = "Consider waiting.",
                NeutralMessage = "This is a $299 purchase."
            });

        _factory.AIInteractionRepoMock
            .Setup(r => r.AddAsync(It.IsAny<AIInteraction>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((AIInteraction i, CancellationToken _) => i);

        var response = await _client.PostAsJsonAsync("/api/v1/ai/pre-purchase", new
        {
            description = "New headphones",
            amount = 299.99,
            currencyCode = "USD",
            category = "Electronics"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("You deserve this!", body);
        Assert.Contains("Consider waiting.", body);
    }

    [Fact]
    public async Task PrePurchase_EmptyDescription_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/ai/pre-purchase", new
        {
            description = "",
            amount = 10,
            currencyCode = "USD",
            category = "Food"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
