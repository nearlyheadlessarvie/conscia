# Regret Memory System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface 30-day regret patterns on the dashboard (glimpse card) and a full Insights screen with merchant/category drill-downs, populated nightly by a single Lambda that also schedules the existing WeeklyInsights calculation.

**Architecture:** New `PurchasePatterns` DynamoDB table (PK=`USER#{userId}`, SK=`SUMMARY`/`CAT#{category}`/`MER#{merchant}`). A `conscia-pattern-aggregator` Lambda runs nightly via EventBridge and writes both `PurchasePatterns` and `WeeklyInsights`. Five new read-only API endpoints under `/api/v1/insights/`. Flutter: a `RegretSummaryCard` on the dashboard that pushes to an `InsightsScreen` with merchant and category drill-downs.

**Tech Stack:** .NET 8, AWS Lambda, DynamoDB, CDK (EventBridge + Lambda), Flutter/Riverpod, Dio, go_router.

---

## File Map

**Create:**
- `src/Conscia.Domain/Entities/PurchasePattern.cs`
- `src/Conscia.Application/Interfaces/IPurchasePatternRepository.cs`
- `src/Conscia.Application/Interfaces/IPurchasePatternService.cs`
- `src/Conscia.Application/DTOs/InsightsDtos.cs`
- `src/Conscia.Application/Services/PurchasePatternService.cs`
- `src/Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`
- `src/Conscia.PatternAggregator/Conscia.PatternAggregator.csproj`
- `src/Conscia.PatternAggregator/Program.cs`
- `src/Conscia.PatternAggregator/PatternAggregatorService.cs`
- `infra/src/Conscia.Infra/PatternAggregatorStack.cs`
- `tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs`
- `app/lib/models/insights_models.dart`
- `app/lib/providers/insights_provider.dart`
- `app/lib/screens/dashboard/widgets/regret_summary_card.dart`
- `app/lib/screens/insights/insights_screen.dart`
- `app/lib/screens/insights/widgets/merchant_spotlight_card.dart`
- `app/lib/screens/insights/widgets/category_trend_card.dart`
- `app/lib/screens/insights/merchant_list_screen.dart`
- `app/lib/screens/insights/merchant_detail_screen.dart`
- `app/lib/screens/insights/category_list_screen.dart`
- `app/lib/screens/insights/category_detail_screen.dart`

**Modify:**
- `src/Conscia.Infrastructure/Helpers/DynamoKeys.cs`
- `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`
- `src/Conscia.Api/Program.cs`
- `infra/src/Conscia.Infra/DatabaseStack.cs`
- `infra/src/Conscia.Infra/ComputeStack.cs`
- `infra/src/Conscia.Infra/Program.cs`
- `tools/DynamoSetup/Program.cs`
- `app/lib/core/constants/api_constants.dart`
- `app/lib/core/routing/app_router.dart`
- `app/lib/screens/dashboard/dashboard_screen.dart`

---

### Task 1: PurchasePatterns table

**Files:**
- Modify: `infra/src/Conscia.Infra/DatabaseStack.cs`
- Modify: `tools/DynamoSetup/Program.cs`

- [ ] **Step 1: Add PurchasePatterns table to DatabaseStack**

In `infra/src/Conscia.Infra/DatabaseStack.cs`, add a new `ITable` property and create the table after `WeeklyInsightsTable`:

```csharp
public ITable PurchasePatternsTable { get; }
```

In the constructor, add after `WeeklyInsightsTable = CreateTable(...)`:

```csharp
PurchasePatternsTable = CreateTable(
    "PurchasePatterns",
    "PK",
    "SK"
);
```

- [ ] **Step 2: Add PurchasePatterns to DynamoSetup**

In `tools/DynamoSetup/Program.cs`, add this entry to the `tables` array after the WeeklyInsights entry:

```csharp
// ---------------- PURCHASE PATTERNS ----------------
("PurchasePatterns", new CreateTableRequest
{
    TableName = "PurchasePatterns",
    KeySchema =
    [
        new KeySchemaElement("PK", KeyType.HASH),
        new KeySchemaElement("SK", KeyType.RANGE)
    ],
    AttributeDefinitions =
    [
        new("PK", ScalarAttributeType.S),
        new("SK", ScalarAttributeType.S)
    ],
    BillingMode = BillingMode.PAY_PER_REQUEST
}),
```

- [ ] **Step 3: Re-run DynamoSetup locally**

```bash
dotnet run --project tools/DynamoSetup/DynamoSetup.csproj -- http://localhost:8000
```

Expected: `Created table 'PurchasePatterns'` (or "already exists" for others).

- [ ] **Step 4: Commit**

```bash
git add infra/src/Conscia.Infra/DatabaseStack.cs tools/DynamoSetup/Program.cs
git commit -m "feat: add PurchasePatterns DynamoDB table"
```

---

### Task 2: DynamoKeys + Domain entity + Application interfaces + DTOs

**Files:**
- Modify: `src/Conscia.Infrastructure/Helpers/DynamoKeys.cs`
- Create: `src/Conscia.Domain/Entities/PurchasePattern.cs`
- Create: `src/Conscia.Application/Interfaces/IPurchasePatternRepository.cs`
- Create: `src/Conscia.Application/Interfaces/IPurchasePatternService.cs`
- Create: `src/Conscia.Application/DTOs/InsightsDtos.cs`

- [ ] **Step 1: Add PurchasePattern SK helpers to DynamoKeys**

Add these methods to `src/Conscia.Infrastructure/Helpers/DynamoKeys.cs`:

```csharp
public static string PurchasePatternSummary()
    => "SUMMARY";

public static string PurchasePatternCategory(string category)
    => $"CAT#{category.Trim().ToLowerInvariant()}";

public static string PurchasePatternMerchant(string merchant)
    => $"MER#{merchant.Trim().ToLowerInvariant()}";
```

- [ ] **Step 2: Create domain entity**

Create `src/Conscia.Domain/Entities/PurchasePattern.cs`:

```csharp
namespace Conscia.Domain.Entities;

public class PurchasePatternSummary
{
    public Guid UserId { get; set; }
    public decimal RegrettedAmount { get; set; }
    public string RegrettedCategory { get; set; } = string.Empty;
    public double AvgRegretRate { get; set; }
    public int PatternCount { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CategoryPattern
{
    public Guid UserId { get; set; }
    public string Category { get; set; } = string.Empty;
    public decimal TotalSpend { get; set; }
    public decimal RegrettedSpend { get; set; }
    public double RegretRate { get; set; }
    public int TransactionCount { get; set; }
    public decimal ProjectedAnnual { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class MerchantPattern
{
    public Guid UserId { get; set; }
    public string Merchant { get; set; } = string.Empty;
    public int VisitCount { get; set; }
    public int RegretCount { get; set; }
    public double RegretRate { get; set; }
    public string LastVisitDate { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
}
```

- [ ] **Step 3: Create repository interface**

