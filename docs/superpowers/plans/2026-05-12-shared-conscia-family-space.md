# Shared Conscia Family Space Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Shared Conscia as a Premium-sponsored Family Space for explicit household sharing between registered users.

**Architecture:** Add a relational Family Space membership layer, then thread explicit `Personal` / `Family` scope through shared-capable records. Keep async side effects on the existing CDK-managed Outbox Lambda path; do not add always-on production workers.

**Tech Stack:** .NET 8 minimal APIs, EF Core/PostgreSQL for users/family metadata, DynamoDB for transactions/alerts/outbox, Flutter/Riverpod for app UX, AWS CDK for Lambda/outbox infrastructure, Firebase Cloud Messaging for later device push delivery.

**MVP simplification update:** Bulk import was removed after planning review. Family Space starts from intentionally-created Family records or explicit per-record scope edits. Do not build import preview/import endpoints, DTOs, or UI.

---

## Scope And Delivery Strategy

Shared Conscia is too large for one safe code dump. Implement it as stacked PRs in this order:

1. Family domain and membership foundation.
2. Family invite API and in-app notifications.
3. Scope fields on budgets, transactions, and recurring schedules.
4. Family UI shell and Personal/Family context.
5. Family-mode AI and Journey events.
6. Outbox Lambda family events and push delivery hook.
7. Story-demo seed, docs, and release cost guardrails.

Do not implement settlement, who-owes-whom, payment requests, child approvals, or multiple family spaces.

## File Structure

### Backend Domain

- Create `src/Conscia.Domain/Entities/FamilySpace.cs`
- Create `src/Conscia.Domain/Entities/FamilyMember.cs`
- Create `src/Conscia.Domain/Entities/FamilyInvite.cs`
- Create `src/Conscia.Domain/Enums/FamilyMemberRole.cs`
- Create `src/Conscia.Domain/Enums/RecordScope.cs`
- Modify `src/Conscia.Domain/Entities/Budget.cs`
- Modify `src/Conscia.Domain/Entities/Transaction.cs`
- Modify `src/Conscia.Domain/Entities/RecurringSchedule.cs`
- Modify `src/Conscia.Domain/Enums/OutboxEventType.cs`

### Backend Application

- Create `src/Conscia.Application/DTOs/FamilySpaceDtos.cs`
- Create `src/Conscia.Application/Interfaces/IFamilySpaceRepository.cs`
- Create `src/Conscia.Application/Interfaces/IFamilySpaceService.cs`
- Create `src/Conscia.Application/Services/FamilySpaceService.cs`
- Modify `src/Conscia.Application/Interfaces/ITransactionRepository.cs`
- Modify `src/Conscia.Application/Interfaces/IBudgetRepository.cs`
- Modify `src/Conscia.Application/Interfaces/IRecurringScheduleRepository.cs`
- Modify `src/Conscia.Application/Services/TransactionService.cs`
- Modify `src/Conscia.Application/Services/BudgetService.cs`
- Modify `src/Conscia.Application/Services/RecurringScheduleService.cs`
- Modify `src/Conscia.Application/Constants/ConscienceJourneyRules.cs`

### Backend Infrastructure

- Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilySpaceConfiguration.cs`
- Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilyMemberConfiguration.cs`
- Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilyInviteConfiguration.cs`
- Modify `src/Conscia.Infrastructure/Persistence/ConsciaDbContext.cs`
- Create `src/Conscia.Infrastructure/Repositories/FamilySpaceRepository.cs`
- Modify `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
- Modify `src/Conscia.Infrastructure/Repositories/BudgetRepository.cs`
- Modify `src/Conscia.Infrastructure/Repositories/RecurringScheduleRepository.cs`
- Modify `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`

### Backend API And Infra

- Create `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Modify `src/Conscia.Api/Program.cs`
- Modify `src/Conscia.Api/Health/DynamoDbHealthCheck.cs` only if new Dynamo tables/indexes are introduced.
- Modify `infra/src/Conscia.Infra/OutboxStack.cs` only if the Lambda needs new environment variables or permissions.
- Modify `infra/tests/Conscia.Infra.Tests/StackTests.cs` if OutboxStack changes.

### Flutter

- Create `app/lib/models/family_space.dart`
- Create `app/lib/models/family_invite.dart`
- Create `app/lib/models/family_import_preview.dart`
- Create `app/lib/providers/family_space_provider.dart`
- Create `app/lib/screens/family/family_space_screen.dart`
- Create `app/lib/screens/family/family_setup_screen.dart`
- Create `app/lib/screens/family/family_invites_screen.dart`
- Create `app/lib/screens/family/family_import_screen.dart`
- Create `app/lib/widgets/scope_selector.dart`
- Modify `app/lib/core/routing/app_router.dart`
- Modify `app/lib/core/constants/api_constants.dart`
- Modify `app/lib/screens/settings/settings_screen.dart`
- Modify `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Modify `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify generated model files only through codegen when model annotations require it.

### Tests

- Create `tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs`
- Create `tests/Conscia.Tests.Unit/Api/FamilySpaceEndpointTests.cs`
- Create `tests/Conscia.Tests.Unit/Infrastructure/FamilySpaceRepositoryTests.cs`
- Modify `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`
- Modify `tests/Conscia.Tests.Unit/Application/BudgetServiceTests.cs`
- Modify `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs`
- Add Flutter widget tests under `app/test/screens/family/`

---

## Task 1: Family Domain Foundation

**Files:**
- Create: `src/Conscia.Domain/Enums/FamilyMemberRole.cs`
- Create: `src/Conscia.Domain/Enums/RecordScope.cs`
- Create: `src/Conscia.Domain/Entities/FamilySpace.cs`
- Create: `src/Conscia.Domain/Entities/FamilyMember.cs`
- Create: `src/Conscia.Domain/Entities/FamilyInvite.cs`
- Modify: `src/Conscia.Infrastructure/Persistence/ConsciaDbContext.cs`
- Create: `src/Conscia.Infrastructure/Persistence/Configurations/FamilySpaceConfiguration.cs`
- Create: `src/Conscia.Infrastructure/Persistence/Configurations/FamilyMemberConfiguration.cs`
- Create: `src/Conscia.Infrastructure/Persistence/Configurations/FamilyInviteConfiguration.cs`
- Test: `tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs`

- [ ] **Step 1: Write failing domain service tests**

Create `tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs`:

```csharp
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class FamilySpaceServiceTests
{
    private readonly Mock<IFamilySpaceRepository> _repo = new();
    private readonly Mock<ISubscriptionService> _subscriptions = new();

    private FamilySpaceService CreateService() =>
        new(_repo.Object, _subscriptions.Object, NullLogger<FamilySpaceService>.Instance);

    [Fact]
    public async Task CreateAsync_PremiumUserWithoutFamily_CreatesSpaceAndOwnerMembership()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);
        _repo.Setup(r => r.CreateWithOwnerAsync(It.IsAny<FamilySpace>(), It.IsAny<FamilyMember>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilySpace space, FamilyMember _, CancellationToken _) => space);

        var result = await CreateService().CreateAsync(userId, "Santos Household", "PHP");

        Assert.Equal("Santos Household", result.Name);
        Assert.Equal("PHP", result.CurrencyCode);
        _repo.Verify(r => r.CreateWithOwnerAsync(
            It.Is<FamilySpace>(s => s.CreatedByUserId == userId && !s.IsReadOnly),
            It.Is<FamilyMember>(m => m.UserId == userId && m.Role == FamilyMemberRole.Owner),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_FreeUser_ThrowsUpgradeRequired()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("Family Space requires Premium.", error.Message);
    }

    [Fact]
    public async Task CreateAsync_UserAlreadyInFamily_Throws()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = Guid.NewGuid() });

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("You already belong to a Family Space.", error.Message);
    }
}
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceServiceTests" --no-restore
```

Expected: compile failure because `FamilySpaceService`, `IFamilySpaceRepository`, `FamilySpace`, `FamilyMember`, and `FamilyMemberRole` do not exist.

- [ ] **Step 3: Add domain enums**

Create `src/Conscia.Domain/Enums/FamilyMemberRole.cs`:

```csharp
namespace Conscia.Domain.Enums;

