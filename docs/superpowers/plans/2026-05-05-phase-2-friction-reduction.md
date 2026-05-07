# Phase 2: Friction Reduction — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add preset category chips, voice input with client-side parsing, smart purchase suggestions, and a SpeedDial FAB to reduce transaction entry time.

**Architecture:** Backend exposes two new endpoints (`GET /api/v1/suggestions/purchases`, `POST /api/v1/transactions/parse-utterance`). Flutter adds a pure-Dart `UtteranceParser`, three new widgets, two new providers, and a SpeedDial FAB. All data flows through existing Riverpod + Dio patterns.

**Tech Stack:** .NET 8 Minimal APIs, xUnit + Moq, Flutter/Dart, Riverpod 2.5, `speech_to_text`, `flutter_speed_dial`

---

## File Map

**Backend — create:**
- `src/Conscia.Application/DTOs/PurchaseSuggestionDto.cs`
- `src/Conscia.Application/Interfaces/IPurchaseSuggestionService.cs`
- `src/Conscia.Application/Services/PurchaseSuggestionService.cs`
- `src/Conscia.Api/Endpoints/SuggestionEndpoints.cs`
- `src/Conscia.Application/Models/UtteranceParseResult.cs`
- `src/Conscia.Api/Endpoints/UtteranceEndpoints.cs`
- `tests/Conscia.Tests.Unit/Application/PurchaseSuggestionServiceTests.cs`
- `tests/Conscia.Tests.Unit/Api/SuggestionEndpointTests.cs`
- `tests/Conscia.Tests.Unit/Api/UtteranceEndpointTests.cs`

**Backend — modify:**
- `src/Conscia.Application/Interfaces/IAIService.cs` — add `ParseUtteranceAsync`
- `src/Conscia.Infrastructure/Services/OllamaAIService.cs` — implement new method
- `src/Conscia.Infrastructure/Services/BedrockAIService.cs` (or equivalent prod AI service) — implement new method
- `src/Conscia.Api/Program.cs` — register service + map endpoints

**Flutter — create:**
- `app/lib/utils/utterance_parser.dart`
- `app/lib/providers/category_frequency_provider.dart`
- `app/lib/providers/purchase_suggestions_provider.dart`
- `app/lib/screens/transactions/widgets/quick_preset_chips.dart`
- `app/lib/screens/transactions/widgets/voice_input_button.dart`
- `app/lib/screens/transactions/widgets/purchase_suggestion_chips.dart`
- `app/lib/widgets/speed_dial_fab.dart`
- `app/test/utils/utterance_parser_test.dart`
- `app/test/providers/category_frequency_provider_test.dart`
- `app/test/screens/transactions/widgets/quick_preset_chips_test.dart`
- `app/test/screens/transactions/widgets/purchase_suggestion_chips_test.dart`
- `app/test/widgets/speed_dial_fab_test.dart`

**Flutter — modify:**
- `app/pubspec.yaml` — add `speech_to_text`, `flutter_speed_dial`
- `app/lib/core/constants/api_constants.dart` — add two new constants
- `app/lib/screens/transactions/transaction_form_screen.dart` — integrate all widgets
- `app/lib/widgets/main_shell.dart` — replace FAB with SpeedDial

---

## Task 1: PurchaseSuggestionService (backend)

**Files:**
- Create: `src/Conscia.Application/DTOs/PurchaseSuggestionDto.cs`
- Create: `src/Conscia.Application/Interfaces/IPurchaseSuggestionService.cs`
- Create: `src/Conscia.Application/Services/PurchaseSuggestionService.cs`
- Test: `tests/Conscia.Tests.Unit/Application/PurchaseSuggestionServiceTests.cs`

- [ ] **Step 1: Write the failing tests**

```csharp
// tests/Conscia.Tests.Unit/Application/PurchaseSuggestionServiceTests.cs
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.ValueObjects;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchaseSuggestionServiceTests
{
    private readonly Mock<ITransactionRepository> _repoMock = new();
    private readonly PurchaseSuggestionService _service;

    public PurchaseSuggestionServiceTests()
    {
        _service = new PurchaseSuggestionService(_repoMock.Object);
    }

    private static Transaction MakeTx(string merchant, decimal amount, int daysAgo = 1) => new()
    {
        Id = Guid.NewGuid(),
        UserId = Guid.NewGuid(),
        Merchant = merchant,
        Category = "Coffee",
        Amount = new Money(amount, "USD"),
        Date = DateTime.UtcNow.AddDays(-daysAgo),
    };

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsEmpty_WhenUnderThreshold()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 9).Select(i => MakeTx($"item{i}", 5m)).ToList();
        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Empty(result);
    }

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsSuggestions_WhenThresholdMet()
    {
        var userId = Guid.NewGuid();
        var txs = new List<Transaction>();
        // 10 total, 3 with same merchant
        for (int i = 0; i < 7; i++) txs.Add(MakeTx($"unique{i}", 10m));
        txs.Add(MakeTx("Starbucks", 6.50m, 1));
        txs.Add(MakeTx("Starbucks", 7.00m, 3));
        txs.Add(MakeTx("Starbucks", 6.50m, 5));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Single(result);
        Assert.Equal("Starbucks", result[0].Description);
    }

    [Fact]
    public async Task GetSuggestionsAsync_UsesMedianAmount()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Coffee Shop", 5m, 1));
        txs.Add(MakeTx("Coffee Shop", 7m, 2));
        txs.Add(MakeTx("Coffee Shop", 9m, 3));  // median = 7

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Equal(7m, result[0].Amount);
    }

    [Fact]
    public async Task GetSuggestionsAsync_SetsThisWeekLabel_WhenRecentTransaction()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Lunch Spot", 12m, 1));  // within 7 days
        txs.Add(MakeTx("Lunch Spot", 12m, 2));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Contains("this week", result[0].FrequencyLabel);
    }

    [Fact]
    public async Task GetSuggestionsAsync_SetsThisMonthLabel_WhenOlderTransaction()
    {
        var userId = Guid.NewGuid();
        var txs = Enumerable.Range(0, 8).Select(i => MakeTx($"pad{i}", 1m)).ToList();
        txs.Add(MakeTx("Old Place", 10m, 20));  // older than 7 days
        txs.Add(MakeTx("Old Place", 10m, 25));

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.Contains("this month", result[0].FrequencyLabel);
    }

    [Fact]
    public async Task GetSuggestionsAsync_ReturnsMaxFive()
    {
        var userId = Guid.NewGuid();
        var txs = new List<Transaction>();
        for (int i = 0; i < 8; i++) txs.Add(MakeTx($"pad{i}", 1m));
        for (int i = 0; i < 8; i++)
        {
            txs.Add(MakeTx($"Merchant{i}", 5m, 1));
            txs.Add(MakeTx($"Merchant{i}", 5m, 2));
        }

        _repoMock.Setup(r => r.GetByUserIdAndDateRangeAsync(userId, It.IsAny<DateTime>(), It.IsAny<DateTime>(), default))
                 .ReturnsAsync(txs);

        var result = await _service.GetSuggestionsAsync(userId);

        Assert.True(result.Count <= 5);
    }
}
```

