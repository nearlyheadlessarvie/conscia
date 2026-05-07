using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class OutboxProcessorTests
{
    private readonly Mock<IOutboxEventRepository> _outboxRepoMock = new();
    private readonly Mock<IBudgetRepository> _budgetRepoMock = new();
    private readonly Mock<ILogger<OutboxProcessor>> _loggerMock = new();

    private OutboxProcessor CreateProcessor()
    {
        var services = new ServiceCollection();
        services.AddScoped(_ => _outboxRepoMock.Object);
        services.AddScoped(_ => _budgetRepoMock.Object);
        var sp = services.BuildServiceProvider();
        var scopeFactory = sp.GetRequiredService<IServiceScopeFactory>();
        return new OutboxProcessor(scopeFactory, _loggerMock.Object);
    }

    [Fact]
    public async Task ProcessesPendingEvents_AndIncrementsBudget()
    {
        var userId = Guid.NewGuid();
        var budgetId = Guid.NewGuid();
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
                    UserId = userId,
                    Amount = 42.50m,
                    CurrencyCode = "USD",
                    Category = "Food"
                }),
                CreatedAt = DateTime.UtcNow
            }
        };

        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(events.AsReadOnly());

        _budgetRepoMock.Setup(r => r.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Id = budgetId, UserId = userId, Category = "Food", MonthlyLimit = 500 }
            });

        _budgetRepoMock.Setup(r => r.IncrementCurrentSpendAsync(budgetId, 42.50m, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _outboxRepoMock.Setup(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

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

        _budgetRepoMock.Verify(r => r.IncrementCurrentSpendAsync(budgetId, 42.50m, It.IsAny<CancellationToken>()), Times.AtLeastOnce);
        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.Is<OutboxEvent>(e => e.Id == eventId), It.IsAny<CancellationToken>()), Times.AtLeastOnce);
    }

    [Fact]
    public async Task SkipsBudgetIncrement_WhenNoBudgetMatchesCategory()
    {
        var userId = Guid.NewGuid();
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
                    UserId = userId,
                    Amount = 10m,
                    CurrencyCode = "USD",
                    Category = "Travel"
                }),
                CreatedAt = DateTime.UtcNow
            }
        };

        _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(events.AsReadOnly());

        _budgetRepoMock.Setup(r => r.ListByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Budget>
            {
                new() { Id = Guid.NewGuid(), UserId = userId, Category = "Food", MonthlyLimit = 500 }
            });

        _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _outboxRepoMock.Setup(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

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

        _budgetRepoMock.Verify(r => r.IncrementCurrentSpendAsync(It.IsAny<Guid>(), It.IsAny<decimal>(), It.IsAny<CancellationToken>()), Times.Never);
        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.Is<OutboxEvent>(e => e.Id == eventId), It.IsAny<CancellationToken>()), Times.AtLeastOnce);
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
        var userId = Guid.NewGuid();

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
                        UserId = userId,
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

        _budgetRepoMock.Verify(r => r.IncrementCurrentSpendAsync(It.IsAny<Guid>(), It.IsAny<decimal>(), It.IsAny<CancellationToken>()), Times.Never);
        _outboxRepoMock.Verify(r => r.MarkProcessedAsync(It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}
