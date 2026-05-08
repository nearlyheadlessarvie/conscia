# Recurring Transactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add recurring expense and income schedules that auto-create real transactions on weekly, monthly, or yearly cadences, backfill missed occurrences, and surface recurring provenance and reminders in the app.

**Architecture:** Add a dedicated recurring schedule model and repository on the backend, extend transaction storage with recurring provenance, and run schedule processing in a backend background worker that creates normal transactions idempotently. The app adds recurring controls to transaction creation, reads recurring metadata from transaction APIs, and surfaces lightweight recurring badges and alerts without changing budget math.

**Tech Stack:** ASP.NET Core minimal APIs, Dynamo-backed repositories, FluentValidation, background hosted services / existing infrastructure services, Flutter + Riverpod + Dio, widget/unit tests.

---

## File Structure

### Backend domain and persistence
- Create: `src/Conscia.Domain/Entities/RecurringSchedule.cs`
  - recurring schedule entity and cadence enum
- Modify: `src/Conscia.Domain/Entities/Transaction.cs`
  - add `RecurringScheduleId` and `RecurringOccurrenceDate`
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleRepository.cs`
  - CRUD + due-schedule query contract
- Create: `src/Conscia.Infrastructure/Repositories/RecurringScheduleRepository.cs`
  - Dynamo persistence for recurring schedules
- Modify: `src/Conscia.Infrastructure/Helpers/DynamoKeys.cs`
  - recurring keys / prefixes
- Modify: `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
  - recurring field mapping and duplicate-occurrence lookup support

### Backend application and API
- Create: `src/Conscia.Application/DTOs/CreateRecurringScheduleDto.cs`
- Create: `src/Conscia.Application/DTOs/UpdateRecurringScheduleDto.cs`
- Create: `src/Conscia.Application/DTOs/RecurringScheduleResponseDto.cs`
- Create: `src/Conscia.Application/Validators/CreateRecurringScheduleValidator.cs`
- Create: `src/Conscia.Application/Validators/UpdateRecurringScheduleValidator.cs`
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleService.cs`
- Create: `src/Conscia.Application/Services/RecurringScheduleService.cs`
- Create: `src/Conscia.Api/Endpoints/RecurringEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`
  - register service/repository/endpoints/hosted worker
- Modify: `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
  - include recurring metadata in create/list/detail/update responses
- Modify: `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
  - optional recurring schedule payload for create-from-transaction flow
- Modify: `src/Conscia.Application/Services/TransactionService.cs`
  - optionally create schedule alongside transaction when requested

### Backend recurring generation and alerts
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleGenerator.cs`
- Create: `src/Conscia.Application/Services/RecurringScheduleGenerator.cs`
  - cadence math, backfill, idempotent occurrence creation
- Create: `src/Conscia.Infrastructure/Services/RecurringScheduleProcessor.cs`
  - background worker / periodic runner
- Modify: `src/Conscia.Application/Interfaces/IInAppAlertRepository.cs`
  - if needed only for clarity; otherwise reuse as-is
- Modify: `src/Conscia.Application/Models/InAppAlert.cs`
  - reuse existing fields, no schema redesign unless needed for reminder action payloads

### Backend tests
- Create: `tests/Conscia.Tests.Unit/Application/RecurringScheduleGeneratorTests.cs`
- Create: `tests/Conscia.Tests.Unit/Application/RecurringScheduleServiceTests.cs`
- Create: `tests/Conscia.Tests.Unit/Infrastructure/RecurringScheduleRepositoryTests.cs`
- Modify: `tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs`
- Modify: `tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs`
- Create: `tests/Conscia.Tests.Unit/Api/RecurringEndpointTests.cs`

### Flutter app
- Create: `app/lib/models/recurring_schedule.dart`
- Modify: `app/lib/services/transaction_service.dart`
  - include recurring metadata on transactions and optional create payload