- [ ] **Step 2: Run tests — expect compile error**

```
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~PurchaseSuggestionServiceTests" -v
```

Expected: FAIL — `PurchaseSuggestionService` not found.

- [ ] **Step 3: Create `PurchaseSuggestionDto.cs`**

```csharp
// src/Conscia.Application/DTOs/PurchaseSuggestionDto.cs
namespace Conscia.Application.DTOs;

public record PurchaseSuggestionDto(
    string Description,
    decimal Amount,
    string CurrencyCode,
    string Category,
    string FrequencyLabel
);
```

- [ ] **Step 4: Create `IPurchaseSuggestionService.cs`**

```csharp
// src/Conscia.Application/Interfaces/IPurchaseSuggestionService.cs
namespace Conscia.Application.Interfaces;

public interface IPurchaseSuggestionService
{
    Task<IReadOnlyList<PurchaseSuggestionDto>> GetSuggestionsAsync(Guid userId, CancellationToken ct = default);
}
```

- [ ] **Step 5: Create `PurchaseSuggestionService.cs`**

```csharp
// src/Conscia.Application/Services/PurchaseSuggestionService.cs
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Application.Services;

public class PurchaseSuggestionService : IPurchaseSuggestionService
{
    private readonly ITransactionRepository _repo;

    public PurchaseSuggestionService(ITransactionRepository repo)
    {
        _repo = repo;
    }

    public async Task<IReadOnlyList<PurchaseSuggestionDto>> GetSuggestionsAsync(
        Guid userId, CancellationToken ct = default)
    {
        var cutoff = DateTime.UtcNow.AddDays(-90);
        var transactions = await _repo.GetByUserIdAndDateRangeAsync(
            userId, cutoff, DateTime.UtcNow, ct);

        if (transactions.Count < 10)
            return Array.Empty<PurchaseSuggestionDto>();

        var now = DateTime.UtcNow;

        return transactions
            .Where(t => !string.IsNullOrWhiteSpace(t.Merchant))
            .GroupBy(t => t.Merchant!.Trim().ToLowerInvariant())
            .Where(g => g.Count() >= 2)
            .Select(g =>
            {
                var items = g.ToList();
                var mostRecent = items.Max(t => t.Date);
                var daysSince = (now - mostRecent).TotalDays;
                var recencyWeight = Math.Max(0.1, 1.0 - daysSince / 90.0 * 0.9);
                var score = items.Count * recencyWeight;

                var amounts = items.Select(t => t.Amount.Amount).OrderBy(a => a).ToList();
                var median = amounts.Count % 2 == 0
                    ? (amounts[amounts.Count / 2 - 1] + amounts[amounts.Count / 2]) / 2
                    : amounts[amounts.Count / 2];

                var withinWeek = items.Any(t => (now - t.Date).TotalDays <= 7);
                var label = withinWeek
                    ? $"{items.Count}× this week"
                    : $"{items.Count}× this month";

                var topCategory = items
                    .GroupBy(t => t.Category)
                    .OrderByDescending(cg => cg.Count())
                    .First().Key;

                return new
                {
                    Score = score,
                    Dto = new PurchaseSuggestionDto(
                        items.First().Merchant!.Trim(),
                        median,
                        items.First().Amount.CurrencyCode,
                        topCategory,
                        label)
                };
            })
            .OrderByDescending(x => x.Score)
            .Take(5)
            .Select(x => x.Dto)
            .ToList();
    }
}
```

- [ ] **Step 6: Run tests — expect all pass**

```
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~PurchaseSuggestionServiceTests" -v
```

Expected: 6 PASS.

- [ ] **Step 7: Commit**

```
git add src/Conscia.Application/DTOs/PurchaseSuggestionDto.cs src/Conscia.Application/Interfaces/IPurchaseSuggestionService.cs src/Conscia.Application/Services/PurchaseSuggestionService.cs tests/Conscia.Tests.Unit/Application/PurchaseSuggestionServiceTests.cs
git commit -m "feat: add PurchaseSuggestionService with threshold gate and recency ranking"
```

---

## Task 2: SuggestionEndpoints + DI registration

**Files:**
- Create: `src/Conscia.Api/Endpoints/SuggestionEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/SuggestionEndpointTests.cs`
- Modify: `src/Conscia.Api/Program.cs`

- [ ] **Step 1: Write failing endpoint tests**

