using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class RecurringScheduleServiceTests
{
    private readonly Mock<IRecurringScheduleRepository> _repoMock = new();

    [Fact]
    public async Task CreateAsync_SetsNextRunAtToStartDate()
    {
        var service = new RecurringScheduleService(_repoMock.Object, NullLogger<RecurringScheduleService>.Instance);
        var userId = Guid.NewGuid();
        var startDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);
        var dto = new CreateRecurringScheduleDto
        {
            Type = TransactionType.Expense,
            Amount = 999m,
            CurrencyCode = "PHP",
            Category = "Subscriptions",
            Counterparty = "Spotify",
            StartDate = startDate,
            Cadence = RecurringCadence.Monthly,
        };

        _repoMock
            .Setup(r => r.AddAsync(It.IsAny<RecurringSchedule>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((RecurringSchedule schedule, CancellationToken _) => schedule);

        var created = await service.CreateAsync(userId, dto, CancellationToken.None);

        Assert.Equal(startDate, created.NextRunAt);
        Assert.Equal("Spotify", created.Counterparty);
        Assert.True(created.IsActive);
    }

    [Fact]
    public async Task CreateAsync_FamilyScope_AddsFamilyMetadataToSchedule()
    {
        var service = new RecurringScheduleService(_repoMock.Object, NullLogger<RecurringScheduleService>.Instance);
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var dto = new CreateRecurringScheduleDto
        {
            Type = TransactionType.Income,
            Amount = 15000m,
            CurrencyCode = "PHP",
            Category = "Family Contribution",
            Counterparty = "Payroll",
            StartDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc),
            Cadence = RecurringCadence.Monthly,
            Scope = RecordScope.Family,
            FamilySpaceId = familySpaceId
        };

        _repoMock
            .Setup(r => r.AddAsync(It.IsAny<RecurringSchedule>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((RecurringSchedule schedule, CancellationToken _) => schedule);

        var created = await service.CreateAsync(userId, dto, CancellationToken.None);

        Assert.Equal(RecordScope.Family, created.Scope);
        Assert.Equal(familySpaceId, created.FamilySpaceId);
        Assert.Equal(userId, created.SharedByUserId);
        Assert.NotNull(created.SharedAt);
    }
}