- Create: `app/lib/services/recurring_service.dart`
- Modify: `app/lib/providers/transaction_providers.dart`
  - recurring metadata awareness if needed for list/detail refresh
- Modify: `app/lib/providers/alert_provider.dart`
  - recognize recurring-generated alerts
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
  - recurring controls in form
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`
  - recurring badge in list
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
  - recurring provenance hint in detail
- Create: `app/lib/widgets/recurring_schedule_section.dart`
  - reusable form section
- Create: `app/lib/widgets/recurring_badge.dart`
  - reusable subtle label

### Flutter tests
- Create: `app/test/widgets/recurring_schedule_section_test.dart`
- Modify: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_list_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_detail_screen_test.dart`
- Modify: `app/test/providers/alert_provider_test.dart`

## Task 1: Add recurring domain model and transaction provenance

**Files:**
- Create: `src/Conscia.Domain/Entities/RecurringSchedule.cs`
- Modify: `src/Conscia.Domain/Entities/Transaction.cs`
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleRepository.cs`
- Modify: `src/Conscia.Infrastructure/Helpers/DynamoKeys.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
- Create: `src/Conscia.Infrastructure/Repositories/RecurringScheduleRepository.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/RecurringScheduleRepositoryTests.cs`

- [ ] **Step 1: Write the failing transaction mapping test**

```csharp
[Fact]
public async Task AddAndRead_Transaction_PreservesRecurringProvenance()
{
    var userId = Guid.NewGuid();
    var scheduleId = Guid.NewGuid();
    var occurrenceDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);
    var repo = CreateTransactionRepository();

    var transaction = new Transaction
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Type = TransactionType.Expense,
        Amount = new Money(499m, "PHP"),
        Category = "Subscriptions",
        Counterparty = "Netflix",
        Date = occurrenceDate,
        RecurringScheduleId = scheduleId,
        RecurringOccurrenceDate = occurrenceDate,
    };

    await repo.AddAsync(transaction, CancellationToken.None);
    var loaded = await repo.GetByIdAsync(userId, transaction.Id, CancellationToken.None);

    loaded.Should().NotBeNull();
    loaded!.RecurringScheduleId.Should().Be(scheduleId);
    loaded.RecurringOccurrenceDate.Should().Be(occurrenceDate);
}
```

- [ ] **Step 2: Run the mapping test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~AddAndRead_Transaction_PreservesRecurringProvenance"`

Expected: FAIL because `Transaction` does not yet have recurring provenance fields or repository mapping.

- [ ] **Step 3: Add the domain model and transaction provenance fields**

```csharp
public enum RecurringCadence
{
    Weekly = 0,
    Monthly = 1,
    Yearly = 2,
}

public class RecurringSchedule
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TransactionType Type { get; set; }
    public Money Amount { get; set; } = null!;
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime StartDate { get; set; }
    public RecurringCadence Cadence { get; set; }
    public DateTime NextRunAt { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastGeneratedAt { get; set; }
}
```