```csharp
// tests/Conscia.Tests.Unit/Api/SuggestionEndpointTests.cs
using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class SuggestionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public SuggestionEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns200_WithSuggestions()
    {
        var suggestions = new List<PurchaseSuggestionDto>
        {
            new("Starbucks", 6.50m, "USD", "Coffee", "3× this week")
        };
        var mock = new Mock<IPurchaseSuggestionService>();
        mock.Setup(s => s.GetSuggestionsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(suggestions);

        var client = _factory.WithWebHostBuilder(b =>
            b.ConfigureServices(s =>
                s.AddScoped<IPurchaseSuggestionService>(_ => mock.Object)))
            .CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "test-token");

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns200Empty_WhenBelowThreshold()
    {
        var mock = new Mock<IPurchaseSuggestionService>();
        mock.Setup(s => s.GetSuggestionsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<PurchaseSuggestionDto>());

        var client = _factory.WithWebHostBuilder(b =>
            b.ConfigureServices(s =>
                s.AddScoped<IPurchaseSuggestionService>(_ => mock.Object)))
            .CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "test-token");

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetPurchaseSuggestions_Returns401_WhenUnauthenticated()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/suggestions/purchases");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
```

- [ ] **Step 2: Run tests — expect fail**

```
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~SuggestionEndpointTests" -v
```

Expected: FAIL — route not found (404).

- [ ] **Step 3: Create `SuggestionEndpoints.cs`**

```csharp
// src/Conscia.Api/Endpoints/SuggestionEndpoints.cs
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class SuggestionEndpoints
{
    public static RouteGroupBuilder MapSuggestionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/suggestions")
            .RequireAuthorization()
            .WithTags("Suggestions");

        group.MapGet("/purchases", async (HttpContext ctx, IPurchaseSuggestionService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var suggestions = await svc.GetSuggestionsAsync(userId, ct);
            return Results.Ok(suggestions);
        })
        .WithName("GetPurchaseSuggestions")
        .Produces<IReadOnlyList<PurchaseSuggestionDto>>(StatusCodes.Status200OK);

        return group;
    }
}
```

- [ ] **Step 4: Register in `Program.cs`**

In `Program.cs`, find the `// --- Services ---` block and add after `IBehavioralInsightsService`:
```csharp
builder.Services.AddScoped<IPurchaseSuggestionService, PurchaseSuggestionService>();
```

Find the `app.MapInsightsEndpoints()` line and add below it:
```csharp
app.MapSuggestionEndpoints().RequireRateLimiting("standard");
```

- [ ] **Step 5: Run tests — expect pass**

```
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~SuggestionEndpointTests" -v
```

Expected: 3 PASS.

- [ ] **Step 6: Commit**

```
git add src/Conscia.Api/Endpoints/SuggestionEndpoints.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Api/SuggestionEndpointTests.cs
git commit -m "feat: add GET /api/v1/suggestions/purchases endpoint"
```

---

## Task 3: ParseUtterance endpoint (premium-gated AI)

**Files:**
- Modify: `src/Conscia.Application/Interfaces/IAIService.cs`
- Modify: `src/Conscia.Infrastructure/Services/OllamaAIService.cs`
- Modify: production AI service (BedrockAIService or equivalent — search for `IAIService` implementations)
- Create: `src/Conscia.Application/Models/UtteranceParseResult.cs`
- Create: `src/Conscia.Api/Endpoints/UtteranceEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/UtteranceEndpointTests.cs`
- Modify: `src/Conscia.Api/Program.cs`

- [ ] **Step 1: Write failing tests**

```csharp
// tests/Conscia.Tests.Unit/Api/UtteranceEndpointTests.cs
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Microsoft.Extensions.DependencyInjection;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class UtteranceEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public UtteranceEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task ParseUtterance_Returns200_ForPremiumUser()
    {
        var parseResult = new UtteranceParseResult("Starbucks", 6.50m, "Coffee");
        var aiMock = new Mock<IAIService>();
        aiMock.Setup(s => s.ParseUtteranceAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
              .ReturnsAsync(parseResult);

        var client = _factory.WithWebHostBuilder(b =>
            b.ConfigureServices(s => s.AddScoped<IAIService>(_ => aiMock.Object)))
            .CreateClient();
        // TestWebAppFactory should configure a "premium" test token — see existing ExchangeRateEndpointTests
        // for how the test factory sets up auth. Use the same premium user token approach.
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "premium-test-token");

        var body = JsonSerializer.Serialize(new { transcript = "starbucks coffee six fifty" });
        var response = await client.PostAsync("/api/v1/transactions/parse-utterance",
            new StringContent(body, Encoding.UTF8, "application/json"));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ParseUtterance_Returns403_ForFreeUser()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "free-test-token");

        var body = JsonSerializer.Serialize(new { transcript = "coffee 5 dollars" });
        var response = await client.PostAsync("/api/v1/transactions/parse-utterance",
            new StringContent(body, Encoding.UTF8, "application/json"));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task ParseUtterance_Returns401_WhenUnauthenticated()
    {
        var client = _factory.CreateClient();

        var body = JsonSerializer.Serialize(new { transcript = "coffee 5" });
        var response = await client.PostAsync("/api/v1/transactions/parse-utterance",
            new StringContent(body, Encoding.UTF8, "application/json"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
```

- [ ] **Step 2: Create `UtteranceParseResult.cs`**

```csharp
// src/Conscia.Application/Models/UtteranceParseResult.cs
namespace Conscia.Application.Models;

public record UtteranceParseResult(
    string? Description,
    decimal? Amount,
    string? Category
);
```

- [ ] **Step 3: Add `ParseUtteranceAsync` to `IAIService.cs`**

