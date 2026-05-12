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
    private readonly Mock<IFamilySpaceRepository> _familyRepoMock = new();

    private RecurringScheduleService CreateService() =>
        new(
            _repoMock.Object,
            NullLogger<RecurringScheduleService>.Instance,
            _familyRepoMock.Object);

    [Fact]
    public async Task CreateAsync_SetsNextRunAtToStartDate()
    {
        var service = CreateService();
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
        var service = CreateService();
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _familyRepoMock.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });
        var dto = new CreateRecurringScheduleDto
        {
            Type = TransactionType.Expense,
            Amount = 1899m,
            CurrencyCode = "PHP",
            Category = "Bills",
            Counterparty = "Home internet",
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

    [Fact]
    public async Task CreateAsync_FamilyScopeRejectsMissingMembership()
    {
        var service = CreateService();
        var userId = Guid.NewGuid();
        _familyRepoMock.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.CreateAsync(userId, new CreateRecurringScheduleDto
            {
                Type = TransactionType.Expense,
                Amount = 1899m,
                CurrencyCode = "PHP",
                Category = "Bills",
                StartDate = DateTime.UtcNow,
                Cadence = RecurringCadence.Monthly,
                Scope = RecordScope.Family,
                FamilySpaceId = Guid.NewGuid()
            }));

        Assert.Equal("You do not belong to a Family Space.", error.Message);
        _repoMock.Verify(r => r.AddAsync(It.IsAny<RecurringSchedule>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}