Create `src/Conscia.Application/Interfaces/IPurchasePatternRepository.cs`:

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IPurchasePatternRepository
{
    Task<PurchasePatternSummary?> GetSummaryAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<CategoryPattern>> GetCategoriesAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<MerchantPattern>> GetMerchantsAsync(Guid userId, CancellationToken ct = default);
    Task UpsertManyAsync(Guid userId, PurchasePatternSummary summary, IEnumerable<CategoryPattern> categories, IEnumerable<MerchantPattern> merchants, CancellationToken ct = default);
}
```

- [ ] **Step 4: Create service interface**

Create `src/Conscia.Application/Interfaces/IPurchasePatternService.cs`:

```csharp
using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IPurchasePatternService
{
    Task<InsightsSummaryDto?> GetSummaryAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<CategoryStatDto>> GetCategoriesAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<MerchantStatDto>> GetMerchantsAsync(Guid userId, CancellationToken ct = default);
    Task<CategoryDetailDto?> GetCategoryDetailAsync(Guid userId, string category, CancellationToken ct = default);
    Task<MerchantDetailDto?> GetMerchantDetailAsync(Guid userId, string merchant, CancellationToken ct = default);
}
```

- [ ] **Step 5: Create DTOs**

Create `src/Conscia.Application/DTOs/InsightsDtos.cs`:

```csharp
namespace Conscia.Application.DTOs;

public record InsightsSummaryDto(
    decimal RegrettedAmount,
    string RegrettedCategory,
    double AvgRegretRate,
    int PatternCount,
    DateTime UpdatedAt
);

public record CategoryStatDto(
    string Category,
    decimal TotalSpend,
    decimal RegrettedSpend,
    double RegretRate,
    int TransactionCount,
    decimal ProjectedAnnual
);

public record MerchantStatDto(
    string Merchant,
    int VisitCount,
    int RegretCount,
    double RegretRate,
    string LastVisitDate
);

public record TransactionSummaryDto(
    Guid Id,
    decimal Amount,
    string CurrencyCode,
    string Category,
    string? Merchant,
    DateTime Date,
    string? RegretLevel
);

public record CategoryDetailDto(
    CategoryStatDto Stats,
    IReadOnlyList<TransactionSummaryDto> RecentTransactions
);

public record MerchantDetailDto(
    MerchantStatDto Stats,
    IReadOnlyList<TransactionSummaryDto> RecentTransactions
);
```

- [ ] **Step 6: Build to check**

```bash
dotnet build src/Conscia.Application/Conscia.Application.csproj --no-restore -v q
```

Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Infrastructure/Helpers/DynamoKeys.cs \
        src/Conscia.Domain/Entities/PurchasePattern.cs \
        src/Conscia.Application/Interfaces/IPurchasePatternRepository.cs \
        src/Conscia.Application/Interfaces/IPurchasePatternService.cs \
        src/Conscia.Application/DTOs/InsightsDtos.cs
git commit -m "feat: add PurchasePattern entities, interfaces, and DTOs"
```

---

### Task 3: PurchasePatternRepository

**Files:**
- Create: `src/Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`

- [ ] **Step 1: Write the failing test**

Create `tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs` with a placeholder that confirms the repo interface compiles:

```csharp
using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchasePatternServiceTests
{
    private readonly Mock<IPurchasePatternRepository> _repoMock = new();
    private readonly Mock<ITransactionRepository> _txRepoMock = new();

    [Fact]
    public void Placeholder_CompilesOk() => Assert.True(true);
}
```

- [ ] **Step 2: Run to verify it compiles**

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "PurchasePatternServiceTests" -v q
```

Expected: `1 passed`

- [ ] **Step 3: Implement PurchasePatternRepository**

Create `src/Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class PurchasePatternRepository : IPurchasePatternRepository
{
    private const string TableName = "PurchasePatterns";
    private readonly IAmazonDynamoDB _dynamo;

    public PurchasePatternRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task<PurchasePatternSummary?> GetSummaryAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await _dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(userId, DynamoKeys.PurchasePatternSummary())
        }, ct);

        return response.Item?.Count > 0 ? SummaryFromItem(response.Item) : null;
    }

    public async Task<IReadOnlyList<CategoryPattern>> GetCategoriesAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new("CAT#")
            }
        }, ct);

        return response.Items.Select(CategoryFromItem).ToList();
    }

    public async Task<IReadOnlyList<MerchantPattern>> GetMerchantsAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new("MER#")
            }
        }, ct);

        return response.Items.Select(MerchantFromItem).ToList();
    }

    public async Task UpsertManyAsync(
        Guid userId,
        PurchasePatternSummary summary,
        IEnumerable<CategoryPattern> categories,
        IEnumerable<MerchantPattern> merchants,
        CancellationToken ct = default)
    {
        var allItems = new List<Dictionary<string, AttributeValue>>
        {
            SummaryToItem(summary)
        };
        allItems.AddRange(categories.Select(CategoryToItem));
        allItems.AddRange(merchants.Select(MerchantToItem));

        // DynamoDB TransactWriteItems limit is 100; batch in chunks of 25 (safe limit)
        foreach (var chunk in allItems.Chunk(25))
        {
            var requests = chunk.Select(item => new WriteRequest
            {
                PutRequest = new PutRequest { Item = item }
            }).ToList();

            await _dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
            {
                RequestItems = new Dictionary<string, List<WriteRequest>>
                {
                    [TableName] = requests
                }
            }, ct);
        }
    }

    // ---- Key helpers ----

    private static Dictionary<string, AttributeValue> Key(Guid userId, string sk) =>
        new()
        {
            ["PK"] = new(DynamoKeys.User(userId)),
            ["SK"] = new(sk)
        };

    // ---- Mappers ----

    private static Dictionary<string, AttributeValue> SummaryToItem(PurchasePatternSummary s) => new()
    {
        ["PK"] = new(DynamoKeys.User(s.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternSummary()),
        ["RegrettedAmount"] = new() { N = s.RegrettedAmount.ToString("G") },
        ["RegrettedCategory"] = new(s.RegrettedCategory),
        ["AvgRegretRate"] = new() { N = s.AvgRegretRate.ToString("F4") },
        ["PatternCount"] = new() { N = s.PatternCount.ToString() },
        ["UpdatedAt"] = new(s.UpdatedAt.ToString("O"))
    };

    private static PurchasePatternSummary SummaryFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["PK"].S.Replace("USER#", "")),
        RegrettedAmount = decimal.Parse(item["RegrettedAmount"].N),
        RegrettedCategory = item["RegrettedCategory"].S,
        AvgRegretRate = double.Parse(item["AvgRegretRate"].N),
        PatternCount = int.Parse(item["PatternCount"].N),
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };

    private static Dictionary<string, AttributeValue> CategoryToItem(CategoryPattern c) => new()
    {
        ["PK"] = new(DynamoKeys.User(c.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternCategory(c.Category)),
        ["Category"] = new(c.Category),
        ["TotalSpend"] = new() { N = c.TotalSpend.ToString("G") },
        ["RegrettedSpend"] = new() { N = c.RegrettedSpend.ToString("G") },
        ["RegretRate"] = new() { N = c.RegretRate.ToString("F4") },
        ["TransactionCount"] = new() { N = c.TransactionCount.ToString() },
        ["ProjectedAnnual"] = new() { N = c.ProjectedAnnual.ToString("G") },
        ["UpdatedAt"] = new(c.UpdatedAt.ToString("O"))
    };

    private static CategoryPattern CategoryFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["PK"].S.Replace("USER#", "")),
        Category = item["Category"].S,
        TotalSpend = decimal.Parse(item["TotalSpend"].N),
        RegrettedSpend = decimal.Parse(item["RegrettedSpend"].N),
        RegretRate = double.Parse(item["RegretRate"].N),
        TransactionCount = int.Parse(item["TransactionCount"].N),
        ProjectedAnnual = decimal.Parse(item["ProjectedAnnual"].N),
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };

    private static Dictionary<string, AttributeValue> MerchantToItem(MerchantPattern m) => new()
    {
        ["PK"] = new(DynamoKeys.User(m.UserId)),
        ["SK"] = new(DynamoKeys.PurchasePatternMerchant(m.Merchant)),
        ["Merchant"] = new(m.Merchant),
        ["VisitCount"] = new() { N = m.VisitCount.ToString() },
        ["RegretCount"] = new() { N = m.RegretCount.ToString() },
        ["RegretRate"] = new() { N = m.RegretRate.ToString("F4") },
        ["LastVisitDate"] = new(m.LastVisitDate),
        ["UpdatedAt"] = new(m.UpdatedAt.ToString("O"))
    };

    private static MerchantPattern MerchantFromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["PK"].S.Replace("USER#", "")),
        Merchant = item["Merchant"].S,
        VisitCount = int.Parse(item["VisitCount"].N),
        RegretCount = int.Parse(item["RegretCount"].N),
        RegretRate = double.Parse(item["RegretRate"].N),
        LastVisitDate = item["LastVisitDate"].S,
        UpdatedAt = DateTime.Parse(item["UpdatedAt"].S)
    };
}
```

- [ ] **Step 4: Build Infrastructure**

```bash
dotnet build src/Conscia.Infrastructure/Conscia.Infrastructure.csproj --no-restore -v q
```

Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs \
        tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs
git commit -m "feat: add PurchasePatternRepository with DynamoDB single-table reads/writes"
```

