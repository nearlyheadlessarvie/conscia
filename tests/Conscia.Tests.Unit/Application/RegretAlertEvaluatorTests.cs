using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Application.Services;
using Conscia.Application.Triggers;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class RegretAlertEvaluatorTests
{
    [Fact]
    public async Task RepeatedRegretCategoryEvaluator_ReturnsAlertForHighRegretCategory()
    {
        var userId = Guid.NewGuid();
        var patterns = new Mock<IPurchasePatternRepository>();
        patterns.Setup(x => x.GetCategoriesAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryPattern>
            {
                new()
                {
                    UserId = userId,
                    Category = "Dining",
                    RegretRate = 0.67,
                    TransactionCount = 6,
                    RegrettedSpend = 5400m,
                    UpdatedAt = DateTime.UtcNow
                },
                new()
                {
                    UserId = userId,
                    Category = "Shopping",
                    RegretRate = 0.30,
                    TransactionCount = 8,
                    RegrettedSpend = 3000m,
                    UpdatedAt = DateTime.UtcNow
                },
            });

        var evaluator = new RepeatedRegretCategoryEvaluator(patterns.Object);

        var alerts = await evaluator.EvaluateAsync(userId);

        var alert = Assert.Single(alerts);
        Assert.Equal("RepeatedRegretCategory", alert.TriggerName);
        Assert.Equal("repeated-regret-category-dining", alert.AlertKey);
        Assert.Equal("/insights/categories/Dining", alert.ActionRoute);
        Assert.Equal("See category trend", alert.ActionLabel);
        Assert.Contains("Dining", alert.Title);
    }

    [Fact]
    public async Task RepeatedRegretCounterpartyEvaluator_ReturnsAlertForFrequentMerchantRegret()
    {
        var userId = Guid.NewGuid();
        var patterns = new Mock<IPurchasePatternRepository>();
        patterns.Setup(x => x.GetMerchantsAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<MerchantPattern>
            {
                new()
                {
                    UserId = userId,
                    Merchant = "Late Night Delivery",
                    VisitCount = 4,
                    RegretCount = 3,
                    RegretRate = 0.75,
                    LastVisitDate = "2026-05-07",
                    UpdatedAt = DateTime.UtcNow
                }
            });

        var evaluator = new RepeatedRegretCounterpartyEvaluator(patterns.Object);

        var alerts = await evaluator.EvaluateAsync(userId);

        var alert = Assert.Single(alerts);
        Assert.Equal("RepeatedRegretCounterparty", alert.TriggerName);
        Assert.Equal("repeated-regret-counterparty-late-night-delivery", alert.AlertKey);
        Assert.Equal("/insights/merchants/Late%20Night%20Delivery", alert.ActionRoute);
        Assert.Equal("See merchant trend", alert.ActionLabel);
        Assert.Contains("Late Night Delivery", alert.Message);
    }

    [Fact]
    public async Task NotSureStreakEvaluator_ReturnsAlertWhenRecentStreakIsUncertain()
    {
        var userId = Guid.NewGuid();
        var txRepo = new Mock<ITransactionRepository>();
        txRepo.Setup(x => x.GetByUserIdAndDateRangeAsync(
                userId,
                It.IsAny<DateTime>(),
                It.IsAny<DateTime>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction>
            {
                Expense("Dining", "Cafe Uno", RegretLevel.NotSure),
                Expense("Shopping", "Mini Mart", RegretLevel.NotSure),
                Expense("Gaming", "Steam", RegretLevel.NotSure),
                Expense("Transport", "Grab", RegretLevel.WorthIt),
            });

        var evaluator = new NotSureStreakEvaluator(txRepo.Object);

        var alerts = await evaluator.EvaluateAsync(userId);

        var alert = Assert.Single(alerts);
        Assert.Equal("NotSureStreak", alert.TriggerName);
        Assert.Equal("not-sure-streak", alert.AlertKey);
        Assert.Equal("/insights", alert.ActionRoute);
        Assert.Equal("Open insights", alert.ActionLabel);
        Assert.Contains("not sure", alert.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ReflectionFollowUpEvaluator_ReturnsAlertForRecentUnreflectedExpense()
    {
        var userId = Guid.NewGuid();
        var tx = Expense("Dining", "Corner Cafe", RegretLevel.Regret);
        var txRepo = new Mock<ITransactionRepository>();
        var aiRepo = new Mock<IAIInteractionRepository>();

        txRepo.Setup(x => x.GetByUserIdAndDateRangeAsync(
                userId,
                It.IsAny<DateTime>(),
                It.IsAny<DateTime>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction> { tx });
        aiRepo.Setup(x => x.GetByTransactionIdAsync(tx.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AIInteraction?)null);

        var evaluator = new ReflectionFollowUpEvaluator(txRepo.Object, aiRepo.Object);

        var alerts = await evaluator.EvaluateAsync(userId);

        var alert = Assert.Single(alerts);
        Assert.Equal("ReflectionFollowUp", alert.TriggerName);
        Assert.Equal($"reflection-follow-up-{tx.Id:D}", alert.AlertKey);
        Assert.Equal($"/transactions/{tx.Id}", alert.ActionRoute);
        Assert.Equal("Reflect now", alert.ActionLabel);
    }

    [Fact]
    public async Task AlertService_SortsAlertsByPriorityDescending()
    {
        var highPriority = new Mock<ITriggerEvaluator>();
        highPriority.SetupGet(x => x.TriggerName).Returns("High");
        highPriority.Setup(x => x.EvaluateAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<InAppAlert>
            {
                new()
                {
                    AlertKey = "high",
                    TriggerName = "High",
                    Title = "High",
                    Message = "High",
                    Priority = 90,
                    CreatedAt = new DateTime(2026, 5, 8, 10, 0, 0, DateTimeKind.Utc)
                }
            });

        var lowPriority = new Mock<ITriggerEvaluator>();
        lowPriority.SetupGet(x => x.TriggerName).Returns("Low");
        lowPriority.Setup(x => x.EvaluateAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<InAppAlert>
            {
                new()
                {
                    AlertKey = "low",
                    TriggerName = "Low",
                    Title = "Low",
                    Message = "Low",
                    Priority = 20,
                    CreatedAt = new DateTime(2026, 5, 8, 11, 0, 0, DateTimeKind.Utc)
                }
            });

        var service = new AlertService(new[] { lowPriority.Object, highPriority.Object });

        var alerts = await service.ListAlertsAsync(Guid.NewGuid());

        Assert.Collection(alerts,
            first => Assert.Equal("high", first.AlertKey),
            second => Assert.Equal("low", second.AlertKey));
    }

    private static Transaction Expense(string category, string counterparty, RegretLevel? regretLevel) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Type = TransactionType.Expense,
            Category = category,
            Counterparty = counterparty,
            Amount = new Money(500m, "PHP"),
            Date = DateTime.UtcNow.AddHours(-2),
            CreatedAt = DateTime.UtcNow.AddHours(-2),
            RegretLevel = regretLevel
        };
}