```csharp
// src/Conscia.Application/Interfaces/IAIService.cs
using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IAIService
{
    Task<AIResponse> GeneratePrePurchaseResponseAsync(AIContext context, CancellationToken ct = default);
    Task<AIResponse> GenerateReflectionAsync(AIContext context, CancellationToken ct = default);
    Task<UtteranceParseResult> ParseUtteranceAsync(string transcript, CancellationToken ct = default);
}
```

- [ ] **Step 4: Implement in `OllamaAIService.cs`**

Find `OllamaAIService.cs` in `src/Conscia.Infrastructure/Services/`. Add this method:

```csharp
public async Task<UtteranceParseResult> ParseUtteranceAsync(string transcript, CancellationToken ct = default)
{
    var prompt = $"""
        Extract purchase details from this spoken utterance. Return ONLY valid JSON with keys:
        description (string or null), amount (number or null), category (string or null).
        Categories: Coffee, Dining, Shopping, Gaming, Travel, Transport, Entertainment, Health, Education, Utilities, Other.
        
        Utterance: "{transcript}"
        
        JSON:
        """;

    // Use the same HTTP client pattern already in this service for generating completions.
    // Send `prompt` as the user message and parse the JSON response.
    // Adapt the call below to match the existing Ollama completion request format in this file:
    var jsonResponse = await SendCompletionAsync(prompt, ct);

    try
    {
        var parsed = System.Text.Json.JsonSerializer.Deserialize<UtteranceParseResult>(
            jsonResponse,
            new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        return parsed ?? new UtteranceParseResult(transcript, null, null);
    }
    catch
    {
        return new UtteranceParseResult(transcript, null, null);
    }
}
```

> **Note:** `SendCompletionAsync` is a placeholder name — look at how `GeneratePrePurchaseResponseAsync` sends its HTTP request in this file and create a similar private helper, or call the same pattern inline.

- [ ] **Step 5: Implement in the production AI service**

Find the production IAIService implementation (search: `grep -r "IAIService" src/Conscia.Infrastructure --include="*.cs" -l`). Add the same method with the same prompt, adapted to the production client (Bedrock/etc.).

- [ ] **Step 6: Create `UtteranceEndpoints.cs`**

```csharp
// src/Conscia.Api/Endpoints/UtteranceEndpoints.cs
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Api.Endpoints;

public static class UtteranceEndpoints
{
    public static RouteGroupBuilder MapUtteranceEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/transactions")
            .RequireAuthorization()
            .WithTags("Transactions");

        group.MapPost("/parse-utterance", async (
            HttpContext ctx,
            ParseUtteranceRequest req,
            IAIService aiService,
            CancellationToken ct) =>
        {
            if (!ctx.User.IsPremium())
                return Results.Forbid();

            if (string.IsNullOrWhiteSpace(req.Transcript))
                return Results.BadRequest(new { error = "Transcript is required." });

            var result = await aiService.ParseUtteranceAsync(req.Transcript, ct);
            return Results.Ok(result);
        })
        .WithName("ParseUtterance")
        .Produces<UtteranceParseResult>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status403Forbidden)
        .Produces(StatusCodes.Status400BadRequest);

        return group;
    }
}

public record ParseUtteranceRequest(string Transcript);
```

- [ ] **Step 7: Register endpoint in `Program.cs`**

```csharp
app.MapUtteranceEndpoints().RequireRateLimiting("standard");
```

- [ ] **Step 8: Run all unit tests**

```
dotnet test tests/Conscia.Tests.Unit -v
```

Expected: All existing tests pass + new tests pass. The premium-gate tests may need the TestWebAppFactory to support a premium token claim — check how `ExchangeRateEndpointTests` sets up auth and add a `"premium-test-token"` variant if needed.

- [ ] **Step 9: Commit**

```
git add src/Conscia.Application/Interfaces/IAIService.cs src/Conscia.Application/Models/UtteranceParseResult.cs src/Conscia.Api/Endpoints/UtteranceEndpoints.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Api/UtteranceEndpointTests.cs
git commit -m "feat: add POST /api/v1/transactions/parse-utterance (premium-gated AI utterance parse)"
```

---

## Task 4: Flutter packages

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `app/lib/core/constants/api_constants.dart`

- [ ] **Step 1: Add packages to `pubspec.yaml`**

In `pubspec.yaml`, under `dependencies:`, add after `shimmer`:

```yaml
  speech_to_text: ^7.0.0
  flutter_speed_dial: ^7.0.0
```

- [ ] **Step 2: Install packages**

```
cd app && flutter pub get
```

Expected: Resolves without conflicts.

- [ ] **Step 3: Add API constants**

In `app/lib/core/constants/api_constants.dart`, add inside the class body after `behavioralInsights`:

```dart
  // Suggestions
  static const String purchaseSuggestions = 'suggestions/purchases';

  // Utterance parse (premium)
  static const String parseUtterance = 'transactions/parse-utterance';
```

- [ ] **Step 4: Commit**

```
git add app/pubspec.yaml app/pubspec.lock app/lib/core/constants/api_constants.dart
git commit -m "feat: add speech_to_text and flutter_speed_dial packages; add API constants"
```

---

## Task 5: UtteranceParser (pure Dart)

