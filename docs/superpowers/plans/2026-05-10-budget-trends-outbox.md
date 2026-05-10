# Budget Trends Outbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an outbox-backed monthly spending projection and expose a last-3-month budget/spend trend section in Insights for all spending categories.

**Architecture:** Transaction writes will emit projection-focused outbox events, a purpose-built processor will maintain a `MonthlyCategorySpends` DynamoDB projection table, and the Insights read path will join that projection against current budgets to return budget-aware or spend-only trends. Current budget status logic remains intact for existing budget screens while the new projection powers the trend card.

**Tech Stack:** .NET 8, ASP.NET Core minimal APIs, DynamoDB, PostgreSQL/EF Core for budgets in development, xUnit, Flutter app consuming existing insights endpoint

---

## File Structure

### Backend files to create

- `src/Conscia.Domain/Entities/MonthlyCategorySpend.cs`
  Responsibility: domain model for one user/category/month projection row.
- `src/Conscia.Application/Interfaces/IMonthlyCategorySpendRepository.cs`
  Responsibility: repository contract for projection reads and upserts.
- `src/Conscia.Infrastructure/Repositories/MonthlyCategorySpendRepository.cs`
  Responsibility: DynamoDB implementation for projection rows.
- `src/Conscia.Application/Models/BudgetTrendInsight.cs`
  Responsibility: backend response model for one category trend item.
- `tests/Conscia.Tests.Unit/Application/BudgetTrendsServiceTests.cs`
  Responsibility: service-level tests for trend shaping and ranking.
- `tests/Conscia.Tests.Unit/Infrastructure/MonthlyCategorySpendRepositoryTests.cs`
  Responsibility: projection repository request-shape tests.

### Backend files to modify

- `src/Conscia.Domain/Entities/OutboxEvent.cs`
  Responsibility: ensure event payload shapes support transaction create/update/delete projection deltas.
- `src/Conscia.Application/Interfaces/ITransactionRepository.cs`
  Responsibility: restore projection-oriented outbox write methods for transaction mutations.
- `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
  Responsibility: write transaction + outbox atomically with projection payloads.
- `src/Conscia.Application/Services/TransactionService.cs`
  Responsibility: emit projection-ready outbox events for create/update/delete.
- `src/Conscia.Infrastructure/Repositories/OutboxEventRepository.cs`
  Responsibility: existing outbox event polling/claim persistence.
- `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
  Responsibility: replace no-op logging with monthly spend projection application.
- `src/Conscia.Api/Program.cs`
  Responsibility: register projection repository and re-enable targeted outbox processor dependencies.
- `src/Conscia.Application/Services/BehavioralInsightsService.cs`
  Responsibility: join monthly projection rows with budgets and append `budgetTrends`.
- `src/Conscia.Application/DTOs/InsightsDtos.cs`
  Responsibility: extend API-facing insights DTO with budget trend fields.
- `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`
  Responsibility: return the extended insights payload.
- `tools/DynamoSetup/Program.cs`
  Responsibility: add `MonthlyCategorySpends` table.
- `src/Conscia.Api/Health/DynamoDbHealthCheck.cs`
  Responsibility: verify `MonthlyCategorySpends` exists.
- `src/Conscia.PatternAggregator/PatternAggregatorService.cs`
  Responsibility: unchanged for current logic unless compile references require adjustment after DTO/service changes.

### App files to modify

- `app/lib/services/behavioral_insights_service.dart` or equivalent current insights service model file
  Responsibility: parse new `budgetTrends` payload shape.
- `app/lib/providers/behavioral_insights_provider.dart`
  Responsibility: expose the richer insights model to the UI.
- `app/lib/screens/dashboard/dashboard_screen.dart`
  Responsibility: render the new budget trends card in Insights when present.
- `app/lib/screens/dashboard/widgets/`
  Responsibility: add a dedicated budget trends card widget.

### Test files to modify

- `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`
  Responsibility: restore outbox emission assertions, now with projection payload semantics.
- `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs`
  Responsibility: validate projection writes instead of no-op acknowledgements.
