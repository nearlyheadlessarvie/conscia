using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class CategoryEndpointTests
{
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    [Fact]
    public async Task ListCategories_ReturnsManagedCategories()
    {
        await using var factory = new TestWebAppFactory();
        factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        factory.CategoryServiceMock
            .Setup(s => s.ListAsync(UserId, RecordScope.Personal, null, false, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new CategoryDto(
                    Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                    "Dining",
                    "dining",
                    TransactionType.Expense.ToString(),
                    RecordScope.Personal.ToString(),
                    null,
                    "dining",
                    "blue",
                    false,
                    true,
                    DateTime.UtcNow,
                    DateTime.UtcNow)
            ]);

        var client = CreateAuthorizedClient(factory);
        var response = await client.GetAsync("/api/categories");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Dining", json[0].GetProperty("name").GetString());
        Assert.True(json[0].GetProperty("isDefault").GetBoolean());
    }

    [Fact]
    public async Task CreateCategory_ValidRequest_ReturnsCreated()
    {
        await using var factory = new TestWebAppFactory();
        factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        var categoryId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        factory.CategoryServiceMock
            .Setup(s => s.CreateAsync(
                UserId,
                It.Is<CreateCategoryDto>(dto =>
                    dto.Name == "Home Repair" &&
                    dto.Type == TransactionType.Expense &&
                    dto.Scope == RecordScope.Personal),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CategoryDto(
                categoryId,
                "Home Repair",
                "home-repair",
                TransactionType.Expense.ToString(),
                RecordScope.Personal.ToString(),
                null,
                "home",
                "blue",
                false,
                false,
                DateTime.UtcNow,
                DateTime.UtcNow));

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/categories", new
        {
            name = "Home Repair",
            type = "Expense",
            scope = "Personal",
            iconKey = "home",
            colorKey = "blue"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.Equal($"/api/categories/{categoryId}", response.Headers.Location?.ToString());
    }

    [Fact]
    public async Task CreateCategory_Duplicate_ReturnsBadRequest()
    {
        await using var factory = new TestWebAppFactory();
        factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        factory.CategoryServiceMock
            .Setup(s => s.CreateAsync(
                It.IsAny<Guid>(),
                It.IsAny<CreateCategoryDto>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("A category with that name already exists."));

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/categories", new
        {
            name = "Dining",
            type = "Expense",
            scope = "Personal",
            iconKey = "dining",
            colorKey = "blue"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateCategory_FreeUser_ReturnsForbiddenUpgradeRequired()
    {
        await using var factory = new TestWebAppFactory();
        factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/categories", new
        {
            name = "Pet care",
            type = "Expense",
            scope = "Personal",
            iconKey = "other",
            colorKey = "green"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.GetProperty("upgradeRequired").GetBoolean());
        factory.CategoryServiceMock.Verify(
            s => s.CreateAsync(It.IsAny<Guid>(), It.IsAny<CreateCategoryDto>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ArchiveCategory_ValidRequest_ReturnsNoContent()
    {
        await using var factory = new TestWebAppFactory();
        factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        var categoryId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        factory.CategoryServiceMock
            .Setup(s => s.ArchiveAsync(UserId, categoryId, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var client = CreateAuthorizedClient(factory);
        var response = await client.DeleteAsync($"/api/categories/{categoryId}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    private static HttpClient CreateAuthorizedClient(TestWebAppFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            factory.GenerateTestToken(UserId.ToString()));
        return client;
    }
}