**Files:**
- Create: `app/lib/utils/utterance_parser.dart`
- Test: `app/test/utils/utterance_parser_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// app/test/utils/utterance_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/utils/utterance_parser.dart';

void main() {
  group('UtteranceParser', () {
    test('parses numeric amount with dollar sign', () {
      final r = UtteranceParser.parse('spent \$12.50 on lunch');
      expect(r.amount, 12.50);
    });

    test('parses numeric amount without dollar sign', () {
      final r = UtteranceParser.parse('coffee 5.50');
      expect(r.amount, 5.50);
    });

    test('parses spoken amount — two-word form', () {
      final r = UtteranceParser.parse('starbucks five fifty');
      expect(r.amount, 5.50);
    });

    test('parses spoken amount — single word', () {
      final r = UtteranceParser.parse('lunch twenty dollars');
      expect(r.amount, 20.0);
    });

    test('extracts category from keyword', () {
      final r = UtteranceParser.parse('starbucks latte');
      expect(r.category, 'Coffee');
    });

    test('extracts dining category', () {
      final r = UtteranceParser.parse('lunch at jollibee');
      expect(r.category, 'Dining');
    });

    test('returns null category when no keyword matches', () {
      final r = UtteranceParser.parse('xyz abc 10');
      expect(r.category, isNull);
    });

    test('returns null amount when none parseable', () {
      final r = UtteranceParser.parse('coffee at starbucks');
      expect(r.amount, isNull);
    });

    test('strips amount tokens from description', () {
      final r = UtteranceParser.parse('coffee 5.50');
      expect(r.description, isNot(contains('5.50')));
    });

    test('falls back to raw transcript when description would be empty', () {
      final r = UtteranceParser.parse('5.50');
      expect(r.description, '5.50');
    });

    test('handles empty string gracefully', () {
      final r = UtteranceParser.parse('');
      expect(r.amount, isNull);
      expect(r.category, isNull);
      expect(r.description, '');
    });
  });
}
```

- [ ] **Step 2: Run — expect fail**

```
cd app && flutter test test/utils/utterance_parser_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Create `utterance_parser.dart`**

```dart
// app/lib/utils/utterance_parser.dart

class ParseResult {
  final String description;
  final double? amount;
  final String? category;

  const ParseResult({
    required this.description,
    this.amount,
    this.category,
  });
}

class UtteranceParser {
  static const _numberWords = <String, double>{
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
    'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
    'eighty': 80, 'ninety': 90, 'hundred': 100,
    // Cent words (fractional)
    'fifty-cents': 0.50, 'fifty cents': 0.50,
    'twenty-five': 0.25, 'seventy-five': 0.75,
  };

  static const _centWords = <String, double>{
    'fifty': 0.50, 'twenty-five': 0.25, 'seventy-five': 0.75,
    'ten': 0.10, 'twenty': 0.20, 'thirty': 0.30, 'forty': 0.40,
    'sixty': 0.60, 'seventy': 0.70, 'eighty': 0.80, 'ninety': 0.90,
  };

  static const _categoryKeywords = <String, List<String>>{
    'Coffee': ['coffee', 'latte', 'espresso', 'cappuccino', 'starbucks', 'cafe', 'café', 'barista'],
    'Dining': ['lunch', 'dinner', 'breakfast', 'restaurant', 'jollibee', 'mcdo', 'mcdonald', 'food', 'meal', 'eat', 'dine', 'dining', 'fastfood', 'kfc', 'burger', 'pizza'],
    'Shopping': ['shopping', 'shopee', 'lazada', 'amazon', 'mall', 'grocery', 'groceries', 'supermarket', 'store', 'bought', 'purchase'],
    'Gaming': ['gaming', 'game', 'steam', 'playstation', 'xbox', 'nintendo', 'mobile legend', 'mlbb'],
    'Travel': ['travel', 'flight', 'airline', 'hotel', 'airbnb', 'booking', 'trip', 'vacation'],
    'Transport': ['uber', 'grab', 'taxi', 'bus', 'train', 'commute', 'transport', 'gas', 'fuel', 'toll'],
    'Entertainment': ['netflix', 'spotify', 'movie', 'cinema', 'concert', 'subscription', 'streaming'],
    'Health': ['pharmacy', 'medicine', 'doctor', 'hospital', 'clinic', 'gym', 'vitamins'],
    'Utilities': ['electricity', 'water', 'internet', 'wifi', 'phone', 'bill', 'utility'],
  };