public enum FamilyMemberRole
{
    Owner,
    Contributor,
    Viewer
}
```

Create `src/Conscia.Domain/Enums/RecordScope.cs`:

```csharp
namespace Conscia.Domain.Enums;

public enum RecordScope
{
    Personal,
    Family
}
```

- [ ] **Step 4: Add family entities**

Create `src/Conscia.Domain/Entities/FamilySpace.cs`:

```csharp
namespace Conscia.Domain.Entities;

public class FamilySpace
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CurrencyCode { get; set; } = "USD";
    public Guid CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PremiumGraceEndsAt { get; set; }
    public bool IsReadOnly { get; set; }
}
```

Create `src/Conscia.Domain/Entities/FamilyMember.cs`:

```csharp
using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class FamilyMember
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public Guid UserId { get; set; }
    public FamilyMemberRole Role { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}
```

Create `src/Conscia.Domain/Entities/FamilyInvite.cs`:

```csharp
using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class FamilyInvite
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public string Email { get; set; } = string.Empty;
    public FamilyMemberRole Role { get; set; }
    public Guid InvitedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? DeclinedAt { get; set; }
}
```

- [ ] **Step 5: Add repository interface**

Create `src/Conscia.Application/Interfaces/IFamilySpaceRepository.cs`:

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceRepository
{
    Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default);
    Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default);
    Task<FamilySpace> CreateWithOwnerAsync(FamilySpace space, FamilyMember owner, CancellationToken ct = default);
    Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default);
    Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default);
    Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default);
    Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default);
    Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default);
    Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default);
}
```

- [ ] **Step 6: Add application service interface and minimal service**

Create `src/Conscia.Application/Interfaces/IFamilySpaceService.cs`:

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceService
{
    Task<FamilySpace> CreateAsync(Guid userId, string name, string currencyCode, CancellationToken ct = default);
}
```

Create `src/Conscia.Application/Services/FamilySpaceService.cs`:

```csharp
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class FamilySpaceService : IFamilySpaceService
{
    private readonly IFamilySpaceRepository _repository;
    private readonly ISubscriptionService _subscriptions;
    private readonly ILogger<FamilySpaceService> _logger;

    public FamilySpaceService(
        IFamilySpaceRepository repository,
        ISubscriptionService subscriptions,
        ILogger<FamilySpaceService> logger)
    {
        _repository = repository;
        _subscriptions = subscriptions;
        _logger = logger;
    }

    public async Task<FamilySpace> CreateAsync(
        Guid userId,
        string name,
        string currencyCode,
        CancellationToken ct = default)
    {
        var premium = await _subscriptions.IsPremiumAsync(userId, ct);
        if (!premium)
            throw new InvalidOperationException("Family Space requires Premium.");

        var existingMembership = await _repository.GetMembershipByUserIdAsync(userId, ct);
        if (existingMembership is not null)
            throw new InvalidOperationException("You already belong to a Family Space.");

        var now = DateTime.UtcNow;
        var space = new FamilySpace
        {
            Id = Guid.NewGuid(),
            Name = name.Trim(),
            CurrencyCode = currencyCode.Trim().ToUpperInvariant(),
            CreatedByUserId = userId,
            CreatedAt = now
        };

        var owner = new FamilyMember
        {
            Id = Guid.NewGuid(),
            FamilySpaceId = space.Id,
            UserId = userId,
            Role = FamilyMemberRole.Owner,
            JoinedAt = now
        };

        _logger.LogInformation("Creating Family Space {FamilySpaceId} for user {UserId}", space.Id, userId);
        return await _repository.CreateWithOwnerAsync(space, owner, ct);
    }
}
```

- [ ] **Step 7: Register EF DbSets and configurations**

Modify `src/Conscia.Infrastructure/Persistence/ConsciaDbContext.cs`:

```csharp
public DbSet<FamilySpace> FamilySpaces => Set<FamilySpace>();
public DbSet<FamilyMember> FamilyMembers => Set<FamilyMember>();
public DbSet<FamilyInvite> FamilyInvites => Set<FamilyInvite>();
```

Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilySpaceConfiguration.cs`:

```csharp
using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilySpaceConfiguration : IEntityTypeConfiguration<FamilySpace>
{
    public void Configure(EntityTypeBuilder<FamilySpace> builder)
    {
        builder.ToTable("family_spaces");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).IsRequired().HasMaxLength(120);
        builder.Property(x => x.CurrencyCode).IsRequired().HasMaxLength(3);
        builder.Property(x => x.IsReadOnly).HasDefaultValue(false);
        builder.HasIndex(x => x.CreatedByUserId);
    }
}
```

Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilyMemberConfiguration.cs`:

```csharp
using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilyMemberConfiguration : IEntityTypeConfiguration<FamilyMember>
{
    public void Configure(EntityTypeBuilder<FamilyMember> builder)
    {
        builder.ToTable("family_members");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Role).HasConversion<string>().IsRequired().HasMaxLength(30);
        builder.HasIndex(x => x.UserId).IsUnique();
        builder.HasIndex(x => new { x.FamilySpaceId, x.UserId }).IsUnique();
    }
}
```

Create `src/Conscia.Infrastructure/Persistence/Configurations/FamilyInviteConfiguration.cs`:

```csharp
using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilyInviteConfiguration : IEntityTypeConfiguration<FamilyInvite>
{
    public void Configure(EntityTypeBuilder<FamilyInvite> builder)
    {
        builder.ToTable("family_invites");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Email).IsRequired().HasMaxLength(256);
        builder.Property(x => x.Role).HasConversion<string>().IsRequired().HasMaxLength(30);
        builder.HasIndex(x => new { x.FamilySpaceId, x.Email });
        builder.HasIndex(x => x.Email);
    }
}
```

- [ ] **Step 8: Run tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceServiceTests" --no-restore
```

Expected: PASS for the three foundation tests.

- [ ] **Step 9: Commit foundation**

```powershell
git add src/Conscia.Domain src/Conscia.Application/Interfaces/IFamilySpaceRepository.cs src/Conscia.Application/Interfaces/IFamilySpaceService.cs src/Conscia.Application/Services/FamilySpaceService.cs src/Conscia.Infrastructure/Persistence tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs
git commit -m "feat: add family space domain foundation"
```

---

## Task 2: Family Repository, API, And Create Flow