---

### Task 4: PurchasePatternService + unit tests

**Files:**
- Create: `src/Conscia.Application/Services/PurchasePatternService.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs`

- [ ] **Step 1: Write failing tests**

Replace the placeholder in `tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs`:

```csharp
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchasePatternServiceTests
{
    private readonly Mock<IPurchasePatternRepository> _repoMock = new();
    private readonly Mock<ITransactionRepository> _txRepoMock = new();
    private readonly PurchasePatternService _svc;

    public PurchasePatternServiceTests()
        => _svc = new PurchasePatternService(_repoMock.Object, _txRepoMock.Object);

    [Fact]
    public async Task GetSummaryAsync_ReturnsNull_WhenNoPatterns()
    {
        _repoMock.Setup(r => r.GetSummaryAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((PurchasePatternSummary?)null);

        var result = await _svc.GetSummaryAsync(Guid.NewGuid());

        Assert.Null(result);
    }

    [Fact]
    public async Task GetSummaryAsync_ReturnsMappedDto_WhenPatternExists()
    {
        var userId = Guid.NewGuid();
        _repoMock.Setup(r => r.GetSummaryAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PurchasePatternSummary
            {
                UserId = userId,
                RegrettedAmount = 120m,
                RegrettedCategory = "Gaming",
                AvgRegretRate = 0.65,
                PatternCount = 3,
                UpdatedAt = DateTime.UtcNow
            });

        var result = await _svc.GetSummaryAsync(userId);

        Assert.NotNull(result);
        Assert.Equal(120m, result!.RegrettedAmount);
        Assert.Equal("Gaming", result.RegrettedCategory);
        Assert.Equal(3, result.PatternCount);
    }

    [Fact]
    public async Task GetCategoryDetailAsync_ReturnsNull_WhenNotFound()
    {
        _repoMock.Setup(r => r.GetCategoriesAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryPattern>());

        var result = await _svc.GetCategoryDetailAsync(Guid.NewGuid(), "Gaming");

        Assert.Null(result);
    }

    [Fact]
    public async Task GetCategoryDetailAsync_ReturnsStatsAndTransactions_WhenFound()
    {
        var userId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        _repoMock.Setup(r => r.GetCategoriesAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryPattern>
            {
                new() { UserId = userId, Category = "Gaming", TotalSpend = 200m,
                        RegrettedSpend = 140m, RegretRate = 0.70, TransactionCount = 5,
                        ProjectedAnnual = 1706m, UpdatedAt = now }
            });

        _txRepoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Transaction>
            {
                new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(50m, "USD"),
                        Category = "Gaming", Date = now, RegretLevel = RegretLevel.Regret },
                new() { Id = Guid.NewGuid(), UserId = userId, Amount = new Money(30m, "USD"),
                        Category = "Food", Date = now }
            });

        var result = await _svc.GetCategoryDetailAsync(userId, "Gaming");

        Assert.NotNull(result);
        Assert.Equal("Gaming", result!.Stats.Category);
        Assert.Single(result.RecentTransactions); // only "Gaming" transactions
    }
}
```

- [ ] **Step 2: Run to verify they fail**

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "PurchasePatternServiceTests" -v q
```

Expected: FAIL — `PurchasePatternService` not defined.

- [ ] **Step 3: Implement PurchasePatternService**

Create `src/Conscia.Application/Services/PurchasePatternService.cs`:

```csharp
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Application.Services;

public class PurchasePatternService : IPurchasePatternService
{
    private readonly IPurchasePatternRepository _repo;
    private readonly ITransactionRepository _txRepo;

    public PurchasePatternService(IPurchasePatternRepository repo, ITransactionRepository txRepo)
    {
        _repo = repo;
        _txRepo = txRepo;
    }

    public async Task<InsightsSummaryDto?> GetSummaryAsync(Guid userId, CancellationToken ct = default)
    {
        var summary = await _repo.GetSummaryAsync(userId, ct);
        if (summary is null) return null;

        return new InsightsSummaryDto(
            summary.RegrettedAmount,
            summary.RegrettedCategory,
            summary.AvgRegretRate,
            summary.PatternCount,
            summary.UpdatedAt
        );
    }

    public async Task<IReadOnlyList<CategoryStatDto>> GetCategoriesAsync(Guid userId, CancellationToken ct = default)
    {
        var categories = await _repo.GetCategoriesAsync(userId, ct);
        return categories
            .OrderByDescending(c => c.RegretRate)
            .Select(c => new CategoryStatDto(c.Category, c.TotalSpend, c.RegrettedSpend,
                c.RegretRate, c.TransactionCount, c.ProjectedAnnual))
            .ToList();
    }

    public async Task<IReadOnlyList<MerchantStatDto>> GetMerchantsAsync(Guid userId, CancellationToken ct = default)
    {
        var merchants = await _repo.GetMerchantsAsync(userId, ct);
        return merchants
            .OrderByDescending(m => m.RegretRate)
            .Select(m => new MerchantStatDto(m.Merchant, m.VisitCount, m.RegretCount,
                m.RegretRate, m.LastVisitDate))
            .ToList();
    }