  static ParseResult parse(String transcript) {
    if (transcript.isEmpty) {
      return const ParseResult(description: '');
    }

    var tokens = transcript.toLowerCase().split(RegExp(r'\s+'));
    final usedIndices = <int>{};

    // --- Extract amount ---
    double? amount;

    // Try regex first: $5.50 or 5.50 or 5
    final numericRegex = RegExp(r'\$?(\d+(?:\.\d{1,2})?)');
    final numericMatch = numericRegex.firstMatch(transcript);
    if (numericMatch != null) {
      amount = double.tryParse(numericMatch.group(1)!);
      // Mark matched token indices as used
      final matchStart = transcript.substring(0, numericMatch.start).split(' ').length - 1;
      usedIndices.add(matchStart.clamp(0, tokens.length - 1));
    }

    // Try spoken number if no numeric found: "five fifty", "twenty", etc.
    if (amount == null) {
      for (int i = 0; i < tokens.length; i++) {
        final word = tokens[i];
        final wholeValue = _numberWords[word];
        if (wholeValue != null) {
          // Look ahead for a cent word
          double cents = 0;
          if (i + 1 < tokens.length) {
            final nextWord = tokens[i + 1];
            final centValue = _centWords[nextWord];
            if (centValue != null && wholeValue < 100) {
              cents = centValue;
              usedIndices.add(i + 1);
            }
          }
          amount = wholeValue + cents;
          usedIndices.add(i);
          break;
        }
      }
    }

    // --- Extract category ---
    String? category;
    final lowerTranscript = transcript.toLowerCase();
    outer:
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerTranscript.contains(keyword)) {
          category = entry.key;
          // Mark keyword tokens as used
          final keyTokens = keyword.split(' ');
          for (int i = 0; i <= tokens.length - keyTokens.length; i++) {
            if (tokens.sublist(i, i + keyTokens.length).join(' ') == keyword) {
              for (int j = i; j < i + keyTokens.length; j++) {
                usedIndices.add(j);
              }
              break;
            }
          }
          break outer;
        }
      }
    }

    // --- Build description ---
    final descTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (!usedIndices.contains(i)) descTokens.add(tokens[i]);
    }
    final description = descTokens.join(' ').trim();

    return ParseResult(
      description: description.isEmpty ? transcript : description,
      amount: amount,
      category: category,
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
cd app && flutter test test/utils/utterance_parser_test.dart
```

Expected: 11 PASS.

- [ ] **Step 5: Commit**

```
git add app/lib/utils/utterance_parser.dart app/test/utils/utterance_parser_test.dart
git commit -m "feat: add UtteranceParser — client-side amount, category, and description extraction"
```

---

## Task 6: categoryFrequencyProvider

**Files:**
- Create: `app/lib/providers/category_frequency_provider.dart`
- Test: `app/test/providers/category_frequency_provider_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// app/test/providers/category_frequency_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/services/transaction_service.dart';

// Minimal Transaction factory for tests
Transaction makeTx(String category) => Transaction(
  id: 'id-$category-${DateTime.now().microsecondsSinceEpoch}',
  amount: 10,
  currencyCode: 'USD',
  category: category,
  description: 'desc',
  type: 'expense',
  date: DateTime.now(),
);

void main() {
  group('categoryFrequencyProvider', () {
    test('returns top 5 categories sorted by frequency', () {
      final txs = [
        ...List.generate(5, (_) => makeTx('Coffee')),
        ...List.generate(3, (_) => makeTx('Dining')),
        ...List.generate(2, (_) => makeTx('Shopping')),
        makeTx('Gaming'),
        makeTx('Travel'),
        makeTx('Transport'),
      ];

      final container = ProviderContainer(overrides: [
        transactionListProvider.overrideWith((ref) => TransactionListNotifier._fromList(txs)),
      ]);

      final chips = container.read(categoryFrequencyProvider);

      expect(chips.first, 'Coffee');
      expect(chips[1], 'Dining');
      expect(chips.length, 5);
    });

    test('falls back to static list when fewer than 5 distinct categories', () {
      final txs = [makeTx('Coffee'), makeTx('Coffee'), makeTx('Dining')];

      final container = ProviderContainer(overrides: [
        transactionListProvider.overrideWith((ref) => TransactionListNotifier._fromList(txs)),
      ]);

      final chips = container.read(categoryFrequencyProvider);

      expect(chips, containsAll(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']));
      expect(chips.length, 5);
    });
  });
}
```

> **Note on the test helper `TransactionListNotifier._fromList`:** You need a way to seed the notifier with a fixed list for testing. Add a private named constructor to `TransactionListNotifier` in `transaction_providers.dart`:
> ```dart
> TransactionListNotifier._fromList(List<Transaction> txs) : _service = null, _categoryFilter = null, super(TransactionListState(transactions: txs, isLoading: false, hasMore: false, currentPage: 1));
> ```
> This is test-only scaffolding — add it only if the test framework needs it. Alternatively, override `transactionListProvider` to return a state directly.

- [ ] **Step 2: Create `category_frequency_provider.dart`**

```dart
// app/lib/providers/category_frequency_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_providers.dart';

const _staticFallback = ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'];

final categoryFrequencyProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;

  final counts = <String, int>{};
  for (final tx in transactions) {
    if (tx.category.isNotEmpty) {
      counts[tx.category] = (counts[tx.category] ?? 0) + 1;
    }
  }

  final distinct = counts.keys.toList();
  if (distinct.length < 5) return _staticFallback;

  final sorted = distinct.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  return sorted.take(5).toList();
});
```

- [ ] **Step 3: Run tests**

```
cd app && flutter test test/providers/category_frequency_provider_test.dart
```

Expected: 2 PASS. (Adjust the test helper approach if the notifier constructor doesn't compile — the provider itself is the important part.)

- [ ] **Step 4: Commit**

```
git add app/lib/providers/category_frequency_provider.dart app/test/providers/category_frequency_provider_test.dart
git commit -m "feat: add categoryFrequencyProvider — dynamic top-5 with static fallback"
```

---

## Task 7: purchaseSuggestionsProvider

**Files:**
- Create: `app/lib/providers/purchase_suggestions_provider.dart`

- [ ] **Step 1: Create the provider**

```dart
// app/lib/providers/purchase_suggestions_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../providers/transaction_providers.dart';

class PurchaseSuggestion {
  final String description;
  final double amount;
  final String currencyCode;
  final String category;
  final String frequencyLabel;

  const PurchaseSuggestion({
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.frequencyLabel,
  });

  factory PurchaseSuggestion.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestion(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      category: json['category'] as String,
      frequencyLabel: json['frequencyLabel'] as String,
    );
  }
}

final purchaseSuggestionsProvider =
    FutureProvider<List<PurchaseSuggestion>>((ref) async {
  // Rebuild whenever transactions change (new tx → refresh suggestions)
  ref.watch(transactionListProvider);

  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<List<dynamic>>(ApiConstants.purchaseSuggestions);
    final data = response.data ?? [];
    return data
        .map((e) => PurchaseSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});
```

- [ ] **Step 2: Commit**

```
git add app/lib/providers/purchase_suggestions_provider.dart
git commit -m "feat: add purchaseSuggestionsProvider — fetches top-5 recurring purchase suggestions"
```

---

## Task 8: QuickPresetChips widget

**Files:**
- Create: `app/lib/screens/transactions/widgets/quick_preset_chips.dart`
- Test: `app/test/screens/transactions/widgets/quick_preset_chips_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// app/test/screens/transactions/widgets/quick_preset_chips_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';

void main() {
  testWidgets('renders all 5 chip labels', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
            ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: null,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
  });

  testWidgets('highlights selected chip', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: 'Coffee',
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ));

    final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Coffee'));
    expect(chip.selected, isTrue);
  });

  testWidgets('calls onCategorySelected when tapped', (tester) async {
    String? selected;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: null,
            onCategorySelected: (cat) => selected = cat,
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Dining'));
    expect(selected, 'Dining');
  });
}
```

- [ ] **Step 2: Create `quick_preset_chips.dart`**

```dart
// app/lib/screens/transactions/widgets/quick_preset_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/category_frequency_provider.dart';

