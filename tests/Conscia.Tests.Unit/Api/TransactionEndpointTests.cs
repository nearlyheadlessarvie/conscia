using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class TransactionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public TransactionEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task CreateTransaction_ValidPayload_Returns201()
    {
        var txnId = Guid.NewGuid();
        CreateTransactionDto? capturedDto = null;
        _factory.TransactionServiceMock
            .Setup(s => s.CreateAsync(UserId, It.IsAny<CreateTransactionDto>(), It.IsAny<CancellationToken>()))
            .Callback<Guid, CreateTransactionDto, CancellationToken>((_, dto, _) => capturedDto = dto)
            .ReturnsAsync(new Transaction
            {
                Id = txnId, UserId = UserId, Type = TransactionType.Expense,
                Amount = new Money(42.50m, "USD"), Category = "Food",
                Counterparty = "Corner Cafe",
                Date = DateTime.UtcNow, CreatedAt = DateTime.UtcNow
            });

        var response = await _client.PostAsJsonAsync("/api/v1/transactions", new
        {
            type = 0,
            amount = 42.50,
            currencyCode = "USD",
            category = "Food",
            counterparty = "Corner Cafe",
            placeName = "Office Pantry",
            date = DateTime.UtcNow.AddHours(-1).ToString("O")
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(capturedDto);
        Assert.Equal("Corner Cafe", capturedDto!.Counterparty);
        Assert.Equal("Office Pantry", capturedDto.PlaceName);

        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("Corner Cafe", body.RootElement.GetProperty("counterparty").GetString());
        Assert.False(body.RootElement.TryGetProperty("merchant", out _));
    }

    [Fact]
    public async Task ListTransactions_ReturnsPagedResult()
    {
        _factory.TransactionServiceMock
            .Setup(s => s.ListAsync(UserId, 1, 20, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<Transaction>
            {
                Items = new List<Transaction>
                {
                    new()
                    {
                        Id = Guid.NewGuid(),
                        Type = TransactionType.Expense,
                        Amount = new Money(10, "USD"),
                        Category = "Food",
                        Counterparty = "Corner Cafe"
                    }
                },
                Page = 1, PageSize = 20, TotalCount = 1
            });

        var response = await _client.GetAsync("/api/v1/transactions");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var firstItem = body.RootElement.GetProperty("items")[0];
        Assert.Equal("Corner Cafe", firstItem.GetProperty("counterparty").GetString());
        Assert.False(firstItem.TryGetProperty("merchant", out _));
    }

    [Fact]
    public async Task GetTransaction_NotFound_Returns404()
    {
        _factory.TransactionServiceMock
            .Setup(s => s.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction?)null);

        var response = await _client.GetAsync($"/api/v1/transactions/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetTransaction_ReturnsCounterpartyAndPlaceName()
    {
        var transactionId = Guid.NewGuid();
        _factory.TransactionServiceMock
            .Setup(s => s.GetByIdAsync(transactionId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Transaction
            {
                Id = transactionId,
                UserId = UserId,
                Type = TransactionType.Expense,
                Amount = new Money(19.99m, "USD"),
                Category = "Food",
                Counterparty = "Corner Cafe",
                Date = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                Location = new Location
                {
                    Latitude = 14.55,
                    Longitude = 121.02,
                    PlaceName = "Office Pantry"
                }
            });

        var response = await _client.GetAsync($"/api/v1/transactions/{transactionId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("Corner Cafe", body.RootElement.GetProperty("counterparty").GetString());
        Assert.False(body.RootElement.TryGetProperty("merchant", out _));
        Assert.Equal("Office Pantry", body.RootElement.GetProperty("location").GetProperty("placeName").GetString());
        Assert.False(body.RootElement.GetProperty("location").TryGetProperty("merchantName", out _));
    }

    [Fact]
    public async Task UpdateTransaction_ReturnsCounterparty()
    {
        var transactionId = Guid.NewGuid();
        UpdateTransactionDto? capturedDto = null;
        _factory.TransactionServiceMock
            .Setup(s => s.UpdateAsync(transactionId, It.IsAny<UpdateTransactionDto>(), It.IsAny<CancellationToken>()))
            .Callback<Guid, UpdateTransactionDto, CancellationToken>((_, dto, _) => capturedDto = dto)
            .ReturnsAsync(new Transaction
            {
                Id = transactionId,
                UserId = UserId,
                Type = TransactionType.Expense,
                Amount = new Money(24.50m, "USD"),
                Category = "Food",
                Counterparty = "Updated Cafe",
                Date = DateTime.UtcNow
            });

        var response = await _client.PutAsJsonAsync($"/api/v1/transactions/{transactionId}", new
        {
            counterparty = "Updated Cafe"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(capturedDto);
        Assert.Equal("Updated Cafe", capturedDto!.Counterparty);

        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("Updated Cafe", body.RootElement.GetProperty("counterparty").GetString());
        Assert.False(body.RootElement.TryGetProperty("merchant", out _));
    }

    [Fact]
    public async Task DeleteTransaction_Success_Returns204()
    {
        _factory.TransactionServiceMock
            .Setup(s => s.DeleteAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var response = await _client.DeleteAsync($"/api/v1/transactions/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task CreateTransaction_InvalidAmount_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/transactions", new
        {
            type = 0,
            amount = 0,
            currencyCode = "USD",
            category = "Food",
            date = DateTime.UtcNow.ToString("O")
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