**Files:**
- Create: `src/Conscia.Infrastructure/Repositories/FamilySpaceRepository.cs`
- Create: `src/Conscia.Application/DTOs/FamilySpaceDtos.cs`
- Create: `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `tests/Conscia.Tests.Unit/Api/TestWebAppFactory.cs`
- Test: `tests/Conscia.Tests.Unit/Api/FamilySpaceEndpointTests.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/FamilySpaceRepositoryTests.cs`

- [ ] **Step 1: Extend the API test factory**

Modify `tests/Conscia.Tests.Unit/Api/TestWebAppFactory.cs`.

Add the mock property:

```csharp
public Mock<IFamilySpaceService> FamilySpaceServiceMock { get; } = new();
```

Add the replacement inside `ConfigureServices`:

```csharp
ReplaceService<IFamilySpaceService>(services, FamilySpaceServiceMock.Object);
```

- [ ] **Step 2: Write endpoint tests**

Create `tests/Conscia.Tests.Unit/Api/FamilySpaceEndpointTests.cs`:

```csharp
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Domain.Entities;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class FamilySpaceEndpointTests
{
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    [Fact]
    public async Task CreateFamilySpace_ValidRequest_ReturnsCreated()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.CreateAsync(UserId, "Santos Household", "PHP", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilySpace
            {
                Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                Name = "Santos Household",
                CurrencyCode = "PHP",
                CreatedByUserId = UserId
            });

        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken(UserId.ToString()));

        var response = await client.PostAsJsonAsync("/api/v1/family-space", new
        {
            name = "Santos Household",
            currencyCode = "PHP"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.Equal("Santos Household", json!["name"].ToString());
    }

    [Fact]
    public async Task CreateFamilySpace_FreeUser_ReturnsForbiddenUpgradeRequired()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.CreateAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Family Space requires Premium."));

        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken(UserId.ToString(), tier: "Free"));

        var response = await client.PostAsJsonAsync("/api/v1/family-space", new
        {
            name = "Santos Household",
            currencyCode = "PHP"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
```

- [ ] **Step 3: Run endpoint test to verify failure**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceEndpointTests" --no-restore
```

Expected: FAIL because `/api/v1/family-space` is not mapped.

- [ ] **Step 4: Add DTOs**

Create `src/Conscia.Application/DTOs/FamilySpaceDtos.cs`:

```csharp
using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public record CreateFamilySpaceDto(string Name, string CurrencyCode);

public record FamilySpaceDto(
    Guid Id,
    string Name,
    string CurrencyCode,
    bool IsReadOnly,
    string Role);

public record CreateFamilyInviteDto(string Email, FamilyMemberRole Role);
```

- [ ] **Step 5: Add EF repository**

Create `src/Conscia.Infrastructure/Repositories/FamilySpaceRepository.cs`:

```csharp
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class FamilySpaceRepository : IFamilySpaceRepository
{
    private readonly ConsciaDbContext _db;

    public FamilySpaceRepository(ConsciaDbContext db) => _db = db;

    public Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default) =>
        _db.FamilySpaces.FirstOrDefaultAsync(x => x.Id == familySpaceId, ct);

    public Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default) =>
        _db.FamilyMembers.FirstOrDefaultAsync(x => x.UserId == userId, ct);

    public async Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default) =>
        await _db.FamilyMembers
            .Where(x => x.FamilySpaceId == familySpaceId)
            .OrderBy(x => x.JoinedAt)
            .ToListAsync(ct);

    public async Task<FamilySpace> CreateWithOwnerAsync(FamilySpace space, FamilyMember owner, CancellationToken ct = default)
    {
        await _db.FamilySpaces.AddAsync(space, ct);
        await _db.FamilyMembers.AddAsync(owner, ct);
        await _db.SaveChangesAsync(ct);
        return space;
    }

    public async Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        await _db.FamilyInvites.AddAsync(invite, ct);
        await _db.SaveChangesAsync(ct);
        return invite;
    }

    public Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default) =>
        _db.FamilyInvites.FirstOrDefaultAsync(x => x.Id == inviteId, ct);

    public Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default) =>
        _db.FamilyInvites
            .Where(x => x.Email == normalizedEmail && x.AcceptedAt == null && x.DeclinedAt == null && x.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default)
    {
        await _db.FamilyMembers.AddAsync(member, ct);
        await _db.SaveChangesAsync(ct);
        return member;
    }

    public async Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        _db.FamilyInvites.Update(invite);
        await _db.SaveChangesAsync(ct);
    }

    public async Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default)
    {
        _db.FamilyMembers.Update(member);
        await _db.SaveChangesAsync(ct);
    }

    public async Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default)
    {
        var member = await _db.FamilyMembers.FirstOrDefaultAsync(x => x.Id == memberId, ct);
        if (member is null) return;
        _db.FamilyMembers.Remove(member);
        await _db.SaveChangesAsync(ct);
    }
}
```

- [ ] **Step 6: Add endpoints**

Create `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`:

```csharp
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class FamilySpaceEndpoints
{
    public static RouteGroupBuilder MapFamilySpaceEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/family-space")
            .RequireAuthorization()
            .WithTags("Family Space");

        group.MapPost("/", async (HttpContext ctx, CreateFamilySpaceDto dto, IFamilySpaceService svc) =>
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return Results.BadRequest(new { error = "Family Space name is required." });

            if (string.IsNullOrWhiteSpace(dto.CurrencyCode) || dto.CurrencyCode.Trim().Length != 3)
                return Results.BadRequest(new { error = "Currency code must be three letters." });

            try
            {
                var userId = ctx.User.GetUserId();
                var space = await svc.CreateAsync(userId, dto.Name, dto.CurrencyCode, ctx.RequestAborted);
                return Results.Created($"/api/v1/family-space/{space.Id}", new
                {
                    space.Id,
                    space.Name,
                    space.CurrencyCode,
                    space.IsReadOnly
                });
            }
            catch (InvalidOperationException ex) when (ex.Message.Contains("Premium", StringComparison.OrdinalIgnoreCase))
            {
                return Results.Json(new { error = ex.Message, upgradeRequired = true }, statusCode: 403);
            }
            catch (InvalidOperationException ex)
            {
                return Results.Conflict(new { error = ex.Message });
            }
        }).WithName("CreateFamilySpace").RequireRateLimiting("standard");

        return group;
    }
}
```

Modify `src/Conscia.Api/Program.cs`:

```csharp
builder.Services.AddScoped<IFamilySpaceRepository, FamilySpaceRepository>();
builder.Services.AddScoped<IFamilySpaceService, FamilySpaceService>();
```

Add the endpoint near the other endpoint registrations:

```csharp
app.MapFamilySpaceEndpoints().RequireRateLimiting("standard");
```

- [ ] **Step 7: Run tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceEndpointTests|FullyQualifiedName~FamilySpaceServiceTests" --no-restore
```

Expected: PASS.

- [ ] **Step 8: Generate EF migration**

Run:

```powershell
dotnet ef migrations add AddFamilySpace --project src\Conscia.Infrastructure --startup-project src\Conscia.Api
```

Expected: a migration adding `family_spaces`, `family_members`, and `family_invites`.

- [ ] **Step 9: Commit API foundation**

```powershell
git add src tests
git commit -m "feat: add family space api foundation"
```

---

## Task 3: Invites, Bell Notifications, And Pending Registration

**Files:**
- Modify: `src/Conscia.Application/Interfaces/IFamilySpaceService.cs`
- Modify: `src/Conscia.Application/Services/FamilySpaceService.cs`
- Modify: `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Modify: `src/Conscia.Domain/Enums/OutboxEventType.cs`
- Test: `tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/FamilySpaceEndpointTests.cs`

- [ ] **Step 1: Add failing invite tests**

Append to `FamilySpaceServiceTests`:

```csharp
[Fact]
public async Task InviteAsync_OwnerCreatesPendingInvite()
{
    var ownerId = Guid.NewGuid();
    var familySpaceId = Guid.NewGuid();
    _repo.Setup(r => r.GetMembershipByUserIdAsync(ownerId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new FamilyMember { UserId = ownerId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Owner });
    _repo.Setup(r => r.AddInviteAsync(It.IsAny<FamilyInvite>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((FamilyInvite invite, CancellationToken _) => invite);

    var invite = await CreateService().InviteAsync(ownerId, " Wife@Example.com ", FamilyMemberRole.Contributor);

    Assert.Equal("wife@example.com", invite.Email);
    Assert.Equal(FamilyMemberRole.Contributor, invite.Role);
    Assert.Equal(familySpaceId, invite.FamilySpaceId);
    Assert.True(invite.ExpiresAt > DateTime.UtcNow.AddDays(13));
}

[Fact]
public async Task InviteAsync_ContributorCannotInvite()
{
    var contributorId = Guid.NewGuid();
    _repo.Setup(r => r.GetMembershipByUserIdAsync(contributorId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new FamilyMember { UserId = contributorId, FamilySpaceId = Guid.NewGuid(), Role = FamilyMemberRole.Contributor });

    var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
        CreateService().InviteAsync(contributorId, "wife@example.com", FamilyMemberRole.Contributor));

    Assert.Equal("Only Family Space owners can invite members.", error.Message);
}
```

- [ ] **Step 2: Run failing invite tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceServiceTests" --no-restore
```

Expected: compile failure because `InviteAsync` does not exist.

- [ ] **Step 3: Extend service contract**

Modify `src/Conscia.Application/Interfaces/IFamilySpaceService.cs`:

```csharp
Task<FamilyInvite> InviteAsync(Guid inviterUserId, string email, FamilyMemberRole role, CancellationToken ct = default);
Task<FamilyMember> AcceptInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
Task DeclineInviteAsync(Guid userId, string email, Guid inviteId, CancellationToken ct = default);
```

- [ ] **Step 4: Implement invite service methods**

Add to `FamilySpaceService`:

```csharp
public async Task<FamilyInvite> InviteAsync(
    Guid inviterUserId,
    string email,
    FamilyMemberRole role,
    CancellationToken ct = default)
{
    var inviter = await _repository.GetMembershipByUserIdAsync(inviterUserId, ct)
        ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

    if (inviter.Role != FamilyMemberRole.Owner)
        throw new UnauthorizedAccessException("Only Family Space owners can invite members.");

    if (role == FamilyMemberRole.Owner)
        throw new InvalidOperationException("Invite members as Contributor or Viewer first, then promote after they join.");

    var normalizedEmail = NormalizeEmail(email);
    var invite = new FamilyInvite
    {
        Id = Guid.NewGuid(),
        FamilySpaceId = inviter.FamilySpaceId,
        Email = normalizedEmail,
        Role = role,
        InvitedByUserId = inviterUserId,
        CreatedAt = DateTime.UtcNow,
        ExpiresAt = DateTime.UtcNow.AddDays(14)
    };

    return await _repository.AddInviteAsync(invite, ct);
}

private static string NormalizeEmail(string email)
{
    if (string.IsNullOrWhiteSpace(email))
        throw new InvalidOperationException("Invite email is required.");
    return email.Trim().ToLowerInvariant();
}
```

- [ ] **Step 5: Add invite endpoints**

Add to `FamilySpaceEndpoints`:

```csharp
group.MapPost("/invites", async (HttpContext ctx, CreateFamilyInviteDto dto, IFamilySpaceService svc) =>
{
    try
    {
        var invite = await svc.InviteAsync(ctx.User.GetUserId(), dto.Email, dto.Role, ctx.RequestAborted);
        return Results.Created($"/api/v1/family-space/invites/{invite.Id}", new
        {
            invite.Id,
            invite.Email,
            Role = invite.Role.ToString(),
            invite.ExpiresAt
        });
    }
    catch (UnauthorizedAccessException ex)
    {
        return Results.Json(new { error = ex.Message }, statusCode: 403);
    }
    catch (InvalidOperationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).WithName("CreateFamilyInvite").RequireRateLimiting("standard");
```

- [ ] **Step 6: Add outbox event type for family invite**

Modify `src/Conscia.Domain/Enums/OutboxEventType.cs`:

```csharp
FamilyInviteCreated
```

Modify `FamilySpaceService` to inject `IOutboxEventRepository`.

After `AddInviteAsync` succeeds, write a `FamilyInviteCreated` event to the existing `OutboxEvents` table. If the outbox write fails, log and rethrow so the invite request does not silently succeed without a notification event.

Use this payload:

```csharp
var outboxEvent = new OutboxEvent
{
    Id = Guid.NewGuid(),
    AggregateId = invite.Id,
    EventType = OutboxEventType.FamilyInviteCreated,
    Payload = JsonSerializer.Serialize(new
    {
        InviteId = invite.Id,
        FamilySpaceId = invite.FamilySpaceId,
        Email = invite.Email,
        Role = invite.Role.ToString(),
        InvitedByUserId = invite.InvitedByUserId,
        ExpiresAt = invite.ExpiresAt
    }),
    CreatedAt = DateTime.UtcNow
};

await _outboxEvents.AddAsync(outboxEvent, ct);
```

This is not a cross-store transaction because invites are relational and current outbox storage is DynamoDB. The deliberate MVP behavior is fail-fast on outbox write failure instead of silently creating an invite that cannot notify.

- [ ] **Step 7: Run invite tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceServiceTests|FullyQualifiedName~FamilySpaceEndpointTests" --no-restore
```

Expected: PASS.

- [ ] **Step 8: Commit invites**

```powershell
git add src tests
git commit -m "feat: add family space invites"
```

---

## Task 4: Record Scope On Transactions, Budgets, And Recurring Schedules

**Files:**
- Modify: `src/Conscia.Domain/Entities/Transaction.cs`
- Modify: `src/Conscia.Domain/Entities/Budget.cs`
- Modify: `src/Conscia.Domain/Entities/RecurringSchedule.cs`
- Modify: `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
- Modify: `src/Conscia.Application/DTOs/CreateBudgetDto.cs`
- Modify: `src/Conscia.Application/DTOs/CreateRecurringScheduleDto.cs`
- Modify: repositories and services for create/list/update authorization.
- Test: transaction, budget, recurring service tests.

- [ ] **Step 1: Add failing transaction scope test**

Append to `TransactionServiceTests`:

```csharp
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

    _repoMock.Setup(r => r.AddWithOutboxAsync(It.IsAny<Transaction>(), It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken _) => t);

    var result = await _service.CreateAsync(userId, dto);

    Assert.Equal(RecordScope.Family, result.Scope);
    Assert.Equal(familySpaceId, result.FamilySpaceId);
    Assert.Equal(userId, result.SharedByUserId);
    Assert.NotNull(result.SharedAt);
}
```

- [ ] **Step 2: Run failing scope test**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~TransactionServiceTests.CreateAsync_FamilyScope" --no-restore
```

Expected: compile failure because transaction scope fields do not exist.

- [ ] **Step 3: Add shared fields to domain entities**

Add to `Transaction`, `Budget`, and `RecurringSchedule`:

```csharp
public RecordScope Scope { get; set; } = RecordScope.Personal;
public Guid? FamilySpaceId { get; set; }
public DateTime? SharedAt { get; set; }
public Guid? SharedByUserId { get; set; }
```

Add `using Conscia.Domain.Enums;` where needed.

- [ ] **Step 4: Add DTO scope fields**

Add to create/update DTOs for transactions, budgets, and recurring schedules:

```csharp
public RecordScope Scope { get; set; } = RecordScope.Personal;
public Guid? FamilySpaceId { get; set; }
```

For update DTOs:

```csharp
public RecordScope? Scope { get; set; }
public Guid? FamilySpaceId { get; set; }
```

- [ ] **Step 5: Set metadata in services**

In each create service, when `Scope == RecordScope.Family`, set:

```csharp
FamilySpaceId = dto.FamilySpaceId ?? throw new InvalidOperationException("Family Space is required for Family records.");
Scope = RecordScope.Family;
SharedAt = DateTime.UtcNow;
SharedByUserId = userId;
```

When `Scope == RecordScope.Personal`, set:

```csharp
FamilySpaceId = null;
SharedAt = null;
SharedByUserId = null;
```

- [ ] **Step 6: Update repository mappings**

For Dynamo-backed records, add attributes:

```csharp
["Scope"] = new(transaction.Scope.ToString()),
["FamilySpaceId"] = transaction.FamilySpaceId is null ? new AttributeValue { NULL = true } : new AttributeValue { S = transaction.FamilySpaceId.Value.ToString() },
["SharedAt"] = transaction.SharedAt is null ? new AttributeValue { NULL = true } : new AttributeValue { S = transaction.SharedAt.Value.ToString("O") },
["SharedByUserId"] = transaction.SharedByUserId is null ? new AttributeValue { NULL = true } : new AttributeValue { S = transaction.SharedByUserId.Value.ToString() }
```

When reading, default missing `Scope` to `RecordScope.Personal` for backwards compatibility.

- [ ] **Step 7: Add family query methods**

Add to `ITransactionRepository`:

```csharp
Task<IReadOnlyList<Transaction>> GetByFamilySpaceAndDateRangeAsync(Guid familySpaceId, DateTime from, DateTime to, CancellationToken ct = default);
```

Add to budget and recurring repositories:

```csharp
Task<IReadOnlyList<Budget>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default);
Task<IReadOnlyList<RecurringSchedule>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default);
```

- [ ] **Step 8: Run focused tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~TransactionServiceTests|FullyQualifiedName~BudgetServiceTests|FullyQualifiedName~RecurringSchedule" --no-restore
```

Expected: PASS.

- [ ] **Step 9: Commit scoped records**

```powershell
git add src tests
git commit -m "feat: add personal and family record scope"
```

---

## Task 5: Superseded - Family Import Preview And Import

**Status:** Superseded for MVP. Do not implement.

Family import was removed because it creates confusing ownership, budget, recurring-schedule, privacy, and insight edge cases. Existing personal records stay personal unless the user explicitly changes a supported individual record to Family. The historical steps below are retained only as context for why this was cut.

**Files:**
- Create: `src/Conscia.Application/DTOs/FamilyImportDtos.cs`
- Modify: `src/Conscia.Application/Interfaces/IFamilySpaceService.cs`
- Modify: `src/Conscia.Application/Services/FamilySpaceService.cs`
- Modify: `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Application/FamilySpaceServiceTests.cs`

- [ ] **Step 1: Write failing import preview test**

Add to `FamilySpaceServiceTests`:

```csharp
[Fact]
public async Task PreviewImportAsync_ContributorCanPreviewOwnCurrentMonthRecords()
{
    var userId = Guid.NewGuid();
    var familySpaceId = Guid.NewGuid();
    _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = familySpaceId, Role = FamilyMemberRole.Contributor });

    var preview = await CreateService().PreviewImportAsync(userId, new FamilyImportPreviewRequestDto(
        IncludeTransactions: true,
        IncludeBudgets: true,
        IncludeRecurringSchedules: true,
        From: new DateTime(2026, 5, 1),
        To: new DateTime(2026, 5, 31),
        Categories: ["Dining"]));

    Assert.Equal(familySpaceId, preview.FamilySpaceId);
    Assert.Contains("These records will become visible", preview.Warning);
}
```

- [ ] **Step 2: Add DTOs**

Create `src/Conscia.Application/DTOs/FamilyImportDtos.cs`:

```csharp
namespace Conscia.Application.DTOs;

public record FamilyImportPreviewRequestDto(
    bool IncludeTransactions,
    bool IncludeBudgets,
    bool IncludeRecurringSchedules,
    DateTime? From,
    DateTime? To,
    IReadOnlyList<string> Categories);

public record FamilyImportPreviewDto(
    Guid FamilySpaceId,
    string Warning,
    IReadOnlyList<FamilyImportItemDto> Items);

public record FamilyImportItemDto(
    string RecordType,
    Guid RecordId,
    string Label,
    string? Category,
    decimal? Amount,
    string? CurrencyCode);

public record FamilyImportRequestDto(IReadOnlyList<FamilyImportSelectionDto> Items);

public record FamilyImportSelectionDto(string RecordType, Guid RecordId);
```

- [ ] **Step 3: Add service methods**

Add to `IFamilySpaceService`:

```csharp
Task<FamilyImportPreviewDto> PreviewImportAsync(Guid userId, FamilyImportPreviewRequestDto request, CancellationToken ct = default);
Task<int> ImportAsync(Guid userId, FamilyImportRequestDto request, CancellationToken ct = default);
```

Implement membership guard in `FamilySpaceService`:

```csharp
private async Task<FamilyMember> RequireContributorAsync(Guid userId, CancellationToken ct)
{
    var member = await _repository.GetMembershipByUserIdAsync(userId, ct)
        ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

    if (member.Role == FamilyMemberRole.Viewer)
        throw new UnauthorizedAccessException("Viewer cannot share records.");

    return member;
}
```

Use the warning string:

```csharp
private const string ImportWarning =
    "These records will become visible to your Family Space. They stay in your Personal timeline with a Family badge.";
```

- [ ] **Step 4: Add endpoints**

Add to `FamilySpaceEndpoints`:

```csharp
group.MapPost("/import-preview", async (HttpContext ctx, FamilyImportPreviewRequestDto dto, IFamilySpaceService svc) =>
{
    try
    {
        return Results.Ok(await svc.PreviewImportAsync(ctx.User.GetUserId(), dto, ctx.RequestAborted));
    }
    catch (UnauthorizedAccessException ex)
    {
        return Results.Json(new { error = ex.Message }, statusCode: 403);
    }
}).WithName("PreviewFamilyImport");

group.MapPost("/import", async (HttpContext ctx, FamilyImportRequestDto dto, IFamilySpaceService svc) =>
{
    try
    {
        var count = await svc.ImportAsync(ctx.User.GetUserId(), dto, ctx.RequestAborted);
        return Results.Ok(new { imported = count });
    }
    catch (UnauthorizedAccessException ex)
    {
        return Results.Json(new { error = ex.Message }, statusCode: 403);
    }
}).WithName("ImportFamilyRecords");
```

- [ ] **Step 5: Run import tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~FamilySpaceServiceTests" --no-restore
```

Expected: PASS.

- [ ] **Step 6: Commit import flow**

```powershell
git add src tests
git commit -m "feat: add family record import flow"
```

---

## Task 6: Flutter Family Space Shell

**Files:**
- Create: `app/lib/models/family_space.dart`
- Create: `app/lib/providers/family_space_provider.dart`
- Create: `app/lib/widgets/scope_selector.dart`
- Create: `app/lib/screens/family/family_setup_screen.dart`
- Create: `app/lib/screens/family/family_space_screen.dart`
- Modify: `app/lib/core/constants/api_constants.dart`
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Test: `app/test/screens/family/family_setup_screen_test.dart`

- [ ] **Step 1: Add API constants**

Modify `app/lib/core/constants/api_constants.dart`:

```dart
static const String familySpace = 'family-space';
static const String familyInvites = 'family-space/invites';
static const String familyImportPreview = 'family-space/import-preview';
static const String familyImport = 'family-space/import';
```

- [ ] **Step 2: Add model**

Create `app/lib/models/family_space.dart`:

```dart
class FamilySpace {
  final String id;
  final String name;
  final String currencyCode;
  final bool isReadOnly;
  final String role;

  const FamilySpace({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.isReadOnly,
    required this.role,
  });

  factory FamilySpace.fromJson(Map<String, dynamic> json) {
    return FamilySpace(
      id: json['id'] as String,
      name: json['name'] as String,
      currencyCode: json['currencyCode'] as String,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      role: json['role'] as String? ?? 'Owner',
    );
  }
}
```

- [ ] **Step 3: Add provider**

Create `app/lib/providers/family_space_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/family_space.dart';

final familySpaceProvider = FutureProvider<FamilySpace?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familySpace);
  if (response.statusCode == 204 || response.data == null) return null;
  return FamilySpace.fromJson(response.data as Map<String, dynamic>);
});

final selectedScopeProvider = StateProvider<String>((ref) => 'personal');
```

- [ ] **Step 4: Add reusable scope selector**

Create `app/lib/widgets/scope_selector.dart`:

```dart
import 'package:flutter/material.dart';

class ScopeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool familyEnabled;

  const ScopeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.familyEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'personal', label: Text('Personal')),
        ButtonSegment(value: 'family', label: Text('Family')),
      ],
      selected: {familyEnabled ? value : 'personal'},
      onSelectionChanged: familyEnabled
          ? (selection) => onChanged(selection.first)
          : null,
    );
  }
}
```

- [ ] **Step 5: Add setup screen**

Create `app/lib/screens/family/family_setup_screen.dart` with:

```dart
class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}
```

The screen must show:

- Title: `Create Family Space`
- Text: `Family Space shares household planning, not private accounts.`
- Inputs for name and currency.
- Premium note: `Requires Premium to create. Invited members can participate free.`
- Button: `Create Family Space`

- [ ] **Step 6: Add routes**

Modify `app/lib/core/routing/app_router.dart`:

```dart
static const familySpace = '/family-space';
static const familySetup = '/family-space/setup';
```

Add routes to `GoRouter`.

- [ ] **Step 7: Add Settings entry**

Modify `app/lib/screens/settings/settings_screen.dart` to add a row:

```dart
ListTile(
  leading: const Icon(Icons.group_outlined),
  title: const Text('Shared Conscia'),
  subtitle: const Text('Create or manage your Family Space'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push(AppRoutes.familySpace),
)
```

- [ ] **Step 8: Run Flutter analyzer**

Run:

```powershell
cd app
flutter analyze lib/models/family_space.dart lib/providers/family_space_provider.dart lib/widgets/scope_selector.dart lib/screens/family/family_setup_screen.dart lib/screens/family/family_space_screen.dart lib/core/routing/app_router.dart lib/screens/settings/settings_screen.dart
```

Expected: no issues.

- [ ] **Step 9: Commit Flutter shell**

```powershell
git add app/lib
git commit -m "feat: add family space flutter shell"
```

---

## Task 7: Notifications, Outbox Lambda, And Push Hook

**Files:**
- Modify: `src/Conscia.Domain/Enums/OutboxEventType.cs`
- Modify: `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
- Create: `src/Conscia.Application/Interfaces/IPushNotificationSender.cs`
- Create: `src/Conscia.Infrastructure/Services/NoopPushNotificationSender.cs`
- Test: `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs`
- Modify: `infra/src/Conscia.Infra/OutboxStack.cs` only if adding FCM secret env var.
- Modify: `infra/tests/Conscia.Infra.Tests/StackTests.cs` if infra changes.

- [ ] **Step 1: Add failing outbox processor test**

Add to `OutboxProcessorTests`:

```csharp
[Fact]
public async Task ProcessBatchAsync_FamilyInviteCreated_SendsPushBestEffort()
{
    var evt = new OutboxEvent
    {
        Id = Guid.NewGuid(),
        AggregateId = Guid.NewGuid(),
        EventType = OutboxEventType.FamilyInviteCreated,
        Payload = JsonSerializer.Serialize(new
        {
            InviteId = Guid.NewGuid(),
            Email = "wife@example.com",
            FamilySpaceName = "Santos Household",
            InvitedByUserId = Guid.NewGuid()
        }),
        CreatedAt = DateTime.UtcNow
    };

    _outboxRepoMock.Setup(r => r.GetPendingAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync([evt]);
    _outboxRepoMock.Setup(r => r.TryStartProcessingAsync(evt, It.IsAny<CancellationToken>()))
        .ReturnsAsync(true);

    await CreateProcessor().ProcessBatchAsync(CancellationToken.None);

    _outboxRepoMock.Verify(r => r.MarkProcessedAsync(evt, It.IsAny<CancellationToken>()), Times.Once);
}
```

- [ ] **Step 2: Add push sender interface**

Create `src/Conscia.Application/Interfaces/IPushNotificationSender.cs`:

```csharp
namespace Conscia.Application.Interfaces;

public interface IPushNotificationSender
{
    Task SendToUserAsync(Guid userId, string title, string body, string? route, CancellationToken ct = default);
}
```

Create `src/Conscia.Infrastructure/Services/NoopPushNotificationSender.cs`:

```csharp
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class NoopPushNotificationSender : IPushNotificationSender
{
    private readonly ILogger<NoopPushNotificationSender> _logger;

    public NoopPushNotificationSender(ILogger<NoopPushNotificationSender> logger)
    {
        _logger = logger;
    }

    public Task SendToUserAsync(Guid userId, string title, string body, string? route, CancellationToken ct = default)
    {
        _logger.LogInformation("Push sender not configured. Skipping push to user {UserId}: {Title}", userId, title);
        return Task.CompletedTask;
    }
}
```

- [ ] **Step 3: Register no-op sender**

Modify `src/Conscia.Api/Program.cs`:

```csharp
builder.Services.AddScoped<IPushNotificationSender, NoopPushNotificationSender>();
```

- [ ] **Step 4: Process family invite event**

In `OutboxProcessor`, add a `FamilyInviteCreated` case that:

- Parses `InviteId`, `Email`, `FamilySpaceName`, and optional `InvitedUserId`.
- Creates or confirms an in-app alert for an existing invited user.
- Calls `IPushNotificationSender.SendToUserAsync` only when an invited user id is known.
- Marks processed even when push sender is no-op.

Use title/body:

```csharp
const string title = "Family invite";
var body = $"You were invited to {familySpaceName}.";
var route = "/family-space/invites";
```

- [ ] **Step 5: Keep infra as-is unless real FCM sender lands**

If this task only adds no-op push sending, do not modify `infra/src/Conscia.Infra/OutboxStack.cs`.

If a real FCM sender is implemented in the same PR, add a Secrets Manager reference and environment variable:

```csharp
["FCM_CREDENTIALS_SECRET_NAME"] = props.FcmCredentialsSecret.SecretName
```

Then add infra test assertions in `StackTests`.

- [ ] **Step 6: Run tests**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~OutboxProcessorTests" --no-restore
```

Expected: PASS.

- [ ] **Step 7: Commit notification hook**

```powershell
git add src tests infra
git commit -m "feat: add family invite notification outbox hook"
```

---

## Task 8: Family AI Context And Journey Events

**Files:**
- Modify: `src/Conscia.Application/Services/PurchaseSuggestionService.cs`
- Modify: `src/Conscia.Application/DTOs/PurchaseSuggestionDtos.cs`
- Modify: `src/Conscia.Application/Constants/ConscienceJourneyRules.cs`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Test: purchase suggestion tests and journey rules tests.

- [ ] **Step 1: Add explicit AI context DTO field**

Add to pre-purchase request DTO:

```csharp
public string ContextScope { get; set; } = "personal";
```

Accepted values:

- `personal`
- `family`

- [ ] **Step 2: Guard family context**

In `PurchaseSuggestionService`, before loading family context:

```csharp
if (string.Equals(dto.ContextScope, "family", StringComparison.OrdinalIgnoreCase))
{
    var membership = await _familySpaceRepository.GetMembershipByUserIdAsync(userId, ct);
    if (membership is null)
        throw new UnauthorizedAccessException("Family advice requires a Family Space.");
}
```

- [ ] **Step 3: Build compact family context**

Family prompt context must include only compact summaries:

```text
Family context:
- Shared monthly budget statuses by category.
- Current month family contributions total.
- Current month family expenses total.
- Active family recurring obligations count and total.
- Recent family insight summary.
```

Do not send full transaction history.

- [ ] **Step 4: Add Journey events**

Add event types in `ConscienceJourneyRules`:

```csharp
["family_invite_sent"] = 15,
["family_invite_accepted"] = 20,
["family_expense_added"] = 10,
["family_contribution_added"] = 15,
["family_purchase_checked"] = 20
```

Add badges:

- `family_founder`
- `household_contributor`
- `family_planner`

- [ ] **Step 5: Add Flutter Personal/Family toggle in pre-purchase**

In `pre_purchase_screen.dart`, show `ScopeSelector` when `familySpaceProvider` has a value. Send:

```dart
'contextScope': selectedScope,
```

Make the response header display:

```dart
selectedScope == 'family' ? 'Family advice' : 'Personal advice'
```

- [ ] **Step 6: Run checks**

Run:

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~PurchaseSuggestion|FullyQualifiedName~ConscienceJourney" --no-restore
cd app
flutter analyze lib/screens/assistant/pre_purchase_screen.dart lib/widgets/scope_selector.dart
```

Expected: PASS/no issues.

- [ ] **Step 7: Commit family AI/Journey**

```powershell
git add src app/lib tests
git commit -m "feat: add family context to ai and journey"
```

---

## Task 9: Story Demo Seed And Documentation

**Files:**
- Modify: `tools/Seeder`
- Modify: `docs/README.md`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-12-shared-conscia-family-space-design.md` only if implementation choices change.

- [ ] **Step 1: Add story-demo family data**

Seed:

- Premium owner: `story-demo@example.com`
- Contributor spouse: `story-spouse@example.com`
- Viewer relative: `story-viewer@example.com`
- Family Space: `Santos Household`
- Family Dining budget
- Family Groceries budget
- Family Contribution recurring schedule
- Internet recurring schedule
- Imported transaction with Family badge
- Pending invite notification
- Family Journey quest progress

- [ ] **Step 2: Add README story-demo note**

In `docs/README.md`, update story-demo section with:

```markdown
- Shared Conscia demo data: a Premium Family Space owner, contributor spouse, viewer relative, shared budgets, shared recurring obligations, a family contribution, an imported shared record, and invite notification examples.
```

- [ ] **Step 3: Add release setup notes**

In root `README.md`, add:

```markdown
### Shared Conscia Setup

Family Space uses relational tables for membership and existing DynamoDB-backed records for shared transactions, alerts, and outbox events.

Production requirements:
- Run the Family Space EF migration.
- Deploy the existing Outbox Lambda stack.
- Enable server-side FCM credentials only when device push delivery is ready.
- Set budget alerts for DynamoDB read/write growth after release.
```

- [ ] **Step 4: Run seed verification**

Run:

```powershell
dotnet run --project tools/Seeder -- story-demo
```

Expected: no exception and story-demo user has linked Family Space data.

- [ ] **Step 5: Commit seed/docs**

```powershell
git add tools docs README.md
git commit -m "docs: add shared conscia demo and setup notes"
```

---

## Final Verification

- [ ] **Step 1: Backend unit tests**

```powershell
dotnet test tests\Conscia.Tests.Unit\Conscia.Tests.Unit.csproj --no-restore
```

Expected: all unit tests pass.

- [ ] **Step 2: Infra tests**

```powershell
dotnet test infra\tests\Conscia.Infra.Tests\Conscia.Infra.Tests.csproj --no-restore
```

Expected: all infra tests pass. If asset publishing is required, run the publish command used by CI before rerunning.

- [ ] **Step 3: Flutter analyzer and tests**

```powershell
cd app
flutter analyze
flutter test
```

Expected: no analyzer issues and all tests pass.

- [ ] **Step 4: Manual emulator smoke test**

Use story-demo and verify:

- Owner sees Family Space in Settings.
- Owner can switch Dashboard to Family.
- Contributor can see shared budgets and add a family expense.
- Viewer can see Family records but cannot create one.
- Import warning appears before sharing records.
- Family-mode pre-purchase shows `Family advice`.
- Invite appears in bell.
- No UI says who owes whom.

- [ ] **Step 5: Cost/infra review**

Verify:

- No Redis, ECS, WebSocket, or always-on worker was introduced.
- Outbox async work uses the existing CDK-managed Outbox Lambda path.
- Family AI context sends compact summaries only.
- Import preview defaults to current month and active recurring schedules.
- Device push delivery is documented as enabled or in-app-only for the release.

---

## Execution Notes

- Prefer one PR per task or per two tightly related tasks.
- Commit after each task with a standard conventional commit.
- Keep generated Flutter files out of manual edits; run codegen only when adding generated model annotations.
- Never silently share existing personal records in tests, seed data, or UI.
- Add migration files in the same PR as domain persistence changes.
- If a task grows beyond one focused PR, stop and split before continuing.