class QuickPresetChips extends ConsumerWidget {
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const QuickPresetChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const _categoryIcons = <String, String>{
    'Coffee': '☕',
    'Dining': '🍽️',
    'Shopping': '🛍️',
    'Gaming': '🎮',
    'Travel': '✈️',
    'Transport': '🚗',
    'Entertainment': '🎬',
    'Health': '💊',
    'Utilities': '💡',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryFrequencyProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final icon = _categoryIcons[cat] ?? '📦';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$icon $cat'),
              selected: selectedCategory == cat,
              onSelected: (_) => onCategorySelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests**

```
cd app && flutter test test/screens/transactions/widgets/quick_preset_chips_test.dart
```

Expected: 3 PASS.

- [ ] **Step 4: Commit**

```
git add app/lib/screens/transactions/widgets/quick_preset_chips.dart app/test/screens/transactions/widgets/quick_preset_chips_test.dart
git commit -m "feat: add QuickPresetChips widget — dynamic top-5 category chips"
```

---

## Task 9: VoiceInputButton widget

**Files:**
- Create: `app/lib/screens/transactions/widgets/voice_input_button.dart`

- [ ] **Step 1: Create `voice_input_button.dart`**

```dart
// app/lib/screens/transactions/widgets/voice_input_button.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onTranscriptReady;

  const VoiceInputButton({super.key, required this.onTranscriptReady});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((available) {
      if (mounted) setState(() => _available = available);
    });
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _listening = false);
          widget.onTranscriptReady(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        _listening ? Icons.stop_circle_outlined : Icons.mic_outlined,
        color: _listening ? Colors.red : null,
      ),
      tooltip: _listening ? 'Stop listening' : 'Speak to fill',
      onPressed: _toggle,
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add app/lib/screens/transactions/widgets/voice_input_button.dart
git commit -m "feat: add VoiceInputButton widget — speech-to-text for description field"
```

---

## Task 10: PurchaseSuggestionChips widget

**Files:**
- Create: `app/lib/screens/transactions/widgets/purchase_suggestion_chips.dart`
- Test: `app/test/screens/transactions/widgets/purchase_suggestion_chips_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
// app/test/screens/transactions/widgets/purchase_suggestion_chips_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/purchase_suggestions_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/purchase_suggestion_chips.dart';

void main() {
  final testSuggestion = PurchaseSuggestion(
    description: 'Starbucks',
    amount: 6.50,
    currencyCode: 'USD',
    category: 'Coffee',
    frequencyLabel: '3× this week',
  );

  testWidgets('renders suggestion rows when suggestions present', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => [testSuggestion]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (_, __, ___) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Starbucks'), findsOneWidget);
    expect(find.text('3× this week'), findsOneWidget);
  });

  testWidgets('renders nothing when suggestions list is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (_, __, ___) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Your usual'), findsNothing);
  });

  testWidgets('calls onSuggestionSelected when tapped', (tester) async {
    String? desc;
    double? amt;
    String? cat;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => [testSuggestion]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (d, a, c) {
              desc = d; amt = a; cat = c;
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starbucks'));

    expect(desc, 'Starbucks');
    expect(amt, 6.50);
    expect(cat, 'Coffee');
  });
}
```

- [ ] **Step 2: Create `purchase_suggestion_chips.dart`**

```dart
// app/lib/screens/transactions/widgets/purchase_suggestion_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/purchase_suggestions_provider.dart';

typedef SuggestionCallback = void Function(
    String description, double amount, String category);

class PurchaseSuggestionChips extends ConsumerWidget {
  final SuggestionCallback onSuggestionSelected;

  const PurchaseSuggestionChips({
    super.key,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(purchaseSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your usual',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...suggestions.map((s) => _SuggestionRow(
                  suggestion: s,
                  onTap: () => onSuggestionSelected(
                      s.description, s.amount, s.category),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final PurchaseSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionRow({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(suggestion.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '${suggestion.currencyCode} ${suggestion.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Text(
              suggestion.frequencyLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests**

```
cd app && flutter test test/screens/transactions/widgets/purchase_suggestion_chips_test.dart
```

Expected: 3 PASS.

- [ ] **Step 4: Commit**

```
git add app/lib/screens/transactions/widgets/purchase_suggestion_chips.dart app/test/screens/transactions/widgets/purchase_suggestion_chips_test.dart
git commit -m "feat: add PurchaseSuggestionChips widget — one-tap recurring purchase fill"
```

---

## Task 11: Integrate widgets into TransactionFormScreen

**Files:**
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`

- [ ] **Step 1: Add imports at the top of `transaction_form_screen.dart`**

Add after the existing imports:

```dart
import '../../utils/utterance_parser.dart';
import 'widgets/quick_preset_chips.dart';
import 'widgets/voice_input_button.dart';
import 'widgets/purchase_suggestion_chips.dart';
```

- [ ] **Step 2: Add voice-listening state field**

Inside `_TransactionFormScreenState`, add after `bool _prefilled = false;`:

```dart
bool _isListening = false;
```

- [ ] **Step 3: Add `_onTranscriptReady` handler**

Inside `_TransactionFormScreenState`, add before `_submit()`:

```dart
void _onTranscriptReady(String transcript) {
  final result = UtteranceParser.parse(transcript);
  setState(() {
    if (result.description.isNotEmpty) {
      _merchantController.text = result.description;
    }
    if (result.amount != null) {
      _amountController.text = result.amount!.toStringAsFixed(2);
    }
    if (result.category != null) {
      _selectedCategory = result.category;
    }
  });
}
```

- [ ] **Step 4: Update the merchant `TextField` to include voice button suffix**

Find the existing merchant TextField in `_buildForm`:

```dart
TextField(
  controller: _merchantController,
  textCapitalization: TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Merchant (optional)',
  ),
),
```

Replace with:

```dart
TextField(
  controller: _merchantController,
  textCapitalization: TextCapitalization.words,
  onChanged: (_) => setState(() {}),
  decoration: InputDecoration(
    labelText: 'Merchant (optional)',
    suffixIcon: VoiceInputButton(
      onTranscriptReady: _onTranscriptReady,
    ),
  ),
),
```

- [ ] **Step 5: Insert suggestion chips + preset chips above CategoryPicker**

Find `CategoryPicker(` in `_buildForm` and insert above it:

```dart
if (!_isEditing) ...[
  PurchaseSuggestionChips(
    onSuggestionSelected: (desc, amount, cat) {
      setState(() {
        _merchantController.text = desc;
        _amountController.text = amount.toStringAsFixed(2);
        _selectedCategory = cat;
      });
    },
  ),
  const SizedBox(height: 8),
  Text(
    'Quick add',
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
  ),
  const SizedBox(height: 6),
  QuickPresetChips(
    selectedCategory: _selectedCategory,
    onCategorySelected: (cat) {
      setState(() => _selectedCategory = cat);
    },
  ),
  const SizedBox(height: 16),
],
```

- [ ] **Step 6: Run Flutter analyzer**

```
cd app && flutter analyze
```

Expected: No errors.

- [ ] **Step 7: Commit**

```
git add app/lib/screens/transactions/transaction_form_screen.dart
git commit -m "feat: integrate preset chips, voice input, and smart suggestions into transaction form"
```

---

## Task 12: SpeedDial FAB

**Files:**
- Create: `app/lib/widgets/speed_dial_fab.dart`
- Test: `app/test/widgets/speed_dial_fab_test.dart`
- Modify: `app/lib/widgets/main_shell.dart`

- [ ] **Step 1: Write failing widget test**

```dart
// app/test/widgets/speed_dial_fab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/widgets/speed_dial_fab.dart';

void main() {
  testWidgets('SpeedDialFab renders closed state with add icon', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/transactions/add', builder: (_, __) => const Scaffold(body: Text('add'))),
    ]);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => Scaffold(
          body: child,
          floatingActionButton: const SpeedDialFab(),
        ),
      ),
    ));

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('SpeedDialFab shows child actions when tapped', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/transactions/add', builder: (_, __) => const Scaffold(body: Text('add'))),
    ]);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => Scaffold(
          body: child,
          floatingActionButton: const SpeedDialFab(),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Ask Conscia'), findsOneWidget);
    expect(find.text('Scan Receipt'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `speed_dial_fab.dart`**

```dart
// app/lib/widgets/speed_dial_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_router.dart';

class SpeedDialFab extends StatelessWidget {
  const SpeedDialFab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: colors.secondary,
      foregroundColor: colors.onSecondary,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.photo_camera_outlined),
          label: 'Scan Receipt',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming in a future update')),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.auto_awesome_outlined),
          label: 'Ask Conscia',
          onTap: () {
            try {
              context.push(AppRoutes.assistant);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.payments_outlined),
          label: 'Add Expense',
          onTap: () => context.push(AppRoutes.addTransaction),
        ),
      ],
    );
  }
}
```

> **Note:** Check `app/lib/core/routing/app_router.dart` for the correct route constant names. `AppRoutes.assistant` is the assistant/chat screen route. If the constant doesn't exist, use the string path directly (e.g., `'/assistant'`).

- [ ] **Step 3: Run widget test**

```
cd app && flutter test test/widgets/speed_dial_fab_test.dart
```

Expected: 2 PASS.

- [ ] **Step 4: Replace FAB in `main_shell.dart`**

Add import at the top of `main_shell.dart`:

```dart
import 'speed_dial_fab.dart';
```

Find the narrow layout FAB (inside `Scaffold`):

```dart
floatingActionButton: _showFab(currentIndex)
    ? FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      )
    : null,
