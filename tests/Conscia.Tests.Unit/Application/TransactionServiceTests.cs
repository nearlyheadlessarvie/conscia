using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class TransactionServiceTests
{
    private readonly Mock<ITransactionRepository> _repoMock = new();
    private readonly Mock<IExchangeRateService> _fxMock = new();
    private readonly Mock<IRecurringScheduleService> _recurringScheduleServiceMock = new();
    private readonly Mock<IFamilySpaceRepository> _familyRepoMock = new();
    private readonly TransactionService _svc;

    public TransactionServiceTests() => _svc = new TransactionService(
        _repoMock.Object,
        _fxMock.Object,
        NullLogger<TransactionService>.Instance,
        _recurringScheduleServiceMock.Object,
        _familyRepoMock.Object);

    [Fact]
    public async Task CreateAsync_CreatesTransaction()
    {
        var userId = Guid.NewGuid();
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 42.50m,
            CurrencyCode = "USD",
            Category = "Food",
            Counterparty = "McDonald's",
            Date = DateTime.UtcNow
        };

        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        var result = await _svc.CreateAsync(userId, dto);

        Assert.Equal(userId, result.UserId);
        Assert.Equal(42.50m, result.Amount.Amount);
        Assert.Equal("USD", result.Amount.CurrencyCode);
        Assert.Equal("Food", result.Category);
        Assert.Equal("McDonald's", result.Counterparty);

        _repoMock.Verify(r => r.AddWithOutboxAsync(
            It.Is<Transaction>(t => t.UserId == userId),
            It.IsAny<OutboxEvent>(),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_WritesTransactionAndProjectionOutboxEvent()
    {
        var userId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 05, 10, 0, 0, 0, DateTimeKind.Utc);
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 120m,
            CurrencyCode = "PHP",
            Category = "Dining",
            Date = transactionDate
        };

        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        await _svc.CreateAsync(userId, dto);

        _repoMock.Verify(r => r.AddWithOutboxAsync(
            It.Is<Transaction>(t => t.UserId == userId && t.Category == "Dining"),
            It.Is<OutboxEvent>(e =>
                e.EventType == OutboxEventType.TransactionCreated &&
                e.Payload.Contains("\"Category\":\"Dining\"") &&
                e.Payload.Contains("\"CurrencyCode\":\"PHP\"")),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_SetsLocation_WhenLatLongProvided()
    {
        var dto = new CreateTransactionDto
        {
            Amount = 10, CurrencyCode = "USD", Category = "Food",
            Date = DateTime.UtcNow,
            Latitude = 40.7128, Longitude = -74.0060, PlaceName = "NYC Shop"
        };

        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        var result = await _svc.CreateAsync(Guid.NewGuid(), dto);

        Assert.NotNull(result.Location);
        Assert.Equal(40.7128, result.Location!.Latitude);
        Assert.Equal("NYC Shop", result.Location.PlaceName);
    }

    [Fact]
    public async Task GetByIdAsync_DelegatesToRepo()
    {
        var userId = Guid.NewGuid();
        var txnId = Guid.NewGuid();
        var txn = new Transaction { Id = txnId, UserId = userId, Amount = new Money(10, "USD"), Category = "Food" };

        _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>())).ReturnsAsync(txn);

        var result = await _svc.GetByIdAsync(userId, txnId);

        Assert.NotNull(result);
        Assert.Equal(txnId, result!.Id);
    }

    [Fact]
    public async Task UpdateAsync_UpdatesFields()
    {
        var userId = Guid.NewGuid();
        var txnId = Guid.NewGuid();
        var existing = new Transaction
        {
            Id = txnId, UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(50, "USD"),
            Category = "Food",
            Counterparty = "Old Cafe",
            Date = DateTime.UtcNow
        };

        _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>())).ReturnsAsync(existing);
        _repoMock.Setup(r => r.UpdateWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var dto = new UpdateTransactionDto { Amount = 75m, Category = "Dining", Counterparty = "New Cafe" };
        var result = await _svc.UpdateAsync(userId, txnId, dto);

        Assert.Equal(75m, result.Amount.Amount);
        Assert.Equal("USD", result.Amount.CurrencyCode);
        Assert.Equal("Dining", result.Category);
        Assert.Equal("New Cafe", result.Counterparty);
    }

    [Fact]
    public async Task UpdateAsync_WritesProjectionAwareUpdateEvent()
    {
        var userId = Guid.NewGuid();
        var txnId = Guid.NewGuid();
        var existing = new Transaction
        {
            Id = txnId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(50, "USD"),
            Category = "Food",
            Counterparty = "Old Cafe",
            Date = new DateTime(2026, 05, 10, 0, 0, 0, DateTimeKind.Utc)
        };

        _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);
        _repoMock.Setup(r => r.UpdateWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        await _svc.UpdateAsync(userId, txnId, new UpdateTransactionDto
        {
            Amount = 75m,
            Category = "Dining",
            Date = new DateTime(2026, 06, 01, 0, 0, 0, DateTimeKind.Utc)
        });

        _repoMock.Verify(r => r.UpdateWithOutboxAsync(
            It.Is<Transaction>(t => t.Category == "Dining" && t.Amount.Amount == 75m),
            It.Is<OutboxEvent>(e =>
                e.EventType == OutboxEventType.TransactionUpdated &&
                e.Payload.Contains("\"PreviousCategory\":\"Food\"") &&
                e.Payload.Contains("\"Category\":\"Dining\"")),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateAsync_ThrowsKeyNotFound_WhenMissing()
    {
        _repoMock.Setup(r => r.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction?)null);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => _svc.UpdateAsync(Guid.NewGuid(), Guid.NewGuid(), new UpdateTransactionDto()));
    }

    [Fact]
    public async Task DeleteAsync_CallsDelete()
    {
        var userId = Guid.NewGuid();
        var txnId = Guid.NewGuid();
        var existing = new Transaction
        {
            Id = txnId, UserId = userId, Type = TransactionType.Expense,
            Amount = new Money(50, "USD"), Category = "Food", Date = DateTime.UtcNow
        };

        _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);
        _repoMock.Setup(r => r.DeleteWithOutboxAsync(
                userId,
                txnId,
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        await _svc.DeleteAsync(userId, txnId);

        _repoMock.Verify(r => r.DeleteWithOutboxAsync(
            userId,
            txnId,
            It.IsAny<OutboxEvent>(),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DeleteAsync_WritesProjectionAwareDeleteEvent()
    {
        var userId = Guid.NewGuid();
        var txnId = Guid.NewGuid();
        var existing = new Transaction
        {
            Id = txnId,
            UserId = userId,
            Type = TransactionType.Expense,
            Amount = new Money(50, "USD"),
            Category = "Food",
            Date = new DateTime(2026, 05, 10, 0, 0, 0, DateTimeKind.Utc)
        };

        _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);
        _repoMock.Setup(r => r.DeleteWithOutboxAsync(userId, txnId, It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        await _svc.DeleteAsync(userId, txnId);

        _repoMock.Verify(r => r.DeleteWithOutboxAsync(
            userId,
            txnId,
            It.Is<OutboxEvent>(e =>
                e.EventType == OutboxEventType.TransactionDeleted &&
                e.Payload.Contains("\"PreviousCategory\":\"Food\"") &&
                e.Payload.Contains("\"PreviousCurrencyCode\":\"USD\"")),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateRegretLevelAsync_DelegatesToRepo()
    {
        var txnId = Guid.NewGuid();

        var userId = Guid.NewGuid();
        _repoMock.Setup(r => r.UpdateRegretLevelAsync(userId, txnId, RegretLevel.Regret, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        await _svc.UpdateRegretLevelAsync(userId, txnId, RegretLevel.Regret);

        _repoMock.Verify(r => r.UpdateRegretLevelAsync(userId, txnId, RegretLevel.Regret, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ListAsync_ReturnsPagedResult()
    {
        var userId = Guid.NewGuid();
        var items = new List<Transaction>
        {
            new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(10, "USD"), Category = "Food" },
            new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(20, "USD"), Category = "Food" }
        };

        _repoMock.Setup(r => r.QueryByUserAsync(userId, null, null, null, 10, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync((items.AsReadOnly(), (string?)null));

        var result = await _svc.ListAsync(userId, 1, 10);

        Assert.Equal(2, result.Items.Count);
        Assert.Equal(1, result.Page);
        Assert.Equal(10, result.PageSize);
    }

    [Fact]
    public async Task CreateAsync_FetchesExchangeRate_WhenCurrencyDiffersFromBase()
    {
        var userId = Guid.NewGuid();
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 100m,
            CurrencyCode = "EUR",
            BaseCurrencyCode = "USD",
            Category = "Travel",
            Date = DateTime.UtcNow
        };

        _fxMock.Setup(f => f.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()))
            .ReturnsAsync(1.08m);
        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        var result = await _svc.CreateAsync(userId, dto);

        Assert.Equal(1.08m, result.Amount.ExchangeRateToBase);
        _fxMock.Verify(f => f.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_UsesOverride_WhenExchangeRateOverrideProvided()
    {
        var userId = Guid.NewGuid();
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 100m,
            CurrencyCode = "EUR",
            BaseCurrencyCode = "USD",
            ExchangeRateOverride = 0.92m,
            Category = "Travel",
            Date = DateTime.UtcNow
        };

        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        var result = await _svc.CreateAsync(userId, dto);

        Assert.Equal(0.92m, result.Amount.ExchangeRateToBase);
        _fxMock.Verify(f => f.GetRateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task CreateAsync_CreatesRecurringSchedule_WhenRecurringOptionsAreProvided()
    {
        var userId = Guid.NewGuid();
        var transactionDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 1000m,
            CurrencyCode = "PHP",
            Category = "Subscriptions",
            Counterparty = "Netflix",
            Date = transactionDate,
            Recurring = new RecurringOptionsDto
            {
                Cadence = RecurringCadence.Monthly,
                EndDate = transactionDate.AddMonths(6)
            }
        };

        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);
        _recurringScheduleServiceMock
            .Setup(s => s.CreateAsync(userId, It.IsAny<CreateRecurringScheduleDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RecurringSchedule
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = TransactionType.Expense,
                Amount = new Money(1000m, "PHP"),
                Category = "Subscriptions",
                Counterparty = "Netflix",
                StartDate = transactionDate,
                Cadence = RecurringCadence.Monthly,
                NextRunAt = transactionDate,
                EndDate = transactionDate.AddMonths(6),
                IsActive = true,
            });

        await _svc.CreateAsync(userId, dto);

        _recurringScheduleServiceMock.Verify(s => s.CreateAsync(
            userId,
            It.Is<CreateRecurringScheduleDto>(r =>
                r.Cadence == RecurringCadence.Monthly &&
                r.StartDate == transactionDate &&
                r.EndDate == transactionDate.AddMonths(6) &&
                r.Counterparty == "Netflix"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_FamilyScope_AddsFamilyMetadataToTransactionAndOutboxPayload()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 280m,
            CurrencyCode = "PHP",
            Category = "Dining",
            Counterparty = "Starbucks",
            Date = DateTime.UtcNow,
            Scope = RecordScope.Family,
            FamilySpaceId = familySpaceId
        };
        OutboxEvent? capturedEvent = null;

        _familyRepoMock.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });
        _repoMock.Setup(r => r.AddWithOutboxAsync(
                It.IsAny<Transaction>(),
                It.IsAny<OutboxEvent>(),
                It.IsAny<CancellationToken>()))
            .Callback<Transaction, OutboxEvent, CancellationToken>((_, evt, _) => capturedEvent = evt)
            .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

        var result = await _svc.CreateAsync(userId, dto);

        Assert.Equal(RecordScope.Family, result.Scope);
        Assert.Equal(familySpaceId, result.FamilySpaceId);
        Assert.Equal(userId, result.SharedByUserId);
        Assert.NotNull(result.SharedAt);
        Assert.Contains("\"Scope\":\"Family\"", capturedEvent!.Payload);
        Assert.Contains(familySpaceId.ToString(), capturedEvent.Payload);
    }

    [Fact]
    public async Task CreateAsync_FamilyScopeRejectsUserOutsideFamilySpace()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _familyRepoMock.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = Guid.NewGuid(),
                Role = FamilyMemberRole.Contributor
            });

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            _svc.CreateAsync(userId, new CreateTransactionDto
            {
                Type = TransactionType.Expense,
                Amount = 280m,
                CurrencyCode = "PHP",
                Category = "Dining",
                Date = DateTime.UtcNow,
                Scope = RecordScope.Family,
                FamilySpaceId = familySpaceId
            }));

        Assert.Equal("You do not belong to that Family Space.", error.Message);
        _repoMock.Verify(r => r.AddWithOutboxAsync(
            It.IsAny<Transaction>(),
            It.IsAny<OutboxEvent>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }
}