```csharp
public class Transaction
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TransactionType Type { get; set; }
    public Money Amount { get; set; } = null!;
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime Date { get; set; }
    public Location? Location { get; set; }
    public RegretLevel? RegretLevel { get; set; }
    public Guid? RecurringScheduleId { get; set; }
    public DateTime? RecurringOccurrenceDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

- [ ] **Step 4: Add repository contracts and persistence mapping**

```csharp
public interface IRecurringScheduleRepository
{
    Task<RecurringSchedule> AddAsync(RecurringSchedule schedule, CancellationToken ct = default);
    Task<RecurringSchedule?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<RecurringSchedule>> ListAsync(Guid userId, CancellationToken ct = default);
    Task UpdateAsync(RecurringSchedule schedule, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<RecurringSchedule>> ListDueAsync(DateTime nowUtc, CancellationToken ct = default);
}
```

```csharp
["recurringScheduleId"] = entity.RecurringScheduleId?.ToString(),
["recurringOccurrenceDate"] = entity.RecurringOccurrenceDate?.ToString("O"),
```

```csharp
RecurringScheduleId = item.TryGetValue("recurringScheduleId", out var scheduleIdValue) &&
                      Guid.TryParse(scheduleIdValue.AsString(), out var scheduleId)
    ? scheduleId
    : null,
RecurringOccurrenceDate = item.TryGetValue("recurringOccurrenceDate", out var occurrenceValue) &&
                          DateTime.TryParse(occurrenceValue.AsString(), out var occurrenceDate)
    ? occurrenceDate
    : null,
```

- [ ] **Step 5: Add a failing repository round-trip test for recurring schedules**

```csharp
[Fact]
public async Task AddAndGet_RecurringSchedule_RoundTripsAllCoreFields()
{
    var repo = CreateRecurringScheduleRepository();
    var userId = Guid.NewGuid();
    var startDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc);

    var schedule = new RecurringSchedule
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Type = TransactionType.Expense,
        Amount = new Money(2500m, "PHP"),
        Category = "Bills",
        Counterparty = "Internet",
        StartDate = startDate,
        Cadence = RecurringCadence.Monthly,
        NextRunAt = startDate,
        EndDate = startDate.AddMonths(6),
    };

    await repo.AddAsync(schedule, CancellationToken.None);
    var loaded = await repo.GetByIdAsync(userId, schedule.Id, CancellationToken.None);

    loaded.Should().NotBeNull();
    loaded!.Cadence.Should().Be(RecurringCadence.Monthly);
    loaded.NextRunAt.Should().Be(startDate);
    loaded.EndDate.Should().Be(startDate.AddMonths(6));
}
```

- [ ] **Step 6: Run the repository tests to verify they pass**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleRepositoryTests|FullyQualifiedName~TransactionRepositoryMappingTests"`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Domain/Entities/RecurringSchedule.cs src/Conscia.Domain/Entities/Transaction.cs src/Conscia.Application/Interfaces/IRecurringScheduleRepository.cs src/Conscia.Infrastructure/Helpers/DynamoKeys.cs src/Conscia.Infrastructure/Repositories/TransactionRepository.cs src/Conscia.Infrastructure/Repositories/RecurringScheduleRepository.cs tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs tests/Conscia.Tests.Unit/Infrastructure/RecurringScheduleRepositoryTests.cs
git commit -m "feat: add recurring schedule persistence"
```

## Task 2: Add cadence math and generation/backfill service

**Files:**
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleGenerator.cs`
- Create: `src/Conscia.Application/Services/RecurringScheduleGenerator.cs`
- Create: `tests/Conscia.Tests.Unit/Application/RecurringScheduleGeneratorTests.cs`
- Modify: `src/Conscia.Application/Models/InAppAlert.cs` (only if additional recurring reminder action fields are needed)

- [ ] **Step 1: Write the failing cadence/backfill tests**

```csharp
[Fact]
public async Task GenerateDueOccurrences_MonthlyThirtyFirst_BackfillsUsingLastDayOfShortMonth()
{
    var now = new DateTime(2026, 03, 31, 12, 0, 0, DateTimeKind.Utc);
    var schedule = MonthlySchedule(day: 31, start: new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc));
    var generator = CreateGenerator();

    var result = await generator.CalculateOccurrencesAsync(schedule, now, CancellationToken.None);

    result.Select(x => x.OccurrenceDate).Should().Equal(
        new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc),
        new DateTime(2026, 02, 28, 0, 0, 0, DateTimeKind.Utc),
        new DateTime(2026, 03, 31, 0, 0, 0, DateTimeKind.Utc));
}

[Fact]
public async Task GenerateDueOccurrences_StopsAtEndDate()
{
    var generator = CreateGenerator();
    var schedule = WeeklySchedule(
        start: new DateTime(2026, 05, 01, 0, 0, 0, DateTimeKind.Utc),
        end: new DateTime(2026, 05, 15, 0, 0, 0, DateTimeKind.Utc));

    var result = await generator.CalculateOccurrencesAsync(schedule, new DateTime(2026, 06, 01, 0, 0, 0, DateTimeKind.Utc), CancellationToken.None);

    result.Should().OnlyContain(x => x.OccurrenceDate <= schedule.EndDate);
}
```