    public async Task<CategoryDetailDto?> GetCategoryDetailAsync(Guid userId, string category, CancellationToken ct = default)
    {
        var categories = await _repo.GetCategoriesAsync(userId, ct);
        var match = categories.FirstOrDefault(c =>
            string.Equals(c.Category, category, StringComparison.OrdinalIgnoreCase));

        if (match is null) return null;

        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);
        var transactions = await _txRepo.GetByUserIdAndDateRangeAsync(userId, from, to, ct);

        var recent = transactions
            .Where(t => string.Equals(t.Category, category, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(t => t.Date)
            .Take(10)
            .Select(t => new TransactionSummaryDto(t.Id, t.Amount.Amount, t.Amount.CurrencyCode,
                t.Category, t.Merchant, t.Date, t.RegretLevel?.ToString()))
            .ToList();

        var stats = new CategoryStatDto(match.Category, match.TotalSpend, match.RegrettedSpend,
            match.RegretRate, match.TransactionCount, match.ProjectedAnnual);

        return new CategoryDetailDto(stats, recent);
    }

    public async Task<MerchantDetailDto?> GetMerchantDetailAsync(Guid userId, string merchant, CancellationToken ct = default)
    {
        var merchants = await _repo.GetMerchantsAsync(userId, ct);
        var match = merchants.FirstOrDefault(m =>
            string.Equals(m.Merchant, merchant, StringComparison.OrdinalIgnoreCase));

        if (match is null) return null;

        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);
        var transactions = await _txRepo.GetByUserIdAndDateRangeAsync(userId, from, to, ct);

        var recent = transactions
            .Where(t => string.Equals(t.Merchant, merchant, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(t => t.Date)
            .Take(10)
            .Select(t => new TransactionSummaryDto(t.Id, t.Amount.Amount, t.Amount.CurrencyCode,
                t.Category, t.Merchant, t.Date, t.RegretLevel?.ToString()))
            .ToList();

        var stats = new MerchantStatDto(match.Merchant, match.VisitCount, match.RegretCount,
            match.RegretRate, match.LastVisitDate);

        return new MerchantDetailDto(stats, recent);
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "PurchasePatternServiceTests" -v q
```

Expected: `4 passed`

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Application/Services/PurchasePatternService.cs \
        tests/Conscia.Tests.Unit/Application/PurchasePatternServiceTests.cs
git commit -m "feat: add PurchasePatternService with category and merchant detail"
```

---

### Task 5: Insights API endpoints + DI registration

**Files:**
- Modify: `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`

- [ ] **Step 1: Add five new endpoints to InsightsEndpoints.cs**

Replace the full content of `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`:

```csharp
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class InsightsEndpoints
{
    public static RouteGroupBuilder MapInsightsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/insights")
            .RequireAuthorization()
            .WithTags("Insights");

        group.MapGet("/behavioral", async (HttpContext ctx, IBehavioralInsightsService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var insights = await svc.GetBehavioralInsightsAsync(userId, ct);
            return insights != null ? Results.Ok(insights) : Results.NoContent();
        }).WithName("GetBehavioralInsights");

        group.MapGet("/summary", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var summary = await svc.GetSummaryAsync(userId, ct);
            return summary is null ? Results.NotFound() : Results.Ok(summary);
        }).WithName("GetInsightsSummary");

        group.MapGet("/categories", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var categories = await svc.GetCategoriesAsync(userId, ct);
            return Results.Ok(categories);
        }).WithName("GetInsightsCategories");

        group.MapGet("/categories/{category}", async (HttpContext ctx, string category, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var detail = await svc.GetCategoryDetailAsync(userId, category, ct);
            return detail is null ? Results.NotFound() : Results.Ok(detail);
        }).WithName("GetInsightsCategoryDetail");

        group.MapGet("/merchants", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var merchants = await svc.GetMerchantsAsync(userId, ct);
            return Results.Ok(merchants);
        }).WithName("GetInsightsMerchants");

        group.MapGet("/merchants/{merchant}", async (HttpContext ctx, string merchant, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var detail = await svc.GetMerchantDetailAsync(userId, merchant, ct);
            return detail is null ? Results.NotFound() : Results.Ok(detail);
        }).WithName("GetInsightsMerchantDetail");

        return group;
    }
}
```

- [ ] **Step 2: Register IPurchasePatternRepository and IPurchasePatternService in Program.cs**

In `src/Conscia.Api/Program.cs`, find the block that registers DynamoDB repositories (around line 135) and add after `builder.Services.AddScoped<IWeeklyInsightsRepository, WeeklyInsightsRepository>();`:

```csharp
builder.Services.AddScoped<IPurchasePatternRepository, PurchasePatternRepository>();
```

Find the Services block (around line 153) and add after `builder.Services.AddScoped<IPurchaseSuggestionService, PurchaseSuggestionService>();`:

```csharp
builder.Services.AddScoped<IPurchasePatternService, PurchasePatternService>();
```

- [ ] **Step 3: Build to check**

```bash
dotnet build src/Conscia.Api/Conscia.Api.csproj --no-restore -v q
```

Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 4: Commit**

```bash
git add src/Conscia.Api/Endpoints/InsightsEndpoints.cs src/Conscia.Api/Program.cs
git commit -m "feat: add Insights API endpoints (summary, categories, merchants + detail)"
```

---

### Task 6: PatternAggregator Lambda

**Files:**
- Create: `src/Conscia.PatternAggregator/Conscia.PatternAggregator.csproj`
- Create: `src/Conscia.PatternAggregator/Program.cs`
- Create: `src/Conscia.PatternAggregator/PatternAggregatorService.cs`

- [ ] **Step 1: Create the .csproj**

Create `src/Conscia.PatternAggregator/Conscia.PatternAggregator.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <AWSProjectType>Lambda</AWSProjectType>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.2.0" />
    <PackageReference Include="Amazon.Lambda.RuntimeSupport" Version="1.10.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.SystemTextJson" Version="2.4.1" />
    <PackageReference Include="AWSSDK.DynamoDBv2" Version="3.7.300" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging" Version="8.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging.Console" Version="8.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Conscia.Application\Conscia.Application.csproj" />
    <ProjectReference Include="..\Conscia.Infrastructure\Conscia.Infrastructure.csproj" />
  </ItemGroup>
</Project>
```

- [ ] **Step 2: Create PatternAggregatorService**

Create `src/Conscia.PatternAggregator/PatternAggregatorService.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.PatternAggregator;

public class PatternAggregatorService
{
    private readonly IAmazonDynamoDB _dynamo;
    private readonly IPurchasePatternRepository _patternRepo;
    private readonly IBehavioralInsightsService _insightsService;
    private readonly ILogger<PatternAggregatorService> _logger;

    public PatternAggregatorService(
        IAmazonDynamoDB dynamo,
        IPurchasePatternRepository patternRepo,
        IBehavioralInsightsService insightsService,
        ILogger<PatternAggregatorService> logger)
    {
        _dynamo = dynamo;
        _patternRepo = patternRepo;
        _insightsService = insightsService;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken ct = default)
    {
        var userIds = await GetActiveUserIdsAsync(ct);
        _logger.LogInformation("Processing {Count} active users", userIds.Count);

        foreach (var userId in userIds)
        {
            try
            {
                await ProcessUserAsync(userId, ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process user {UserId}", userId);
            }
        }
    }

    private async Task ProcessUserAsync(Guid userId, CancellationToken ct)
    {
        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);

        // --- PurchasePatterns aggregation ---
        var transactions = await GetTransactionsForUserAsync(userId, from, to, ct);
        var expenses = transactions
            .Where(t => t.Type == TransactionType.Expense && t.RegretLevel.HasValue)
            .ToList();

        if (expenses.Count > 0)
        {
            var (summary, categories, merchants) = Aggregate(userId, expenses, to);
            await _patternRepo.UpsertManyAsync(userId, summary, categories, merchants, ct);
        }

        // --- WeeklyInsights calculation ---
        var weekStart = GetStartOfWeek(to);
        await _insightsService.CalculateAndStoreWeeklyInsightsAsync(userId, weekStart, ct);

        _logger.LogInformation("Processed user {UserId}: {Expenses} rated expenses", userId, expenses.Count);
    }

    private static (PurchasePatternSummary summary, List<CategoryPattern> categories, List<MerchantPattern> merchants)
        Aggregate(Guid userId, List<Transaction> expenses, DateTime now)
    {
        var categoryGroups = expenses
            .GroupBy(t => t.Category)
            .Select(g =>
            {
                var regretted = g.Where(t => t.RegretLevel != RegretLevel.WorthIt).ToList();
                var totalSpend = g.Sum(t => t.Amount.Amount);
                var regrettedSpend = regretted.Sum(t => t.Amount.Amount);
                var regretRate = (double)regretted.Count / g.Count();
                return new CategoryPattern
                {
                    UserId = userId,
                    Category = g.Key,
                    TotalSpend = totalSpend,
                    RegrettedSpend = regrettedSpend,
                    RegretRate = regretRate,
                    TransactionCount = g.Count(),
                    ProjectedAnnual = regrettedSpend / 30m * 365m,
                    UpdatedAt = now
                };
            }).ToList();

        var merchantGroups = expenses
            .Where(t => !string.IsNullOrWhiteSpace(t.Merchant))
            .GroupBy(t => t.Merchant!.Trim(), StringComparer.OrdinalIgnoreCase)
            .Select(g =>
            {
                var regretted = g.Count(t => t.RegretLevel != RegretLevel.WorthIt);
                return new MerchantPattern
                {
                    UserId = userId,
                    Merchant = g.First().Merchant!.Trim(),
                    VisitCount = g.Count(),
                    RegretCount = regretted,
                    RegretRate = (double)regretted / g.Count(),
                    LastVisitDate = g.Max(t => t.Date).ToString("yyyy-MM-dd"),
                    UpdatedAt = now
                };
            }).ToList();

        var worstCategory = categoryGroups
            .OrderByDescending(c => c.RegrettedSpend)
            .FirstOrDefault();

        var totalRated = expenses.Count;
        var totalRegretted = expenses.Count(t => t.RegretLevel != RegretLevel.WorthIt);

        var summary = new PurchasePatternSummary
        {
            UserId = userId,
            RegrettedAmount = worstCategory?.RegrettedSpend ?? 0m,
            RegrettedCategory = worstCategory?.Category ?? string.Empty,
            AvgRegretRate = totalRated > 0 ? (double)totalRegretted / totalRated : 0.0,
            PatternCount = categoryGroups.Count(c => c.RegretRate >= 0.4),
            UpdatedAt = now
        };

        return (summary, categoryGroups, merchantGroups);
    }

    private async Task<List<Transaction>> GetTransactionsForUserAsync(
        Guid userId, DateTime from, DateTime to, CancellationToken ct)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = "Transactions",
            IndexName = "GSI-Date",
            KeyConditionExpression = "UserId = :uid AND #d BETWEEN :from AND :to",
            ExpressionAttributeNames = new Dictionary<string, string> { ["#d"] = "Date" },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":uid"] = new(userId.ToString()),
                [":from"] = new(from.ToString("yyyy-MM-dd")),
                [":to"] = new(to.ToString("yyyy-MM-dd"))
            }
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    private async Task<List<Guid>> GetActiveUserIdsAsync(CancellationToken ct)
    {
        var minDate = DateTime.UtcNow.AddDays(-30).ToString("yyyy-MM-dd");
        var userIds = new HashSet<string>();
        Dictionary<string, AttributeValue>? lastKey = null;

        do
        {
            var request = new ScanRequest
            {
                TableName = "Transactions",
                FilterExpression = "#d >= :minDate",
                ExpressionAttributeNames = new Dictionary<string, string> { ["#d"] = "Date" },
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":minDate"] = new(minDate)
                },
                ProjectionExpression = "UserId",
                ExclusiveStartKey = lastKey
            };

            var response = await _dynamo.ScanAsync(request, ct);
            foreach (var item in response.Items)
            {
                if (item.TryGetValue("UserId", out var uid))
                    userIds.Add(uid.S);
            }

            lastKey = response.LastEvaluatedKey?.Count > 0 ? response.LastEvaluatedKey : null;
        } while (lastKey is not null);

        return userIds
            .Where(id => Guid.TryParse(id, out _))
            .Select(Guid.Parse)
            .ToList();
    }

    private static Transaction FromItem(Dictionary<string, AttributeValue> item)
    {
        decimal? exchangeRate = item.TryGetValue("ExchangeRateToBase", out var er) ? decimal.Parse(er.N) : null;
        return new Transaction
        {
            Id = Guid.Parse(item["Id"].S),
            UserId = Guid.Parse(item["UserId"].S),
            Type = Enum.Parse<TransactionType>(item["Type"].S),
            Amount = new Conscia.Domain.ValueObjects.Money(decimal.Parse(item["Amount"].N), item["CurrencyCode"].S, exchangeRate),
            Category = item["Category"].S,
            Merchant = item.TryGetValue("Merchant", out var m) ? m.S : null,
            Date = DateTime.Parse(item["Date"].S),
            RegretLevel = item.TryGetValue("RegretLevel", out var rl) ? Enum.Parse<RegretLevel>(rl.S) : null,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S)
        };
    }

    private static DateTime GetStartOfWeek(DateTime date)
    {
        var diff = (7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7;
        return date.AddDays(-diff).Date;
    }
}
```

- [ ] **Step 3: Create Lambda bootstrap**

Create `src/Conscia.PatternAggregator/Program.cs`:

```csharp
using Amazon;
using Amazon.DynamoDBv2;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Amazon.Runtime;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Infrastructure.Repositories;
using Conscia.PatternAggregator;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

var services = new ServiceCollection();

services.AddLogging(b => b.AddConsole());

services.AddSingleton<IAmazonDynamoDB>(_ =>
    new AmazonDynamoDBClient(new AmazonDynamoDBConfig
    {
        RegionEndpoint = RegionEndpoint.GetBySystemName(
            Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION") ?? "us-east-1")
    }));

services.AddScoped<IPurchasePatternRepository, PurchasePatternRepository>();
services.AddScoped<IWeeklyInsightsRepository, WeeklyInsightsRepository>();
services.AddScoped<ITransactionRepository, TransactionRepository>();
services.AddScoped<IBehavioralInsightsService, BehavioralInsightsService>();
services.AddScoped<PatternAggregatorService>();

var provider = services.BuildServiceProvider();

var handler = async (ILambdaContext context) =>
{
    using var scope = provider.CreateScope();
    var aggregator = scope.ServiceProvider.GetRequiredService<PatternAggregatorService>();
    await aggregator.RunAsync();
};

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
```

- [ ] **Step 4: Build the Lambda project**

```bash
dotnet build src/Conscia.PatternAggregator/Conscia.PatternAggregator.csproj --no-restore -v q
```

Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.PatternAggregator/
git commit -m "feat: add PatternAggregator Lambda — nightly PurchasePatterns + WeeklyInsights"
```

---

### Task 7: PatternAggregatorStack CDK

**Files:**
- Create: `infra/src/Conscia.Infra/PatternAggregatorStack.cs`
- Modify: `infra/src/Conscia.Infra/ComputeStack.cs`
- Modify: `infra/src/Conscia.Infra/Program.cs`

- [ ] **Step 1: Create PatternAggregatorStack**

Create `infra/src/Conscia.Infra/PatternAggregatorStack.cs`:

```csharp
using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Events;
using Amazon.CDK.AWS.Events.Targets;
using Amazon.CDK.AWS.Lambda;
using Constructs;

namespace Conscia.Infra;

public class PatternAggregatorStackProps : StackProps
{
    public required ITable TransactionsTable { get; set; }
    public required ITable WeeklyInsightsTable { get; set; }
    public required ITable PurchasePatternsTable { get; set; }
}

public class PatternAggregatorStack : Stack
{
    public PatternAggregatorStack(Construct scope, string id, PatternAggregatorStackProps props)
        : base(scope, id, props)
    {
        var lambda = new Function(this, "PatternAggregatorLambda", new FunctionProps
        {
            FunctionName = "conscia-pattern-aggregator",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.PatternAggregator",
            Code = Code.FromAsset("../publish/pattern-aggregator"),
            MemorySize = 512,
            Timeout = Duration.Minutes(5),
            Architecture = Architecture.ARM_64,
            Tracing = Tracing.ACTIVE
        });

        props.TransactionsTable.GrantReadData(lambda);
        props.WeeklyInsightsTable.GrantReadWriteData(lambda);
        props.PurchasePatternsTable.GrantReadWriteData(lambda);

        var rule = new Rule(this, "NightlySchedule", new RuleProps
        {
            Schedule = Schedule.Cron(new CronOptions
            {
                Minute = "0",
                Hour = "2",
                Day = "*",
                Month = "*",
                Year = "*"
            })
        });

        rule.AddTarget(new LambdaFunction(lambda));
    }
}
```

- [ ] **Step 2: Add PurchasePatternsTable to ComputeStack**

In `infra/src/Conscia.Infra/ComputeStack.cs`, add to `ComputeStackProps`:

```csharp
public required ITable PurchasePatternsTable { get; set; }
```

In the `ComputeStack` constructor, add to the `ApiLambda` `Environment` dictionary:

```csharp
["AWS__DynamoDB__PurchasePatternsTable"] = props.PurchasePatternsTable.TableName,
```

After the grant lines, add:

```csharp
props.PurchasePatternsTable.GrantReadWriteData(ApiLambda);
```

- [ ] **Step 3: Wire PatternAggregatorStack in Program.cs**

In `infra/src/Conscia.Infra/Program.cs`, add `PurchasePatternsTable` to the `compute` instantiation:

```csharp
var compute = new ComputeStack(app, "Conscia-Compute", new ComputeStackProps
{
    // ... existing props ...
    PurchasePatternsTable = database.PurchasePatternsTable,
    // ...
});
```

Then add after the `outbox` instantiation:

```csharp
_ = new PatternAggregatorStack(app, "Conscia-PatternAggregator", new PatternAggregatorStackProps
{
    Env = env,
    TransactionsTable = database.TransactionsTable,
    WeeklyInsightsTable = database.WeeklyInsightsTable,
    PurchasePatternsTable = database.PurchasePatternsTable
});
```

- [ ] **Step 4: Build infra to check**

```bash
dotnet build infra/src/Conscia.Infra/Conscia.Infra.csproj --no-restore -v q
```

Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 5: Commit**

```bash
git add infra/src/Conscia.Infra/PatternAggregatorStack.cs \
        infra/src/Conscia.Infra/ComputeStack.cs \
        infra/src/Conscia.Infra/Program.cs
git commit -m "feat: add PatternAggregatorStack — EventBridge nightly cron + Lambda grants"
```

---

### Task 8: Flutter models + API constants

**Files:**
- Create: `app/lib/models/insights_models.dart`
- Modify: `app/lib/core/constants/api_constants.dart`

- [ ] **Step 1: Create insights models**

Create `app/lib/models/insights_models.dart`:

```dart
class InsightsSummary {
  final double regrettedAmount;
  final String regrettedCategory;
  final double avgRegretRate;
  final int patternCount;
  final DateTime updatedAt;

  const InsightsSummary({
    required this.regrettedAmount,
    required this.regrettedCategory,
    required this.avgRegretRate,
    required this.patternCount,
    required this.updatedAt,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) => InsightsSummary(
        regrettedAmount: (json['regrettedAmount'] as num).toDouble(),
        regrettedCategory: json['regrettedCategory'] as String,
        avgRegretRate: (json['avgRegretRate'] as num).toDouble(),
        patternCount: json['patternCount'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CategoryStat {
  final String category;
  final double totalSpend;
  final double regrettedSpend;
  final double regretRate;
  final int transactionCount;
  final double projectedAnnual;

  const CategoryStat({
    required this.category,
    required this.totalSpend,
    required this.regrettedSpend,
    required this.regretRate,
    required this.transactionCount,
    required this.projectedAnnual,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        category: json['category'] as String,
        totalSpend: (json['totalSpend'] as num).toDouble(),
        regrettedSpend: (json['regrettedSpend'] as num).toDouble(),
        regretRate: (json['regretRate'] as num).toDouble(),
        transactionCount: json['transactionCount'] as int,
        projectedAnnual: (json['projectedAnnual'] as num).toDouble(),
      );
}

class MerchantStat {
  final String merchant;
  final int visitCount;
  final int regretCount;
  final double regretRate;
  final String lastVisitDate;

  const MerchantStat({
    required this.merchant,
    required this.visitCount,
    required this.regretCount,
    required this.regretRate,
    required this.lastVisitDate,
  });

  factory MerchantStat.fromJson(Map<String, dynamic> json) => MerchantStat(
        merchant: json['merchant'] as String,
        visitCount: json['visitCount'] as int,
        regretCount: json['regretCount'] as int,
        regretRate: (json['regretRate'] as num).toDouble(),
        lastVisitDate: json['lastVisitDate'] as String,
      );
}

class TransactionSummary {
  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String? merchant;
  final DateTime date;
  final String? regretLevel;

  const TransactionSummary({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.merchant,
    required this.date,
    this.regretLevel,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) => TransactionSummary(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currencyCode: json['currencyCode'] as String,
        category: json['category'] as String,
        merchant: json['merchant'] as String?,
        date: DateTime.parse(json['date'] as String),
        regretLevel: json['regretLevel'] as String?,
      );
}

class CategoryDetail {
  final CategoryStat stats;
  final List<TransactionSummary> recentTransactions;

  const CategoryDetail({required this.stats, required this.recentTransactions});

  factory CategoryDetail.fromJson(Map<String, dynamic> json) => CategoryDetail(
        stats: CategoryStat.fromJson(json['stats'] as Map<String, dynamic>),
        recentTransactions: (json['recentTransactions'] as List)
            .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MerchantDetail {
  final MerchantStat stats;
  final List<TransactionSummary> recentTransactions;

  const MerchantDetail({required this.stats, required this.recentTransactions});

  factory MerchantDetail.fromJson(Map<String, dynamic> json) => MerchantDetail(
        stats: MerchantStat.fromJson(json['stats'] as Map<String, dynamic>),
        recentTransactions: (json['recentTransactions'] as List)
            .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

- [ ] **Step 2: Add API constants for Insights**

In `app/lib/core/constants/api_constants.dart`, add after the `behavioralInsights` line:

```dart
// Regret Memory Insights
static const String insightsSummary = 'insights/summary';
static const String insightsCategories = 'insights/categories';
static String insightsCategoryDetail(String category) => 'insights/categories/$category';
static const String insightsMerchants = 'insights/merchants';
static String insightsMerchantDetail(String merchant) => 'insights/merchants/$merchant';
```

- [ ] **Step 3: Build Flutter to check**

```bash
cd app && flutter analyze lib/models/insights_models.dart lib/core/constants/api_constants.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/models/insights_models.dart app/lib/core/constants/api_constants.dart
git commit -m "feat: add InsightsSummary, CategoryStat, MerchantStat models and API constants"
```

---

### Task 9: Flutter insights providers

**Files:**
- Create: `app/lib/providers/insights_provider.dart`

- [ ] **Step 1: Create providers**

Create `app/lib/providers/insights_provider.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/insights_models.dart';
import 'transaction_providers.dart';

final insightsSummaryProvider = FutureProvider<InsightsSummary?>((ref) async {
  ref.watch(transactionListProvider);
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(ApiConstants.insightsSummary);
    if (response.data == null) return null;
    return InsightsSummary.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});

final insightsMerchantsProvider = FutureProvider<List<MerchantStat>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<List<dynamic>>(ApiConstants.insightsMerchants);
    return (response.data ?? [])
        .map((e) => MerchantStat.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});

final insightsCategoriesProvider = FutureProvider<List<CategoryStat>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<List<dynamic>>(ApiConstants.insightsCategories);
    return (response.data ?? [])
        .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});

final merchantDetailProvider =
    FutureProvider.family<MerchantDetail?, String>((ref, merchant) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.insightsMerchantDetail(merchant));
    if (response.data == null) return null;
    return MerchantDetail.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});

final categoryDetailProvider =
    FutureProvider.family<CategoryDetail?, String>((ref, category) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.insightsCategoryDetail(category));
    if (response.data == null) return null;
    return CategoryDetail.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});
```

- [ ] **Step 2: Analyze**

```bash
cd app && flutter analyze lib/providers/insights_provider.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/providers/insights_provider.dart
git commit -m "feat: add insights providers (summary, merchants, categories, detail)"
```

---

### Task 10: RegretSummaryCard + dashboard wiring

**Files:**
- Create: `app/lib/screens/dashboard/widgets/regret_summary_card.dart`
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`

- [ ] **Step 1: Create RegretSummaryCard**

Create `app/lib/screens/dashboard/widgets/regret_summary_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';
import '../../../providers/insights_provider.dart';

class RegretSummaryCard extends ConsumerWidget {
  const RegretSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return _buildCard(context, summary);
      },
    );
  }

  Widget _buildCard(BuildContext context, InsightsSummary summary) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currency = '£';

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: colors.onErrorContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currency${summary.regrettedAmount.toStringAsFixed(0)} regretted on ${summary.regrettedCategory}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'last 30 days · tap to see patterns',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add RegretSummaryCard to dashboard**

In `app/lib/screens/dashboard/dashboard_screen.dart`, add the import at the top:

```dart
import 'package:conscia_app/screens/dashboard/widgets/regret_summary_card.dart';
import 'package:conscia_app/providers/insights_provider.dart';
```

Find the `insightsState.when` data block where the insights cards are rendered. After the last insights sliver (after `ImpulseTrendsCard`), add a `RegretSummaryCard` in a `SliverToBoxAdapter` wrapped in `SliverPadding`:

```dart
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  sliver: SliverToBoxAdapter(
    child: const RegretSummaryCard(),
  ),
),
```

- [ ] **Step 3: Analyze**

```bash
cd app && flutter analyze lib/screens/dashboard/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/dashboard/widgets/regret_summary_card.dart \
        app/lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: add RegretSummaryCard to dashboard — glimpse of biggest regretted spend"
```

---

### Task 11: InsightsScreen + spotlight cards + routing

**Files:**
- Create: `app/lib/screens/insights/insights_screen.dart`
- Create: `app/lib/screens/insights/widgets/merchant_spotlight_card.dart`
- Create: `app/lib/screens/insights/widgets/category_trend_card.dart`
- Modify: `app/lib/core/routing/app_router.dart`

- [ ] **Step 1: Create MerchantSpotlightCard**

Create `app/lib/screens/insights/widgets/merchant_spotlight_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';

class MerchantSpotlightCard extends StatelessWidget {
  final MerchantStat merchant;

  const MerchantSpotlightCard({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rate = (merchant.regretRate * 100).toStringAsFixed(0);

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights/merchants'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🏪 Merchant to watch',
                      style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(merchant.merchant,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${merchant.regretCount} of ${merchant.visitCount} purchases regretted',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: merchant.regretRate,
                  backgroundColor: colors.surfaceVariant,
                  color: colors.error,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('$rate% regret rate',
                  style: textTheme.labelSmall?.copyWith(color: colors.error)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create CategoryTrendCard**

Create `app/lib/screens/insights/widgets/category_trend_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';

class CategoryTrendCard extends StatelessWidget {
  final CategoryStat category;

  const CategoryTrendCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currency = '£';

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights/categories'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📈 Category trend',
                      style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(category.category,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '$currency${category.regrettedSpend.toStringAsFixed(0)} regretted last 30 days',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '→ $currency${category.projectedAnnual.toStringAsFixed(0)}/year projected',
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create InsightsScreen**

Create `app/lib/screens/insights/insights_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/insights_provider.dart';
import 'widgets/category_trend_card.dart';
import 'widgets/merchant_spotlight_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    final merchantsAsync = ref.watch(insightsMerchantsProvider);
    final categoriesAsync = ref.watch(insightsCategoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Regret Patterns')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load insights.')),
        data: (summary) {
          if (summary == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Check back after your first week of tracking.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats header
              Row(
                children: [
                  _StatCell(label: 'Regretted', value: '£${summary.regrettedAmount.toStringAsFixed(0)}'),
                  _StatCell(label: 'Avg rate', value: '${(summary.avgRegretRate * 100).toStringAsFixed(0)}%'),
                  _StatCell(label: 'Patterns', value: '${summary.patternCount}'),
                ],
              ),
              const SizedBox(height: 16),

              // Merchant spotlight
              merchantsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (merchants) {
                  if (merchants.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      MerchantSpotlightCard(merchant: merchants.first),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              // Category trend
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return CategoryTrendCard(category: categories.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add routes to app_router.dart**

In `app/lib/core/routing/app_router.dart`, add imports at the top:

```dart
import '../../screens/insights/insights_screen.dart';
import '../../screens/insights/merchant_list_screen.dart';
import '../../screens/insights/merchant_detail_screen.dart';
import '../../screens/insights/category_list_screen.dart';
import '../../screens/insights/category_detail_screen.dart';
```

Add to `AppRoutes`:

```dart
static const insights = '/insights';
static const insightsMerchants = '/insights/merchants';
static String insightsMerchantDetail(String merchant) => '/insights/merchants/$merchant';
static const insightsCategories = '/insights/categories';
static String insightsCategoryDetail(String category) => '/insights/categories/$category';
```

Add inside the routes list (after the `/receipts/:id/review` route):

```dart
GoRoute(
  path: '/insights',
  builder: (context, state) => const InsightsScreen(),
),
GoRoute(
  path: '/insights/merchants',
  builder: (context, state) => const MerchantListScreen(),
),
GoRoute(
  path: '/insights/merchants/:merchant',
  builder: (context, state) =>
      MerchantDetailScreen(merchant: state.pathParameters['merchant']!),
),
GoRoute(
  path: '/insights/categories',
  builder: (context, state) => const CategoryListScreen(),
),
GoRoute(
  path: '/insights/categories/:category',
  builder: (context, state) =>
      CategoryDetailScreen(category: state.pathParameters['category']!),
),
```

- [ ] **Step 5: Commit** (screens are stubs until Tasks 12-13 — router needs them to compile)

```bash
git add app/lib/screens/insights/ app/lib/core/routing/app_router.dart
git commit -m "feat: add InsightsScreen, spotlight cards, and routing"
```

---

### Task 12: Merchant drill-down screens

**Files:**
- Create: `app/lib/screens/insights/merchant_list_screen.dart`
- Create: `app/lib/screens/insights/merchant_detail_screen.dart`

- [ ] **Step 1: Create MerchantListScreen**

Create `app/lib/screens/insights/merchant_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class MerchantListScreen extends ConsumerWidget {
  const MerchantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(insightsMerchantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Merchants')),
      body: merchantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load merchants.')),
        data: (merchants) {
          if (merchants.isEmpty) {
            return const Center(child: Text('No merchant data yet.'));
          }
          return ListView.builder(
            itemCount: merchants.length,
            itemBuilder: (context, i) => _MerchantTile(merchant: merchants[i]),
          );
        },
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final MerchantStat merchant;

  const _MerchantTile({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratePercent = (merchant.regretRate * 100).toStringAsFixed(0);
    final color = merchant.regretRate >= 0.6
        ? colors.error
        : merchant.regretRate >= 0.4
            ? colors.tertiary
            : colors.primary;

    return ListTile(
      title: Text(merchant.merchant),
      subtitle: Text('${merchant.visitCount} visits · last ${merchant.lastVisitDate}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$ratePercent%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('regret', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
      onTap: () => context.push('/insights/merchants/${merchant.merchant}'),
    );
  }
}
```

- [ ] **Step 2: Create MerchantDetailScreen**

Create `app/lib/screens/insights/merchant_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class MerchantDetailScreen extends ConsumerWidget {
  final String merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(merchantDetailProvider(merchant));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(merchant)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load data.')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('No data found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatsHeader(stats: detail.stats),
              const SizedBox(height: 16),
              Text('Recent transactions',
                  style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...detail.recentTransactions.map((t) => _TransactionRow(tx: t)),
            ],
          );
        },
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final MerchantStat stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final rate = (stats.regretRate * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(children: [
              Text('${stats.visitCount}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('visits', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
            Column(children: [
              Text('${stats.regretCount}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.error)),
              Text('regrets', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
            Column(children: [
              Text('$rate%', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.error)),
              Text('rate', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionSummary tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretEmoji = switch (tx.regretLevel?.toLowerCase()) {
      'worthit' => '✅',
      'regret' => '❌',
      'notsure' => '🤔',
      _ => '—',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(regretEmoji),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tx.category,
                style: textTheme.bodyMedium),
          ),
          Text('£${tx.amount.toStringAsFixed(2)}',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
cd app && flutter analyze lib/screens/insights/merchant_list_screen.dart lib/screens/insights/merchant_detail_screen.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/insights/merchant_list_screen.dart \
        app/lib/screens/insights/merchant_detail_screen.dart
git commit -m "feat: add MerchantListScreen and MerchantDetailScreen"
```

---

### Task 13: Category drill-down screens

**Files:**
- Create: `app/lib/screens/insights/category_list_screen.dart`
- Create: `app/lib/screens/insights/category_detail_screen.dart`

- [ ] **Step 1: Create CategoryListScreen**

Create `app/lib/screens/insights/category_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(insightsCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load categories.')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No category data yet.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryStat category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratePercent = (category.regretRate * 100).toStringAsFixed(0);
    final color = category.regretRate >= 0.6
        ? colors.error
        : category.regretRate >= 0.4
            ? colors.tertiary
            : colors.primary;

    return ListTile(
      title: Text(category.category),
      subtitle: Text('£${category.regrettedSpend.toStringAsFixed(0)} regretted · ${category.transactionCount} purchases'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$ratePercent%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('regret', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
      onTap: () => context.push('/insights/categories/${category.category}'),
    );
  }
}
```

- [ ] **Step 2: Create CategoryDetailScreen**

Create `app/lib/screens/insights/category_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(categoryDetailProvider(category));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load data.')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('No data found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CategoryStatsHeader(stats: detail.stats),
              const SizedBox(height: 16),
              Text('Recent transactions',
                  style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...detail.recentTransactions.map((t) => _TransactionRow(tx: t)),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryStatsHeader extends StatelessWidget {
  final CategoryStat stats;

  const _CategoryStatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final rate = (stats.regretRate * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('£${stats.totalSpend.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('spent', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
                Column(children: [
                  Text('£${stats.regrettedSpend.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.error)),
                  Text('regretted', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
                Column(children: [
                  Text('$rate%',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.error)),
                  Text('rate', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: colors.onErrorContainer, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '£${stats.projectedAnnual.toStringAsFixed(0)} in regretted spend projected this year',
                    style: textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionSummary tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretEmoji = switch (tx.regretLevel?.toLowerCase()) {
      'worthit' => '✅',
      'regret' => '❌',
      'notsure' => '🤔',
      _ => '—',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(regretEmoji),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tx.merchant ?? tx.category, style: textTheme.bodyMedium),
          ),
          Text('£${tx.amount.toStringAsFixed(2)}',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Full Flutter analyze**

```bash
cd app && flutter analyze lib/
```

Expected: No errors.

- [ ] **Step 4: Run all .NET unit tests**

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj -v q
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/insights/category_list_screen.dart \
        app/lib/screens/insights/category_detail_screen.dart
git commit -m "feat: add CategoryListScreen and CategoryDetailScreen with projected annual spend"
```
