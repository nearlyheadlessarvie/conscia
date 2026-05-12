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

    [Fact]
    public async Task PrePurchase_FamilyContextWithoutMembership_ReturnsForbidden()
    {
        _factory.FamilySpaceRepoMock
            .Setup(r => r.GetMembershipByUserIdAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);

        var response = await _client.PostAsJsonAsync("/api/v1/ai/pre-purchase", new
        {
            description = "Dinner delivery",
            amount = 1200,
            currencyCode = "PHP",
            category = "Dining",
            contextScope = "family"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        _factory.AIServiceMock.Verify(
            s => s.GeneratePrePurchaseResponseAsync(It.IsAny<AIContext>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task PrePurchase_FamilyContext_SendsCompactFamilySummary()
    {
        var familySpaceId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        AIContext? capturedContext = null;
        _factory.FamilySpaceRepoMock
            .Setup(r => r.GetMembershipByUserIdAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = UserId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });
        _factory.BudgetRepoMock
            .Setup(r => r.ListByFamilySpaceAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Budget
                {
                    Id = Guid.NewGuid(),
                    UserId = UserId,
                    Category = "Dining",
                    MonthlyLimit = 4000m,
                    CurrencyCode = "PHP",
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _factory.TransactionRepoMock
            .Setup(r => r.GetByFamilySpaceAndDateRangeAsync(
                familySpaceId,
                It.IsAny<DateTime>(),
                It.IsAny<DateTime>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = UserId,
                    Type = TransactionType.Expense,
                    Amount = new Money(1200m, "PHP"),
                    Category = "Dining",
                    Date = DateTime.UtcNow,
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                },
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = UserId,
                    Type = TransactionType.Income,
                    Amount = new Money(15000m, "PHP"),
                    Category = "Contribution",
                    Date = DateTime.UtcNow,
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _factory.RecurringScheduleRepoMock
            .Setup(r => r.ListByFamilySpaceAsync(familySpaceId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new RecurringSchedule
                {
                    Id = Guid.NewGuid(),
                    UserId = UserId,
                    Type = TransactionType.Expense,
                    Amount = new Money(2500m, "PHP"),
                    Category = "Bills",
                    StartDate = DateTime.UtcNow,
                    NextRunAt = DateTime.UtcNow,
                    Cadence = RecurringCadence.Monthly,
                    IsActive = true,
                    Scope = RecordScope.Family,
                    FamilySpaceId = familySpaceId
                }
            ]);
        _factory.BudgetServiceMock
            .Setup(s => s.ListStatusesByUserAsync(UserId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync([]);
        _factory.TransactionServiceMock
            .Setup(s => s.ListAsync(UserId, 1, 100, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<Transaction> { Items = [], Page = 1, PageSize = 100, TotalCount = 0 });
        _factory.AIServiceMock
            .Setup(s => s.GeneratePrePurchaseResponseAsync(It.IsAny<AIContext>(), It.IsAny<CancellationToken>()))
            .Callback<AIContext, CancellationToken>((context, _) => capturedContext = context)
            .ReturnsAsync(new AIResponse
            {
                DevilMessage = "Family treat?",
                AngelMessage = "Check the household plan.",
                NeutralMessage = "Family context included."
            });

        var response = await _client.PostAsJsonAsync("/api/v1/ai/pre-purchase", new
        {
            description = "Dinner delivery",
            amount = 1200,
            currencyCode = "PHP",
            category = "Dining",
            contextScope = "family"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(capturedContext);
        Assert.Equal("family", capturedContext!.ContextScope);
        Assert.Contains("Family context:", capturedContext.FamilyContextSummary);
        Assert.Contains("family expenses total: PHP 1200.00", capturedContext.FamilyContextSummary);
        Assert.Contains("family income total: PHP 15000.00", capturedContext.FamilyContextSummary);
        Assert.Contains("Active family recurring obligations: 1", capturedContext.FamilyContextSummary);
    }
}