- [ ] **Step 2: Run the generator tests to verify they fail**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleGeneratorTests"`

Expected: FAIL because the generator does not exist.

- [ ] **Step 3: Implement cadence calculation and due occurrence planning**

```csharp
public interface IRecurringScheduleGenerator
{
    Task<IReadOnlyList<GeneratedOccurrence>> CalculateOccurrencesAsync(
        RecurringSchedule schedule,
        DateTime nowUtc,
        CancellationToken ct = default);
}

public sealed record GeneratedOccurrence(DateTime OccurrenceDate);
```

```csharp
private static DateTime Advance(RecurringSchedule schedule, DateTime current)
{
    return schedule.Cadence switch
    {
        RecurringCadence.Weekly => current.AddDays(7),
        RecurringCadence.Monthly => AdvanceMonthly(schedule.StartDate, current),
        RecurringCadence.Yearly => AdvanceYearly(schedule.StartDate, current),
        _ => throw new ArgumentOutOfRangeException(nameof(schedule.Cadence)),
    };
}

private static DateTime AdvanceMonthly(DateTime anchor, DateTime current)
{
    var targetMonth = current.AddMonths(1);
    var day = Math.Min(anchor.Day, DateTime.DaysInMonth(targetMonth.Year, targetMonth.Month));
    return new DateTime(targetMonth.Year, targetMonth.Month, day, anchor.Hour, anchor.Minute, anchor.Second, DateTimeKind.Utc);
}
```

- [ ] **Step 4: Add idempotent duplicate key shape to the generator contract**

```csharp
public sealed record GeneratedOccurrence(
    DateTime OccurrenceDate,
    string DuplicateKey);
```

```csharp
var duplicateKey = $"{schedule.Id:N}:{occurrenceDate:O}";
```

- [ ] **Step 5: Run the generator tests to verify they pass**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleGeneratorTests"`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Application/Interfaces/IRecurringScheduleGenerator.cs src/Conscia.Application/Services/RecurringScheduleGenerator.cs tests/Conscia.Tests.Unit/Application/RecurringScheduleGeneratorTests.cs
git commit -m "feat: add recurring cadence generator"
```

## Task 3: Add recurring service, endpoints, and create-from-transaction flow

**Files:**
- Create: `src/Conscia.Application/DTOs/CreateRecurringScheduleDto.cs`
- Create: `src/Conscia.Application/DTOs/UpdateRecurringScheduleDto.cs`
- Create: `src/Conscia.Application/DTOs/RecurringScheduleResponseDto.cs`
- Create: `src/Conscia.Application/Validators/CreateRecurringScheduleValidator.cs`
- Create: `src/Conscia.Application/Validators/UpdateRecurringScheduleValidator.cs`
- Create: `src/Conscia.Application/Interfaces/IRecurringScheduleService.cs`
- Create: `src/Conscia.Application/Services/RecurringScheduleService.cs`
- Create: `src/Conscia.Api/Endpoints/RecurringEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
- Modify: `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
- Modify: `src/Conscia.Application/Services/TransactionService.cs`
- Test: `tests/Conscia.Tests.Unit/Application/RecurringScheduleServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/RecurringEndpointTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs`

- [ ] **Step 1: Write the failing service and API tests**

```csharp
[Fact]
public async Task CreateAsync_SetsNextRunAtToStartDate()
{
    var repo = new FakeRecurringScheduleRepository();
    var service = CreateRecurringScheduleService(repo);
    var dto = new CreateRecurringScheduleDto
    {
        Type = TransactionType.Expense,
        Amount = 999m,
        CurrencyCode = "PHP",
        Category = "Subscriptions",
        Counterparty = "Spotify",
        StartDate = new DateTime(2026, 05, 31, 0, 0, 0, DateTimeKind.Utc),
        Cadence = RecurringCadence.Monthly,
    };

    var created = await service.CreateAsync(Guid.NewGuid(), dto, CancellationToken.None);

    created.NextRunAt.Should().Be(dto.StartDate);
}
```

```csharp
[Fact]
public async Task PostRecurring_ReturnsCreatedSchedule()
{
    var client = CreateAuthorizedClient();
    var response = await client.PostAsJsonAsync("/api/v1/recurring", new
    {
        type = "Expense",
        amount = 1500,
        currencyCode = "PHP",
        category = "Bills",
        counterparty = "Water",
        startDate = "2026-05-31T00:00:00Z",
        cadence = "Monthly"
    });

    response.StatusCode.Should().Be(HttpStatusCode.Created);
}
```

- [ ] **Step 2: Run the failing tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleServiceTests|FullyQualifiedName~RecurringEndpointTests"`

