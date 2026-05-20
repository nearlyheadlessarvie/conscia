using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class RecurringEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    public RecurringEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task PostRecurring_ReturnsCreatedSchedule()
    {
        var scheduleId = Guid.NewGuid();
        var startDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);

        _factory.RecurringScheduleServiceMock
            .Setup(s => s.CreateAsync(UserId, It.IsAny<CreateRecurringScheduleDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RecurringSchedule
            {
                Id = scheduleId,
                UserId = UserId,
                Type = TransactionType.Expense,
                Amount = new Money(1500m, "PHP"),
                Category = "Bills",
                Counterparty = "Water",
                StartDate = startDate,
                Cadence = RecurringCadence.Monthly,
                NextRunAt = startDate,
                IsActive = true,
            });

        var response = await _client.PostAsJsonAsync("/api/recurring", new
        {
            type = 0,
            amount = 1500,
            currencyCode = "PHP",
            category = "Bills",
            counterparty = "Water",
            startDate = startDate.ToString("O"),
            cadence = 1
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
