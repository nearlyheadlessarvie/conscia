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
    private readonly Mock<ILogger<OutboxProcessor>> _loggerMock = new();

    private OutboxProcessor CreateProcessor()
    {
        var services = new ServiceCollection();
        services.AddScoped(_ => _outboxRepoMock.Object);
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
    public async Task ProcessesTransactionCreatedWithoutBudgetMutation()
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
                    Amount = 10m,
                    CurrencyCode = "USD",
                    Category = "Travel"
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
}