Expected: FAIL because DTOs, service, and endpoints do not exist.

- [ ] **Step 3: Implement recurring DTOs, validators, and service**

```csharp
public class CreateRecurringScheduleDto
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime StartDate { get; set; }
    public RecurringCadence Cadence { get; set; }
    public DateTime? EndDate { get; set; }
}
```

```csharp
public async Task<RecurringSchedule> CreateAsync(Guid userId, CreateRecurringScheduleDto dto, CancellationToken ct = default)
{
    var schedule = new RecurringSchedule
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Type = dto.Type,
        Amount = new Money(dto.Amount, dto.CurrencyCode),
        Category = dto.Category,
        Counterparty = dto.Counterparty,
        StartDate = dto.StartDate,
        Cadence = dto.Cadence,
        NextRunAt = dto.StartDate,
        EndDate = dto.EndDate,
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
    };

    return await _repo.AddAsync(schedule, ct);
}
```

- [ ] **Step 4: Implement recurring endpoints and transaction response metadata**

```csharp
group.MapPost("/", async (
    HttpContext ctx,
    CreateRecurringScheduleDto dto,
    IRecurringScheduleService svc,
    IValidator<CreateRecurringScheduleDto> validator) =>
{
    var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
    if (!validation.IsValid) return Results.ValidationProblem(validation.ToDictionary());

    var userId = ctx.User.GetUserId();
    var schedule = await svc.CreateAsync(userId, dto, ctx.RequestAborted);
    return Results.Created($"/api/v1/recurring/{schedule.Id}", RecurringScheduleResponseDto.From(schedule));
});
```

```csharp
recurringScheduleId = txn.RecurringScheduleId,
recurringOccurrenceDate = txn.RecurringOccurrenceDate,
isRecurring = txn.RecurringScheduleId is not null,
```

- [ ] **Step 5: Extend transaction creation to optionally create a schedule**

```csharp
public class CreateTransactionDto
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime Date { get; set; }
    public RecurringOptionsDto? Recurring { get; set; }
}
```

```csharp
if (dto.Recurring is not null)
{
    await _recurringScheduleService.CreateAsync(userId, new CreateRecurringScheduleDto
    {
        Type = dto.Type,
        Amount = dto.Amount,
        CurrencyCode = dto.CurrencyCode,
        Category = dto.Category,
        Counterparty = dto.Counterparty,
        StartDate = dto.Recurring.StartDate ?? dto.Date,
        Cadence = dto.Recurring.Cadence,
        EndDate = dto.Recurring.EndDate,
    }, ct);
}
```