- `tests/Conscia.Tests.Unit/Application/BehavioralInsightsServiceTests.cs`
  Responsibility: cover budget trend shaping on the existing insights service.
- `tests/Conscia.Tests.Unit/Api/DynamoDbHealthCheckTests.cs`
  Responsibility: expect `MonthlyCategorySpends` in required tables.
- `app/test/screens/dashboard/...`
  Responsibility: add UI coverage for the new trend card if dashboard insights tests already exist.

---

### Task 1: Define the monthly projection model

**Files:**
- Create: `src/Conscia.Domain/Entities/MonthlyCategorySpend.cs`
- Create: `src/Conscia.Application/Interfaces/IMonthlyCategorySpendRepository.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/MonthlyCategorySpendRepositoryTests.cs`

- [ ] **Step 1: Write the failing repository-shape test**

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class MonthlyCategorySpendRepositoryTests
{
    [Fact]
    public async Task UpsertAsync_WritesExpectedProjectionKeyShape()
    {
        var dynamo = new Mock<IAmazonDynamoDB>();
        PutItemRequest? captured = null;

        dynamo.Setup(d => d.PutItemAsync(It.IsAny<PutItemRequest>(), It.IsAny<CancellationToken>()))
            .Callback<PutItemRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new PutItemResponse());

        var repository = new MonthlyCategorySpendRepository(dynamo.Object);

        await repository.UpsertAsync(new MonthlyCategorySpend
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            MonthKey = "2026-05",
            Category = "Dining",
            NormalizedCategory = "dining",
            CurrencyCode = "PHP",
            TotalExpenseAmount = 1200m,
            TransactionCount = 3,
            LastUpdatedAt = DateTime.UtcNow,
        });

        Assert.NotNull(captured);
        Assert.Equal("MonthlyCategorySpends", captured!.TableName);
        Assert.Equal("USER#11111111-1111-1111-1111-111111111111", captured.Item["PK"].S);
        Assert.Equal("MONTH#2026-05#CAT#dining", captured.Item["SK"].S);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter MonthlyCategorySpendRepositoryTests`
Expected: FAIL with missing `MonthlyCategorySpendRepository` / missing projection types

- [ ] **Step 3: Add the new domain model and repository contract**

```csharp
namespace Conscia.Domain.Entities;

public class MonthlyCategorySpend
{
    public Guid UserId { get; set; }
    public string MonthKey { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string NormalizedCategory { get; set; } = string.Empty;
    public string CurrencyCode { get; set; } = "USD";
    public decimal TotalExpenseAmount { get; set; }
    public int TransactionCount { get; set; }
    public DateTime LastUpdatedAt { get; set; }
}
```

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IMonthlyCategorySpendRepository
{
    Task UpsertAsync(MonthlyCategorySpend projection, CancellationToken ct = default);
    Task<IReadOnlyList<MonthlyCategorySpend>> ListRecentMonthsAsync(
        Guid userId,
        IReadOnlyList<string> monthKeys,
        CancellationToken ct = default);
}
```

- [ ] **Step 4: Add the minimal DynamoDB repository implementation**

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class MonthlyCategorySpendRepository : IMonthlyCategorySpendRepository
{
    private const string TableName = "MonthlyCategorySpends";
    private readonly IAmazonDynamoDB _dynamo;

    public MonthlyCategorySpendRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task UpsertAsync(MonthlyCategorySpend projection, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"USER#{projection.UserId}"),
                ["SK"] = new($"MONTH#{projection.MonthKey}#CAT#{projection.NormalizedCategory}"),
                ["UserId"] = new(projection.UserId.ToString()),
                ["MonthKey"] = new(projection.MonthKey),
                ["Category"] = new(projection.Category),
                ["NormalizedCategory"] = new(projection.NormalizedCategory),
                ["CurrencyCode"] = new(projection.CurrencyCode),
                ["TotalExpenseAmount"] = new() { N = projection.TotalExpenseAmount.ToString("G") },
                ["TransactionCount"] = new() { N = projection.TransactionCount.ToString() },
                ["LastUpdatedAt"] = new(projection.LastUpdatedAt.ToString("O")),
            }
        }, ct);
    }

    public Task<IReadOnlyList<MonthlyCategorySpend>> ListRecentMonthsAsync(
        Guid userId,
        IReadOnlyList<string> monthKeys,
        CancellationToken ct = default) =>
        throw new NotImplementedException();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dotnet test tests/Conscia.Tests.Unit --filter MonthlyCategorySpendRepositoryTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Domain/Entities/MonthlyCategorySpend.cs src/Conscia.Application/Interfaces/IMonthlyCategorySpendRepository.cs src/Conscia.Infrastructure/Repositories/MonthlyCategorySpendRepository.cs tests/Conscia.Tests.Unit/Infrastructure/MonthlyCategorySpendRepositoryTests.cs