```

Replace with:

```dart
floatingActionButton: _showFab(currentIndex) ? const SpeedDialFab() : null,
```

Find the wide layout FAB (inside `NavigationRail.leading`):

```dart
leading: _showFab(currentIndex)
    ? FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      )
    : null,
```

Replace with:

```dart
leading: _showFab(currentIndex) ? const SpeedDialFab() : null,
```

- [ ] **Step 5: Run analyzer**

```
cd app && flutter analyze
```

Expected: No errors.

- [ ] **Step 6: Commit**

```
git add app/lib/widgets/speed_dial_fab.dart app/test/widgets/speed_dial_fab_test.dart app/lib/widgets/main_shell.dart
git commit -m "feat: replace single FAB with SpeedDial — Add Expense, Ask Conscia, Scan Receipt"
```

---

## Task 13: Final verification

- [ ] **Step 1: Run all .NET tests**

```
dotnet test tests/Conscia.Tests.Unit -v
```

Expected: All tests pass (no regressions).

- [ ] **Step 2: Run all Flutter tests**

```
cd app && flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Run Flutter analyzer**

```
cd app && flutter analyze
```

Expected: No errors.

- [ ] **Step 4: Commit if any fixes were needed**

```
git add -A
git commit -m "fix: address any final lint or test issues from Phase 2 integration"
```