- [ ] **Step 6: Run the service and endpoint tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleServiceTests|FullyQualifiedName~RecurringEndpointTests|FullyQualifiedName~TransactionEndpointTests"`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/DTOs/CreateRecurringScheduleDto.cs src/Conscia.Application/DTOs/UpdateRecurringScheduleDto.cs src/Conscia.Application/DTOs/RecurringScheduleResponseDto.cs src/Conscia.Application/Validators/CreateRecurringScheduleValidator.cs src/Conscia.Application/Validators/UpdateRecurringScheduleValidator.cs src/Conscia.Application/Interfaces/IRecurringScheduleService.cs src/Conscia.Application/Services/RecurringScheduleService.cs src/Conscia.Api/Endpoints/RecurringEndpoints.cs src/Conscia.Api/Program.cs src/Conscia.Api/Endpoints/TransactionEndpoints.cs src/Conscia.Application/DTOs/CreateTransactionDto.cs src/Conscia.Application/Services/TransactionService.cs tests/Conscia.Tests.Unit/Application/RecurringScheduleServiceTests.cs tests/Conscia.Tests.Unit/Api/RecurringEndpointTests.cs tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs
git commit -m "feat: add recurring schedule api"
```

## Task 4: Add background processing, idempotent occurrence creation, and reminders

**Files:**
- Create: `src/Conscia.Infrastructure/Services/RecurringScheduleProcessor.cs`
- Modify: `src/Conscia.Application/Interfaces/ITransactionRepository.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
- Modify: `src/Conscia.Application/Services/AlertService.cs` (only if recurring reminder composition belongs there; otherwise keep reminder creation inside processor)
- Create: `tests/Conscia.Tests.Unit/Application/RecurringScheduleProcessorTests.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs` only if registration patterns overlap

- [ ] **Step 1: Write the failing processor tests**

```csharp
[Fact]
public async Task ProcessDueSchedules_BackfillsMissedOccurrences_AndCreatesReminderAlert()
{
    var userId = Guid.NewGuid();
    var schedule = MonthlySchedule(day: 31, start: new DateTime(2026, 01, 31, 0, 0, 0, DateTimeKind.Utc));
    var processor = CreateProcessor(now: new DateTime(2026, 03, 31, 12, 0, 0, DateTimeKind.Utc));

    await processor.ProcessOnceAsync(CancellationToken.None);

    TransactionRepo.CreatedTransactions.Should().HaveCount(3);
    AlertRepo.CreatedAlerts.Should().ContainSingle(a => a.TriggerName == "recurring_transaction_created");
}
```

```csharp
[Fact]
public async Task ProcessDueSchedules_SkipsDuplicateOccurrence_WhenRetrying()
{
    var processor = CreateProcessorWithExistingOccurrence();

    await processor.ProcessOnceAsync(CancellationToken.None);

    TransactionRepo.CreatedTransactions.Should().HaveCount(0);
}
```

- [ ] **Step 2: Run the processor tests to verify they fail**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleProcessorTests"`

Expected: FAIL because the processor and duplicate check do not exist.

- [ ] **Step 3: Add duplicate-occurrence lookup to the transaction repository**

```csharp
Task<bool> ExistsRecurringOccurrenceAsync(
    Guid userId,
    Guid recurringScheduleId,
    DateTime occurrenceDate,
    CancellationToken ct = default);
```

```csharp
return items.Any(t => t.RecurringScheduleId == recurringScheduleId &&
                      t.RecurringOccurrenceDate == occurrenceDate);
```

- [ ] **Step 4: Implement the recurring schedule processor**

