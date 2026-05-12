using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class OutboxProcessorTests
{
    private readonly Mock<IOutboxEventRepository> _outboxRepoMock = new();
    private readonly Mock<IMonthlyCategorySpendRepository> _projectionRepoMock = new();
    private readonly Mock<ITransactionRepository> _transactionRepoMock = new();
    private readonly Mock<IUserRepository> _userRepoMock = new();
    private readonly Mock<IInAppAlertRepository> _alertRepoMock = new();
    private readonly Mock<IPushNotificationSender> _pushSenderMock = new();
    private readonly Mock<ILogger<OutboxProcessor>> _loggerMock = new();

    private OutboxProcessor CreateProcessor()
    {
        var services = new ServiceCollection();
        services.AddScoped(_ => _outboxRepoMock.Object);
        services.AddScoped(_ => _projectionRepoMock.Object);
        services.AddScoped(_ => _transactionRepoMock.Object);
        services.AddScoped(_ => _userRepoMock.Object);
        services.AddScoped(_ => _alertRepoMock.Object);
        services.AddScoped(_ => _pushSenderMock.Object);
        var sp = services.BuildServiceProvider();
        var scopeFactory = sp.GetRequiredService<IServiceScopeFactory>();
        return new OutboxProcessor(scopeFactory, _loggerMock.Object);
    }

    [Fact]
    public async Task ProcessesPendingEvents_AndMarksProcessed()
    {
        var eventId = Guid.NewGuid();

        var events = new List<OutboxEvent>
        {
            new()
            {
                Id = eventId,
                AggregateId = Guid.NewGuid(),
                EventType = OutboxEventType.TransactionCreated,
                Payload = System.Text.Json.JsonSerializer.Serialize(new
                {
                    TransactionId = Guid.NewGuid(),
                    UserId = Guid.NewGuid(),
                    Amount = 42.50m,
                    CurrencyCode = "USD",
                    Category = "Food"
                }),
                CreatedAt = DateTime.UtcNow
            }
        };

        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(events.AsReadOnly());

        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _outboxRepoMock.Setup(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        _projectionRepoMock.Setup(r => r.ListRecentMonthsAsync(
                It.IsAny<Guid>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<MonthlyCategorySpend>());

        var processor = CreateProcessor();
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

        try
        {
            await processor.StartAsync(cts.Token);
            await Task.Delay(1000, cts.Token);
        }
        catch (OperationCanceledException) { }
        finally
        {
            await processor.StopAsync(CancellationToken.None);
        }

        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.Is<OutboxEvent>(e => e.Id == eventId), It.IsAny<CancellationToken>()), Times.AtLeastOnce);
    }

    [Fact]
    public async Task ProcessesTransactionCreatedEvent_UpdatesMonthlyProjection()
    {
        var eventId = Guid.NewGuid();
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        var events = new List<OutboxEvent>
        {
            new()
            {
                Id = eventId,
                AggregateId = Guid.NewGuid(),
                EventType = OutboxEventType.TransactionCreated,
                Payload = System.Text.Json.JsonSerializer.Serialize(new
                {
                    TransactionId = Guid.NewGuid(),
                    UserId = userId,
                    Type = "Expense",
                    Category = "Dining",
                    Amount = 120m,
                    CurrencyCode = "PHP",
                    TransactionDate = DateTime.Parse("2026-05-10T00:00:00Z")
                }),
                CreatedAt = DateTime.UtcNow
            }
        };

        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(events.AsReadOnly());

        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _outboxRepoMock.Setup(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        _projectionRepoMock.Setup(r => r.ListRecentMonthsAsync(
                It.IsAny<Guid>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<MonthlyCategorySpend>());

        var processor = CreateProcessor();
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

        try
        {
            await processor.StartAsync(cts.Token);
            await Task.Delay(1000, cts.Token);
        }
        catch (OperationCanceledException) { }
        finally
        {
            await processor.StopAsync(CancellationToken.None);
        }

        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.Is<OutboxEvent>(e => e.Id == eventId), It.IsAny<CancellationToken>()), Times.AtLeastOnce);
        _projectionRepoMock.Verify(r => r.UpsertAsync(
            It.Is<MonthlyCategorySpend>(p =>
                p.UserId == userId &&
                p.MonthKey == "2026-05" &&
                p.NormalizedCategory == "dining"),
            It.IsAny<CancellationToken>()), Times.AtLeastOnce);
    }

    [Fact]
    public async Task NoPendingEvents_DoesNothing()
    {
        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<OutboxEvent>().AsReadOnly());

        var processor = CreateProcessor();
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

        try
        {
            await processor.StartAsync(cts.Token);
            await Task.Delay(1000, cts.Token);
        }
        catch (OperationCanceledException) { }
        finally
        {
            await processor.StopAsync(CancellationToken.None);
        }

        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task SkipsDispatch_WhenPendingEventWasAlreadyClaimed()
    {
        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<OutboxEvent>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    AggregateId = Guid.NewGuid(),
                    EventType = OutboxEventType.TransactionCreated,
                    Payload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        TransactionId = Guid.NewGuid(),
                        UserId = Guid.NewGuid(),
                        Amount = 15m,
                        CurrencyCode = "USD",
                        Category = "Food"
                    }),
                    CreatedAt = DateTime.UtcNow
                }
            }.AsReadOnly());

        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var processor = CreateProcessor();
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

        try
        {
            await processor.StartAsync(cts.Token);
            await Task.Delay(1000, cts.Token);
        }
        catch (OperationCanceledException) { }
        finally
        {
            await processor.StopAsync(CancellationToken.None);
        }

        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task RepairProjectionAsync_OverwritesDriftedMonthFromSourceTotals()
    {
        var userId = Guid.NewGuid();
        var monthKey = "2026-05";
        var monthStart = new DateTime(2026, 05, 01, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

        _transactionRepoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, monthStart, monthEnd, It.IsAny<CancellationToken>()))
            .ReturnsAsync(
            [
                new Transaction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = TransactionType.Expense,
                    Category = "Dining",
                    Amount = new Money(1200m, "PHP"),
                    Date = new DateTime(2026, 05, 10, 0, 0, 0, DateTimeKind.Utc)
                }
            ]);

        var processor = CreateProcessor();

        await processor.RepairProjectionAsync(userId, [monthKey], CancellationToken.None);

        _projectionRepoMock.Verify(r => r.UpsertAsync(
            It.Is<MonthlyCategorySpend>(p =>
                p.UserId == userId &&
                p.MonthKey == monthKey &&
                p.Category == "Dining" &&
                p.NormalizedCategory == "dining" &&
                p.TotalExpenseAmount == 1200m &&
                p.TransactionCount == 1),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ProcessBatchAsync_FamilyInviteCreated_NotifiesRegisteredInvitee()
    {
        var invitedUserId = Guid.NewGuid();
        var inviteId = Guid.NewGuid();
        var evt = new OutboxEvent
        {
            Id = Guid.NewGuid(),
            AggregateId = inviteId,
            EventType = OutboxEventType.FamilyInviteCreated,
            Payload = System.Text.Json.JsonSerializer.Serialize(new
            {
                InviteId = inviteId,
                Email = "wife@example.com",
                FamilySpaceName = "Santos Household",
                InvitedByUserId = Guid.NewGuid()
            }),
            CreatedAt = DateTime.UtcNow
        };

        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync([evt]);
        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(evt, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _userRepoMock.Setup(r => r.GetByEmailAsync("wife@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = invitedUserId, Email = "wife@example.com" });

        await CreateProcessor().ProcessBatchAsync(CancellationToken.None);

        _alertRepoMock.Verify(r => r.AddAsync(
            It.Is<Conscia.Application.Models.InAppAlert>(alert =>
                alert.UserId == invitedUserId &&
                alert.AlertKey == $"family-invite:{inviteId}" &&
                alert.Title == "Family invite" &&
                alert.ActionRoute == "/settings/family-space/invites"),
            It.IsAny<CancellationToken>()), Times.Once);
        _pushSenderMock.Verify(s => s.SendToUserAsync(
            invitedUserId,
            "Family invite",
            "You were invited to Santos Household.",
            "/settings/family-space/invites",
            It.IsAny<CancellationToken>()), Times.Once);
        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(evt, It.IsAny<CancellationToken>()), Times.Once);
    }
}