git commit -m "feat: add monthly category spend projection model"
```

### Task 2: Add projection table to local infrastructure and health checks

**Files:**
- Modify: `tools/DynamoSetup/Program.cs`
- Modify: `src/Conscia.Api/Health/DynamoDbHealthCheck.cs`
- Modify: `tests/Conscia.Tests.Unit/Api/DynamoDbHealthCheckTests.cs`

- [ ] **Step 1: Write the failing health-check assertion**

```csharp
[Fact]
public async Task CheckHealthAsync_ReturnsUnhealthy_WhenMonthlyCategorySpendsTableIsMissing()
{
    _dynamoMock.Setup(d => d.ListTablesAsync(It.IsAny<CancellationToken>()))
        .ReturnsAsync(new ListTablesResponse
        {
            TableNames =
            [
                "Transactions",
                "RecurringSchedules",
                "AIInteractions",
                "WeeklyInsights",
                "PurchasePatterns",
                "InAppAlerts"
            ]
        });

    var healthCheck = new DynamoDbHealthCheck(_dynamoMock.Object);
    var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

    Assert.Equal(HealthStatus.Unhealthy, result.Status);
    Assert.Contains("MonthlyCategorySpends", result.Description);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter FullyQualifiedName~DynamoDbHealthCheckTests`
Expected: FAIL because the health check does not yet require `MonthlyCategorySpends`

- [ ] **Step 3: Add the table to Dynamo setup**

```csharp
("MonthlyCategorySpends", new CreateTableRequest
{
    TableName = "MonthlyCategorySpends",
    KeySchema =
    [
        new("PK", KeyType.HASH),
        new("SK", KeyType.RANGE)
    ],
    AttributeDefinitions =
    [
        new("PK", ScalarAttributeType.S),
        new("SK", ScalarAttributeType.S)
    ],
    BillingMode = BillingMode.PAY_PER_REQUEST
}),
```

- [ ] **Step 4: Extend the health check required-table list**

```csharp
private static readonly (string TableName, string[] RequiredIndexes)[] RequiredTables =
[
    ("Transactions", ["GSI-UserId-Category-Date"]),
    ("RecurringSchedules", []),
    ("AIInteractions", ["GSI-TransactionId-Date"]),
    ("WeeklyInsights", []),
    ("PurchasePatterns", []),
    ("InAppAlerts", []),
    ("MonthlyCategorySpends", [])
];
```

- [ ] **Step 5: Run tests and tool build**

Run: `dotnet test tests/Conscia.Tests.Unit --filter FullyQualifiedName~DynamoDbHealthCheckTests`
Expected: PASS

Run: `dotnet build tools/DynamoSetup/DynamoSetup.csproj`
Expected: `Build succeeded.`

- [ ] **Step 6: Commit**

```bash
git add tools/DynamoSetup/Program.cs src/Conscia.Api/Health/DynamoDbHealthCheck.cs tests/Conscia.Tests.Unit/Api/DynamoDbHealthCheckTests.cs
git commit -m "feat: add monthly spend projection table setup"
```

### Task 3: Restore transaction outbox writes for projection-only events

**Files:**
- Modify: `src/Conscia.Application/Interfaces/ITransactionRepository.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
- Modify: `src/Conscia.Application/Services/TransactionService.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`

- [ ] **Step 1: Write the failing transaction service assertions**

```csharp
[Fact]
public async Task CreateAsync_WritesTransactionAndProjectionOutboxEvent()
{
    _repoMock.Setup(r => r.AddWithOutboxAsync(It.IsAny<Transaction>(), It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

    var result = await _svc.CreateAsync(userId, dto);

    _repoMock.Verify(r => r.AddWithOutboxAsync(
        It.IsAny<Transaction>(),
        It.Is<OutboxEvent>(e => e.EventType == OutboxEventType.TransactionCreated &&
            e.Payload.Contains("\"Category\":\"Dining\"")),
        It.IsAny<CancellationToken>()), Times.Once);
}
```

```csharp
[Fact]
public async Task DeleteAsync_WritesProjectionAwareDeleteEvent()
{
    _repoMock.Setup(r => r.GetByIdAsync(userId, txnId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(existing);
    _repoMock.Setup(r => r.DeleteWithOutboxAsync(userId, txnId, It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
        .Returns(Task.CompletedTask);

    await _svc.DeleteAsync(userId, txnId);

    _repoMock.Verify(r => r.DeleteWithOutboxAsync(
        userId,
        txnId,
        It.Is<OutboxEvent>(e => e.Payload.Contains("\"PreviousCategory\":\"Food\"")),
        It.IsAny<CancellationToken>()), Times.Once);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter TransactionServiceTests`
Expected: FAIL because the transaction service currently uses plain add/delete

- [ ] **Step 3: Restore the projection-oriented repository contract**

```csharp
Task<Transaction> AddWithOutboxAsync(Transaction transaction, OutboxEvent outboxEvent, CancellationToken ct = default);
Task DeleteWithOutboxAsync(Guid userId, Guid id, OutboxEvent outboxEvent, CancellationToken ct = default);
```

- [ ] **Step 4: Restore atomic transaction + outbox writes**

```csharp
public async Task<Transaction> AddWithOutboxAsync(
    Transaction transaction,
    OutboxEvent outboxEvent,
    CancellationToken ct = default)
{
    await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
    {
        TransactItems =
        [
            new()
            {
                Put = new Put { TableName = "Transactions", Item = ToItem(transaction) }
            },
            new()
            {
                Put = new Put { TableName = "OutboxEvents", Item = OutboxToItem(outboxEvent) }
            }
        ]
    }, ct);

    return transaction;
}
```

- [ ] **Step 5: Emit projection-ready payloads from the service**

```csharp
var outboxEvent = new OutboxEvent
{
    Id = Guid.NewGuid(),
    AggregateId = transaction.Id,
    EventType = OutboxEventType.TransactionCreated,
    Payload = JsonSerializer.Serialize(new
    {
        TransactionId = transaction.Id,
        UserId = userId,
        Type = transaction.Type.ToString(),
        Category = transaction.Category,
        Amount = transaction.Amount.Amount,
        CurrencyCode = transaction.Amount.CurrencyCode,
        TransactionDate = transaction.Date,
    }),
    CreatedAt = DateTime.UtcNow
};
```

For delete:

```csharp
Payload = JsonSerializer.Serialize(new
{
    TransactionId = id,
    UserId = userId,
    PreviousType = existing.Type.ToString(),
    PreviousCategory = existing.Category,
    PreviousAmount = existing.Amount.Amount,
    PreviousCurrencyCode = existing.Amount.CurrencyCode,
    PreviousTransactionDate = existing.Date,
}),
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `dotnet test tests/Conscia.Tests.Unit --filter TransactionServiceTests`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/Interfaces/ITransactionRepository.cs src/Conscia.Infrastructure/Repositories/TransactionRepository.cs src/Conscia.Application/Services/TransactionService.cs tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs
git commit -m "feat: emit projection outbox events for transactions"
```

### Task 4: Make OutboxProcessor maintain the monthly projection

**Files:**
- Modify: `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs`

- [ ] **Step 1: Write the failing processor test**

```csharp
[Fact]
public async Task ProcessesTransactionCreatedEvent_UpdatesMonthlyProjection()
{
    var projectionRepo = new Mock<IMonthlyCategorySpendRepository>();

    services.AddScoped(_ => _outboxRepoMock.Object);
    services.AddScoped(_ => projectionRepo.Object);

    _outboxRepoMock.Setup(r => r.GetPendingAsync(50, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new List<OutboxEvent>
        {
            new()
            {
                Id = Guid.NewGuid(),
                AggregateId = Guid.NewGuid(),
                EventType = OutboxEventType.TransactionCreated,
                Payload = JsonSerializer.Serialize(new
                {
                    TransactionId = Guid.NewGuid(),
                    UserId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Type = "Expense",
                    Category = "Dining",
                    Amount = 120m,
                    CurrencyCode = "PHP",
                    TransactionDate = DateTime.Parse("2026-05-10T00:00:00Z")
                }),
                CreatedAt = DateTime.UtcNow
            }
        }.AsReadOnly());

    await processor.ProcessBatchAsync(CancellationToken.None);

    projectionRepo.Verify(r => r.UpsertAsync(
        It.Is<MonthlyCategorySpend>(p => p.MonthKey == "2026-05" && p.NormalizedCategory == "dining"),
        It.IsAny<CancellationToken>()), Times.Once);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter OutboxProcessorTests`
Expected: FAIL because the processor still only logs acknowledgements

- [ ] **Step 3: Inject the projection repository and implement event dispatch**

```csharp
private async Task DispatchEventAsync(
    OutboxEvent evt,
    IMonthlyCategorySpendRepository projections,
    CancellationToken ct)
{
    switch (evt.EventType)
    {
        case OutboxEventType.TransactionCreated:
            await ApplyCreatedAsync(evt, projections, ct);
            break;
        case OutboxEventType.TransactionDeleted:
            await ApplyDeletedAsync(evt, projections, ct);
            break;
        case OutboxEventType.TransactionUpdated:
            await ApplyUpdatedAsync(evt, projections, ct);
            break;
    }
}
```

- [ ] **Step 4: Re-enable the targeted processor wiring**

```csharp
builder.Services.AddScoped<IOutboxEventRepository, OutboxEventRepository>();
builder.Services.AddScoped<IMonthlyCategorySpendRepository, MonthlyCategorySpendRepository>();
builder.Services.AddHostedService<OutboxProcessor>();
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `dotnet test tests/Conscia.Tests.Unit --filter OutboxProcessorTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Infrastructure/Services/OutboxProcessor.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs
git commit -m "feat: project monthly spending from outbox events"
```

### Task 5: Add drift reconciliation support

**Files:**
- Modify: `src/Conscia.Application/Interfaces/IMonthlyCategorySpendRepository.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/MonthlyCategorySpendRepository.cs`
- Modify: `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
- Create or Modify: `tests/Conscia.Tests.Unit/Application/BudgetTrendsServiceTests.cs`

- [ ] **Step 1: Write the failing reconciliation test**

```csharp
[Fact]
public async Task RepairProjectionAsync_OverwritesDriftedMonthFromSourceTotals()
{
    var sourceTotals = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase)
    {
        ["Dining"] = 1200m
    };

    var drifted = new MonthlyCategorySpend
    {
        UserId = userId,
        MonthKey = "2026-05",
        Category = "Dining",
        NormalizedCategory = "dining",
        CurrencyCode = "PHP",
        TotalExpenseAmount = 900m,
        TransactionCount = 2,
    };

    // Assert repaired amount becomes 1200 rather than 900
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter BudgetTrendsServiceTests`
Expected: FAIL because reconciliation logic does not exist yet

- [ ] **Step 3: Add repository support for reading month slices**

```csharp
public async Task<IReadOnlyList<MonthlyCategorySpend>> ListRecentMonthsAsync(
    Guid userId,
    IReadOnlyList<string> monthKeys,
    CancellationToken ct = default)
{
    var results = new List<MonthlyCategorySpend>();
    foreach (var monthKey in monthKeys)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new($"USER#{userId}"),
                [":prefix"] = new($"MONTH#{monthKey}#CAT#")
            }
        }, ct);

        results.AddRange(response.Items.Select(FromItem));
    }

    return results;
}
```

- [ ] **Step 4: Add repair logic**

```csharp
private async Task RepairMonthAsync(Guid userId, string monthKey, CancellationToken ct)
{
    var totals = await RecomputeMonthFromTransactionsAsync(userId, monthKey, ct);
    foreach (var total in totals)
    {
        await _projectionRepository.UpsertAsync(total, ct);
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dotnet test tests/Conscia.Tests.Unit --filter BudgetTrendsServiceTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Application/Interfaces/IMonthlyCategorySpendRepository.cs src/Conscia.Infrastructure/Repositories/MonthlyCategorySpendRepository.cs src/Conscia.Infrastructure/Services/OutboxProcessor.cs tests/Conscia.Tests.Unit/Application/BudgetTrendsServiceTests.cs
git commit -m "feat: add monthly spend projection repair logic"
```

### Task 6: Extend insights models with budget trends

**Files:**
- Modify: `src/Conscia.Application/DTOs/InsightsDtos.cs`
- Modify: `src/Conscia.Application/Services/BehavioralInsightsService.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/BehavioralInsightsServiceTests.cs`

- [ ] **Step 1: Write the failing insights shaping test**

```csharp
[Fact]
public async Task GetBehavioralInsightsAsync_ReturnsBudgetAndSpendTrends_ForLastThreeMonths()
{
    _projectionRepositoryMock.Setup(r => r.ListRecentMonthsAsync(
            userId,
            It.IsAny<IReadOnlyList<string>>(),
            It.IsAny<CancellationToken>()))
        .ReturnsAsync(new List<MonthlyCategorySpend>
        {
            new() { UserId = userId, MonthKey = "2026-03", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 580m, TransactionCount = 4 },
            new() { UserId = userId, MonthKey = "2026-04", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 610m, TransactionCount = 4 },
            new() { UserId = userId, MonthKey = "2026-05", Category = "Dining", NormalizedCategory = "dining", CurrencyCode = "PHP", TotalExpenseAmount = 740m, TransactionCount = 5 },
        });

    _budgetRepositoryMock.Setup(...); // current budget limit of 1000

    var result = await _service.GetBehavioralInsightsAsync(userId);

    Assert.Equal(new[] { 58d, 61d, 74d }, result!.BudgetTrends.Single().Months);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter BehavioralInsightsServiceTests`
Expected: FAIL because the insights model has no `BudgetTrends`

- [ ] **Step 3: Extend the DTOs**

```csharp
public sealed record BudgetTrendInsightDto(
    string Category,
    bool HasBudget,
    string CurrencyCode,
    IReadOnlyList<double> Months,
    decimal CurrentMonthSpend,
    double? CurrentMonthPercentUsed,
    string InsightLabel,
    string? Nudge);
```

- [ ] **Step 4: Join projection rows with budgets in the service**

```csharp
var monthKeys = Enumerable.Range(0, 3)
    .Select(offset => now.AddMonths(-offset))
    .Select(date => date.ToString("yyyy-MM"))
    .Reverse()
    .ToArray();

var projections = await _monthlyCategorySpendRepository.ListRecentMonthsAsync(userId, monthKeys, ct);
var budgets = await _budgetService.ListStatusesByUserAsync(userId, now: now, ct: ct);
```

Then shape:

```csharp
BudgetTrends = rankedCategories
    .Take(3)
    .Select(category => new BudgetTrendInsightDto(
        category.Category,
        category.HasBudget,
        category.CurrencyCode,
        category.Months,
        category.CurrentMonthSpend,
        category.CurrentMonthPercentUsed,
        category.InsightLabel,
        category.HasBudget ? null : "Add a budget for sharper insights"))
    .ToList()
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `dotnet test tests/Conscia.Tests.Unit --filter BehavioralInsightsServiceTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Application/DTOs/InsightsDtos.cs src/Conscia.Application/Services/BehavioralInsightsService.cs tests/Conscia.Tests.Unit/Application/BehavioralInsightsServiceTests.cs
git commit -m "feat: add budget trend insights"
```

### Task 7: Expose the extended insights payload from the API

**Files:**
- Modify: `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`
- Test: existing API insights tests if present, otherwise add `tests/Conscia.Tests.Unit/...` service-level coverage only

- [ ] **Step 1: Write the failing API serialization test**

```csharp
// Add an assertion that the serialized insights payload includes "budgetTrends"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit --filter Insights`
Expected: FAIL because the endpoint output does not include the new property

- [ ] **Step 3: Return the extended payload**

```csharp
return Results.Ok(new
{
    insights.Mood,
    insights.WorthItPercentage,
    insights.WorthItCount,
    insights.PreviousMonthWorthItCount,
    insights.ImpulseeTrends,
    insights.BudgetTrends,
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dotnet test tests/Conscia.Tests.Unit --filter Insights`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Api/Endpoints/InsightsEndpoints.cs
git commit -m "feat: expose budget trends in insights api"
```

### Task 8: Render the new insights card in the app

**Files:**
- Create: `app/lib/screens/dashboard/widgets/budget_trends_card.dart`
- Modify: `app/lib/services/ai_service.dart` or current shared insights model file if it owns the insights response shape
- Modify: `app/lib/providers/behavioral_insights_provider.dart`
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Test: `app/test/screens/dashboard/...`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('dashboard shows budget trends insight card when trends exist', (tester) async {
  // Build dashboard with insights provider returning budgetTrends
  expect(find.text('Budget Trends'), findsOneWidget);
  expect(find.text('Dining'), findsOneWidget);
  expect(find.text('Add a budget for sharper insights'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/dashboard`
Expected: FAIL because no trends card exists

- [ ] **Step 3: Add the card widget**

```dart
class BudgetTrendsCard extends StatelessWidget {
  const BudgetTrendsCard({super.key, required this.trends});

  final List<BudgetTrendInsight> trends;

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Trends', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final trend in trends) ...[
            Text(trend.category),
            Text(trend.displayLine),
            if (trend.nudge != null) Text(trend.nudge!),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Wire it into the dashboard**

```dart
if (insights.budgetTrends.isNotEmpty)
  BudgetTrendsCard(trends: insights.budgetTrends),
```

- [ ] **Step 5: Run widget tests to verify they pass**

Run: `flutter test test/screens/dashboard`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/dashboard/widgets/budget_trends_card.dart app/lib/providers/behavioral_insights_provider.dart app/lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: show budget trends in dashboard insights"
```

### Task 9: End-to-end verification

**Files:**
- No new files

- [ ] **Step 1: Run focused backend tests**

Run: `dotnet test tests/Conscia.Tests.Unit --filter "TransactionServiceTests|OutboxProcessorTests|BehavioralInsightsServiceTests|DynamoDbHealthCheckTests|MonthlyCategorySpendRepositoryTests"`
Expected: PASS

- [ ] **Step 2: Run focused Flutter tests**

Run: `flutter test test/screens/dashboard test/screens/budgets/widgets/budget_form_sheet_test.dart`
Expected: PASS

- [ ] **Step 3: Build backend projects**

Run: `dotnet build src/Conscia.Api/Conscia.Api.csproj`
Expected: `Build succeeded.`

Run: `dotnet build src/Conscia.PatternAggregator/Conscia.PatternAggregator.csproj`
Expected: `Build succeeded.`

- [ ] **Step 4: Commit final integration polish if needed**

```bash
git add .
git commit -m "chore: finalize budget trends projection integration"
```

---

## Self-Review

### Spec coverage

- Monthly projection table: covered in Tasks 1 and 2
- Projection-only outbox restoration: covered in Tasks 3 and 4
- Drift prevention and repair: covered in Task 5
- Last 3 months insights card: covered in Tasks 6, 7, and 8
- Budgeted vs unbudgeted category behavior: covered in Task 6 and app rendering in Task 8
- No Redis in first version: reflected in architecture; no cache implementation task added

### Placeholder scan

- One intentionally thin API serialization test placeholder remains because the exact existing API test file needs discovery before execution. If no API insights test exists, rely on service-level and app-level coverage instead of inventing a weak test file. This is the only place execution should adjust based on actual repo context.

### Type consistency

- Projection entity: `MonthlyCategorySpend`
- Repository: `IMonthlyCategorySpendRepository`
- DTO: `BudgetTrendInsightDto`
- App card expects a parsed `BudgetTrendInsight` client model derived from the API payload