```csharp
public async Task ProcessOnceAsync(CancellationToken ct = default)
{
    var nowUtc = _clock.UtcNow;
    var dueSchedules = await _scheduleRepository.ListDueAsync(nowUtc, ct);

    foreach (var schedule in dueSchedules)
    {
        var occurrences = await _generator.CalculateOccurrencesAsync(schedule, nowUtc, ct);
        foreach (var occurrence in occurrences)
        {
            var exists = await _transactionRepository.ExistsRecurringOccurrenceAsync(
                schedule.UserId, schedule.Id, occurrence.OccurrenceDate, ct);
            if (exists) continue;

            var transaction = BuildOccurrenceTransaction(schedule, occurrence.OccurrenceDate);
            await _transactionRepository.AddAsync(transaction, ct);
            await _alertRepository.AddAsync(BuildReminderAlert(schedule, transaction), ct);
            schedule.LastGeneratedAt = occurrence.OccurrenceDate;
        }

        schedule.NextRunAt = CalculateNextFutureRun(schedule, nowUtc);
        schedule.UpdatedAt = nowUtc;
        await _scheduleRepository.UpdateAsync(schedule, ct);
    }
}
```

- [ ] **Step 5: Register the background worker**

```csharp
builder.Services.AddSingleton<IRecurringScheduleGenerator, RecurringScheduleGenerator>();
builder.Services.AddHostedService<RecurringScheduleProcessor>();
```

- [ ] **Step 6: Run the processor tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~RecurringScheduleProcessorTests"`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Infrastructure/Services/RecurringScheduleProcessor.cs src/Conscia.Application/Interfaces/ITransactionRepository.cs src/Conscia.Infrastructure/Repositories/TransactionRepository.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Application/RecurringScheduleProcessorTests.cs
git commit -m "feat: generate recurring transaction occurrences"
```

## Task 5: Add Flutter recurring controls, badges, and alert surfacing

**Files:**
- Create: `app/lib/models/recurring_schedule.dart`
- Create: `app/lib/widgets/recurring_schedule_section.dart`
- Create: `app/lib/widgets/recurring_badge.dart`
- Create: `app/lib/services/recurring_service.dart`
- Modify: `app/lib/services/transaction_service.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/providers/alert_provider.dart`
- Test: `app/test/widgets/recurring_schedule_section_test.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_list_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`
- Test: `app/test/providers/alert_provider_test.dart`

- [ ] **Step 1: Write the failing form and badge tests**

```dart
testWidgets('shows recurring controls when make this recurring is enabled', (tester) async {
  await tester.pumpWidget(buildTransactionForm());

  await tester.tap(find.text('Make this recurring'));
  await tester.pumpAndSettle();

  expect(find.text('Weekly'), findsOneWidget);
  expect(find.text('Monthly'), findsOneWidget);
  expect(find.text('Yearly'), findsOneWidget);
  expect(find.text('End date (optional)'), findsOneWidget);
});
```

```dart
testWidgets('renders recurring badge in transaction list item', (tester) async {
  await tester.pumpWidget(buildTransactionList(
    transactions: [
      Transaction(
        id: 'tx-1',
        amount: 999,
        currencyCode: 'PHP',
        category: 'Subscriptions',
        description: 'Spotify',
        type: 'expense',
        date: DateTime(2026, 5, 31),
        recurringScheduleId: 'schedule-1',
        recurringOccurrenceDate: DateTime(2026, 5, 31),
      ),
    ],
  ));

  expect(find.text('Recurring'), findsOneWidget);
});
```

- [ ] **Step 2: Run the Flutter tests to verify they fail**

Run: `flutter test test/widgets/recurring_schedule_section_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart`

Expected: FAIL because recurring controls and metadata do not exist.

- [ ] **Step 3: Extend transaction models and create reusable recurring widgets**

```dart
class Transaction {
  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String description;
  final String type;
  final DateTime date;
  final int? regretLevel;
  final String? recurringScheduleId;
  final DateTime? recurringOccurrenceDate;

  bool get isRecurring => recurringScheduleId != null;
}
```

```dart
class RecurringDraft {
  final bool enabled;
  final String cadence;
  final DateTime? endDate;
}
```

- [ ] **Step 4: Add recurring payload support to transaction creation**

```dart
Map<String, dynamic> toJson() {
  final json = <String, dynamic>{
    'amount': amount,
    'currencyCode': currencyCode,
    'category': category,
    'counterparty': counterparty,
    'type': _capitalizeType(type),
    'date': date.toIso8601String(),
  };
  if (recurring != null && recurring!.enabled) {
    json['recurring'] = {
      'cadence': recurring!.cadence,
      if (recurring!.endDate != null) 'endDate': recurring!.endDate!.toIso8601String(),
    };
  }
  return json;
}
```

- [ ] **Step 5: Add form UI, badges, and recurring alert handling**

```dart
ScreenSection(
  title: 'Recurring',
  description: 'Create future transactions automatically on a schedule.',
  child: RecurringScheduleSection(
    enabled: _recurringEnabled,
    cadence: _recurringCadence,
    endDate: _recurringEndDate,
    onEnabledChanged: (value) => setState(() => _recurringEnabled = value),
    onCadenceChanged: (value) => setState(() => _recurringCadence = value),
    onEndDateChanged: (value) => setState(() => _recurringEndDate = value),
  ),
),
```

```dart
if (transaction.isRecurring) const RecurringBadge(),
```

```dart
if (alert.type == 'recurring_transaction_created') {
  // map remote alert into normal visible alert flow
}
```

- [ ] **Step 6: Run the Flutter tests and analyze**

Run: `flutter test test/widgets/recurring_schedule_section_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart test/providers/alert_provider_test.dart`

Run: `flutter analyze lib/services/transaction_service.dart lib/screens/transactions/transaction_form_screen.dart lib/screens/transactions/transaction_list_screen.dart lib/screens/transactions/transaction_detail_screen.dart lib/widgets/recurring_schedule_section.dart lib/widgets/recurring_badge.dart test/widgets/recurring_schedule_section_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart test/providers/alert_provider_test.dart`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/lib/models/recurring_schedule.dart app/lib/widgets/recurring_schedule_section.dart app/lib/widgets/recurring_badge.dart app/lib/services/recurring_service.dart app/lib/services/transaction_service.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/transactions/transaction_list_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/lib/providers/alert_provider.dart app/test/widgets/recurring_schedule_section_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/transactions/transaction_list_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart app/test/providers/alert_provider_test.dart
git commit -m "feat: add recurring transaction ui"
```

## Task 6: Final verification and docs touch-up

**Files:**
- Modify: `docs/implementation-tasks.md`
- Modify: `docs/README.md` only if recurring should be called out in feature status

- [ ] **Step 1: Add or update roadmap status notes**

```md
- Recurring expense/income schedules: shipped
  - weekly / monthly / yearly
  - optional end date
  - automatic occurrence generation and reminders
```

- [ ] **Step 2: Run focused backend verification**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~Recurring|FullyQualifiedName~TransactionEndpointTests"`

Expected: PASS

- [ ] **Step 3: Run focused Flutter verification**

Run: `flutter test test/widgets/recurring_schedule_section_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart test/providers/alert_provider_test.dart`

Expected: PASS

- [ ] **Step 4: Run compile/build checks**

Run: `dotnet build src/Conscia.Api/Conscia.Api.csproj`

Run: `flutter analyze`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add docs/implementation-tasks.md docs/README.md
git commit -m "docs: update recurring transactions status"
```

## Self-Review

- Spec coverage: covered domain model, provenance, cadence math, end dates, backfill, duplicate prevention, dedicated endpoints, create-from-transaction flow, recurring badges, and reminders. Future schedule-editing remains explicitly out of scope.
- Placeholder scan: removed generic “handle errors” language from tasks and named concrete tests, files, and commands for each step.
- Type consistency: plan consistently uses `RecurringScheduleId`, `RecurringOccurrenceDate`, `RecurringCadence`, `CreateRecurringScheduleDto`, and `RecurringScheduleSection`.
