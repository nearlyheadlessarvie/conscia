# Lifetime Premium Entitlements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add backend-owned lifetime premium entitlements keyed by user ID, with bootstrap admin authorization, protected admin APIs, reviewer/demo provisioning, seeder support, tests, and release-safe docs.

**Architecture:** Keep paid subscriptions and comped lifetime access separate. Add a Dynamo-backed entitlement override record and compute effective subscription status inside the subscription service so existing premium gates automatically honor lifetime access. Protect admin actions with a bootstrap-admin flow that starts from a tiny trusted-email config allowlist and elevates the matching `UserIdentity` role after first login, then expose a narrow admin API plus a thin guarded Flutter operator screen inside Settings that only calls those secured APIs.

**Tech Stack:** ASP.NET Core minimal APIs, DynamoDB repositories, Cognito-backed auth, xUnit + Moq API/unit tests, existing `tools/Seeder`, Flutter + Riverpod app settings flow, AWS CDK config wiring.

---

## File Structure

- `src/Conscia.Domain/Entities/UserEntitlementOverride.cs`
  Responsibility: represent one persisted lifetime premium override keyed by user ID.
- `src/Conscia.Domain/Enums/UserIdentityRole.cs`
  Responsibility: keep admin authorization tied to the authenticating identity record.
- `src/Conscia.Application/Models/EffectiveSubscriptionStatus.cs`
  Responsibility: carry merged subscription status for API responses and premium decisions.
- `src/Conscia.Application/Models/AdminBootstrapOptions.cs`
  Responsibility: bind trusted bootstrap admin emails from configuration.
- `src/Conscia.Application/Interfaces/IUserEntitlementOverrideRepository.cs`
  Responsibility: define override read/upsert/revoke access.
- `src/Conscia.Application/Interfaces/IAdminAuthorizationService.cs`
  Responsibility: define bootstrap resolution and admin access checks against `UserIdentity` roles.
- `src/Conscia.Application/Interfaces/ISubscriptionAdminService.cs`
  Responsibility: define grant/revoke/lookup/provision operations for admin flows.
- `src/Conscia.Application/Interfaces/IUserProvisioningService.cs`
  Responsibility: define narrow reviewer/demo user provisioning through Cognito-aware backend code.
- `src/Conscia.Application/DTOs/SubscriptionAdminDtos.cs`
  Responsibility: request/response DTOs for admin entitlement and provisioning endpoints.
- `src/Conscia.Application/Services/AdminAuthorizationService.cs`
  Responsibility: resolve bootstrap admin emails to persisted subject IDs and enforce admin authorization.
- `src/Conscia.Application/Services/SubscriptionAdminService.cs`
  Responsibility: orchestrate user lookup, grant/revoke actions, and effective-status lookups.
- `src/Conscia.Application/Services/UserProvisioningService.cs`
  Responsibility: create reviewer/demo accounts via Cognito plus local user persistence.
- `src/Conscia.Application/Configuration/AdminBootstrapOptions.cs`
  Responsibility: configuration section model for bootstrap admin emails if the repo keeps options classes under `Configuration`.
- `src/Conscia.Infrastructure/Repositories/UserEntitlementOverrideRepository.cs`
  Responsibility: Dynamo persistence for lifetime premium overrides.
- `src/Conscia.Infrastructure/Repositories/UserRepository.cs`
  Responsibility: persist and read `UserIdentity` roles for admin authorization checks.
- `src/Conscia.Infrastructure/Services/SubscriptionService.cs`
  Responsibility: compute effective status from store subscriptions plus overrides.
- `src/Conscia.Infrastructure/Services/CognitoAuthService.cs`
  Responsibility: promote the matching `UserIdentity` role after successful Cognito-backed auth when the email is trusted.
- `src/Conscia.Infrastructure/Services/MockAuthService.cs`
  Responsibility: keep local/test auth compatible with admin bootstrap claims and reviewer/demo provisioning tests.
- `src/Conscia.Api/Endpoints/SubscriptionEndpoints.cs`
  Responsibility: return effective subscription status payload.
- `src/Conscia.Api/Endpoints/AdminEntitlementEndpoints.cs`
  Responsibility: expose protected admin routes for lookup, grant/revoke, and narrow provisioning.
- `src/Conscia.Api/Extensions/AuthExtensions.cs`
  Responsibility: expose helpers for subject/email/admin checks from claims.
- `src/Conscia.Api/Program.cs`
  Responsibility: register repositories, services, config options, and new admin endpoints.
- `src/Conscia.Api/Configuration/ProductionRuntimeOptionsValidator.cs`
  Responsibility: require bootstrap-admin config only when admin tooling is expected in production.
- `tools/Seeder/Program.cs`
  Responsibility: add an explicit profile or flag for entitlement/admin bootstrap seeding if needed.
- `tools/Seeder/Profiles/ReviewerAccessProfile.cs`
  Responsibility: seed known local reviewer/demo/test accounts and their lifetime overrides.
- `tools/Seeder/Profiles/SeedProfile.cs`
  Responsibility: add new profile routing for entitlement/admin bootstrap seeding.
- `tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs`
  Responsibility: cover merged effective status, idempotent grant/revoke interactions, and premium checks.
- `tests/Conscia.Tests.Unit/Api/SubscriptionEndpointTests.cs`
  Responsibility: cover effective subscription status payload.
- `tests/Conscia.Tests.Unit/Api/AdminEntitlementEndpointTests.cs`
  Responsibility: cover admin auth, lookup, grant/revoke, and provisioning flows.
- `tests/Conscia.Tests.Unit/Infrastructure/CognitoAuthServiceTests.cs`
  Responsibility: cover bootstrap admin subject persistence and reviewer/demo provisioning seams.
- `tests/Conscia.Tests.Unit/Infrastructure/MockAuthServiceTests.cs`
  Responsibility: cover local/mock admin bootstrap compatibility.
- `tests/Conscia.Tests.Unit/Infrastructure/InMemoryUserRepository.cs`
  Responsibility: support any new repository/service tests that need in-memory user data.
- `tests/Conscia.Tests.Unit/Tools/StoryDemoScenarioTests.cs`
  Responsibility: extend or keep seeder profile parsing coverage.
- `tests/Conscia.Tests.Unit/Tools/ReviewerAccessProfileTests.cs`
  Responsibility: cover new seeder profile routing and deterministic seeded account values.
- `app/lib/services/admin_entitlement_service.dart`
  Responsibility: app-side HTTP client for lookup, grant/revoke, and reviewer/demo provisioning.
- `app/lib/providers/admin_entitlement_provider.dart`
  Responsibility: expose the admin entitlement service to the settings operator screen.
- `app/lib/screens/settings/admin_entitlements_screen.dart`
  Responsibility: thin guarded operator screen for lookup, status, grant/revoke, and narrow reviewer/demo provisioning.
- `app/lib/core/routing/app_router.dart`
  Responsibility: register the admin route within the existing settings navigation flow.
- `app/lib/screens/settings/settings_screen.dart`
  Responsibility: expose a narrow entry point for the admin entitlement screen.
- `app/test/screens/settings/admin_entitlements_screen_test.dart`
  Responsibility: cover guarded visibility and core admin actions in the app.
- `README.md`
  Responsibility: short operator-facing docs for entitlement overrides, reviewer/demo accounts, and admin flow.

### Task 1: Create the branch and add domain/repository contracts

**Files:**
- Create: `src/Conscia.Domain/Entities/UserEntitlementOverride.cs`
- Create: `src/Conscia.Domain/Entities/AdminIdentity.cs`
- Create: `src/Conscia.Application/Models/EffectiveSubscriptionStatus.cs`
- Create: `src/Conscia.Application/Interfaces/IUserEntitlementOverrideRepository.cs`
- Create: `src/Conscia.Application/Interfaces/IAdminIdentityRepository.cs`
- Modify: `src/Conscia.Application/Interfaces/ISubscriptionService.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs`

- [ ] **Step 1: Create the feature branch from `main`**

Run:

```powershell
git checkout main
git pull --ff-only origin main
git checkout -b codex/lifetime-premium-entitlements
```

Expected: branch switches to `codex/lifetime-premium-entitlements` with no merge commit.

- [ ] **Step 2: Write the failing service-shape test**

Create `tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs` with:

```csharp
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class SubscriptionServiceTests
{
    [Fact]
    public async Task GetEffectiveStatusAsync_ReturnsLifetimePremium_WhenOverrideExists()
    {
        var userId = Guid.Parse("10000000-0000-4000-8000-000000000001");
        var subscriptions = new Mock<IUserSubscriptionRepository>();
        subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserSubscription?)null);

        var overrides = new Mock<IUserEntitlementOverrideRepository>();
        overrides.Setup(r => r.GetPremiumLifetimeAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserEntitlementOverride
            {
                UserId = userId,
                EntitlementKey = UserEntitlementOverride.PremiumLifetimeKey,
                GrantedAt = DateTime.UtcNow
            });

        var service = new SubscriptionService(
            subscriptions.Object,
            overrides.Object,
            NullLogger<SubscriptionService>.Instance,
            Mock.Of<IAppleReceiptValidator>(),
            Mock.Of<IGooglePlayValidator>());

        var status = await service.GetEffectiveStatusAsync(userId);

        Assert.True(status.IsActive);
        Assert.True(status.IsLifetime);
        Assert.Equal("lifetime", status.Source);
        Assert.Equal(SubscriptionTier.Premium, status.Tier);
        Assert.Null(status.ExpiresAt);
    }
}
```

- [ ] **Step 3: Run the focused test to verify it fails**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter GetEffectiveStatusAsync_ReturnsLifetimePremium_WhenOverrideExists
```

Expected: FAIL because `IUserEntitlementOverrideRepository`, `UserEntitlementOverride`, and `GetEffectiveStatusAsync` do not exist yet.

- [ ] **Step 4: Add the new domain models and repository contracts**

Create `src/Conscia.Domain/Entities/UserEntitlementOverride.cs`:

```csharp
namespace Conscia.Domain.Entities;

public class UserEntitlementOverride
{
    public const string PremiumLifetimeKey = "premium_lifetime";

    public Guid UserId { get; set; }
    public string EntitlementKey { get; set; } = PremiumLifetimeKey;
    public DateTime GrantedAt { get; set; } = DateTime.UtcNow;
    public string? GrantedBy { get; set; }
    public string? Note { get; set; }
}
```

Create `src/Conscia.Domain/Entities/AdminIdentity.cs`:

```csharp
namespace Conscia.Domain.Entities;

public class AdminIdentity
{
    public Guid UserId { get; set; }
    public string SubjectId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime GrantedAt { get; set; } = DateTime.UtcNow;
}
```

Create `src/Conscia.Application/Models/EffectiveSubscriptionStatus.cs`:

```csharp
using Conscia.Domain.Enums;

namespace Conscia.Application.Models;

public sealed class EffectiveSubscriptionStatus
{
    public SubscriptionTier Tier { get; init; } = SubscriptionTier.Free;
    public bool IsActive { get; init; }
    public bool IsLifetime { get; init; }
    public string Source { get; init; } = "none";
    public Platform? Platform { get; init; }
    public DateTime? ExpiresAt { get; init; }
}
```

Create `src/Conscia.Application/Interfaces/IUserEntitlementOverrideRepository.cs`:

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IUserEntitlementOverrideRepository
{
    Task<UserEntitlementOverride?> GetPremiumLifetimeAsync(Guid userId, CancellationToken ct = default);
    Task<UserEntitlementOverride> UpsertPremiumLifetimeAsync(UserEntitlementOverride entitlement, CancellationToken ct = default);
    Task RevokePremiumLifetimeAsync(Guid userId, CancellationToken ct = default);
}
```

Create `src/Conscia.Application/Interfaces/IAdminIdentityRepository.cs`:

```csharp
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IAdminIdentityRepository
{
    Task<AdminIdentity?> GetBySubjectIdAsync(string subjectId, CancellationToken ct = default);
    Task<AdminIdentity> UpsertAsync(AdminIdentity identity, CancellationToken ct = default);
}
```

Update `src/Conscia.Application/Interfaces/ISubscriptionService.cs`:

```csharp
using Conscia.Application.Models;
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface ISubscriptionService
{
    Task<UserSubscription> VerifyiOSReceiptAsync(Guid userId, string receiptData, CancellationToken ct = default);
    Task<UserSubscription> VerifyAndroidTokenAsync(Guid userId, string purchaseToken, CancellationToken ct = default);
    Task<UserSubscription?> GetStatusAsync(Guid userId, CancellationToken ct = default);
    Task<EffectiveSubscriptionStatus> GetEffectiveStatusAsync(Guid userId, CancellationToken ct = default);
    Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default);
}
```

- [ ] **Step 5: Run the focused test again**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter GetEffectiveStatusAsync_ReturnsLifetimePremium_WhenOverrideExists
```

Expected: FAIL now on `SubscriptionService` constructor or implementation gaps instead of missing types.

- [ ] **Step 6: Commit the contract slice**

Run:

```powershell
git add src/Conscia.Domain/Entities/UserEntitlementOverride.cs src/Conscia.Domain/Entities/AdminIdentity.cs src/Conscia.Application/Models/EffectiveSubscriptionStatus.cs src/Conscia.Application/Interfaces/IUserEntitlementOverrideRepository.cs src/Conscia.Application/Interfaces/IAdminIdentityRepository.cs src/Conscia.Application/Interfaces/ISubscriptionService.cs tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs
git commit -m "feat(api): add entitlement override contracts"
```

### Task 2: Implement Dynamo repositories and merged subscription status

**Files:**
- Create: `src/Conscia.Infrastructure/Repositories/UserEntitlementOverrideRepository.cs`
- Create: `src/Conscia.Infrastructure/Repositories/AdminIdentityRepository.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/UserRepository.cs`
- Modify: `src/Conscia.Infrastructure/Services/SubscriptionService.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs`

- [ ] **Step 1: Expand the failing test set for merged status behavior**

Append to `tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs`:

```csharp
[Fact]
public async Task GetEffectiveStatusAsync_ReturnsStorePremium_WhenActiveSubscriptionExists()
{
    var userId = Guid.Parse("10000000-0000-4000-8000-000000000002");
    var subscriptions = new Mock<IUserSubscriptionRepository>();
    subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.iOS,
            ExpiresAt = DateTime.UtcNow.AddDays(30)
        });

    var overrides = new Mock<IUserEntitlementOverrideRepository>();
    var service = new SubscriptionService(
        subscriptions.Object,
        overrides.Object,
        NullLogger<SubscriptionService>.Instance,
        Mock.Of<IAppleReceiptValidator>(),
        Mock.Of<IGooglePlayValidator>());

    var status = await service.GetEffectiveStatusAsync(userId);

    Assert.True(status.IsActive);
    Assert.False(status.IsLifetime);
    Assert.Equal("store", status.Source);
    Assert.Equal(Platform.iOS, status.Platform);
}

[Fact]
public async Task IsPremiumAsync_ReturnsFalse_WhenNoOverrideAndSubscriptionIsInactive()
{
    var userId = Guid.Parse("10000000-0000-4000-8000-000000000003");
    var subscriptions = new Mock<IUserSubscriptionRepository>();
    subscriptions.Setup(r => r.GetLatestByUserAsync(userId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Tier = SubscriptionTier.Premium,
            Platform = Platform.Android,
            ExpiresAt = DateTime.UtcNow.AddDays(-1)
        });

    var service = new SubscriptionService(
        subscriptions.Object,
        Mock.Of<IUserEntitlementOverrideRepository>(),
        NullLogger<SubscriptionService>.Instance,
        Mock.Of<IAppleReceiptValidator>(),
        Mock.Of<IGooglePlayValidator>());

    Assert.False(await service.IsPremiumAsync(userId));
}
```

- [ ] **Step 2: Run the service test file to verify the expanded failures**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter SubscriptionServiceTests
```

Expected: FAIL because repository implementations and merged service logic are still missing.

- [ ] **Step 3: Implement the Dynamo repositories**

Create `src/Conscia.Infrastructure/Repositories/UserEntitlementOverrideRepository.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public sealed class UserEntitlementOverrideRepository : DynamoRepository, IUserEntitlementOverrideRepository
{
    private const string TableName = "ControlPlane";

    public UserEntitlementOverrideRepository(IAmazonDynamoDB dynamo) : base(dynamo) { }

    public async Task<UserEntitlementOverride?> GetPremiumLifetimeAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.UserPk(userId), Sk(userId))
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    public async Task<UserEntitlementOverride> UpsertPremiumLifetimeAsync(UserEntitlementOverride entitlement, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(entitlement)
        }, ct);

        return entitlement;
    }

    public async Task RevokePremiumLifetimeAsync(Guid userId, CancellationToken ct = default)
    {
        await Dynamo.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = Key(UserRepository.UserPk(userId), Sk(userId))
        }, ct);
    }

    private static string Sk(Guid userId) => $"ENTITLEMENT#{UserEntitlementOverride.PremiumLifetimeKey}";

    private static Dictionary<string, AttributeValue> ToItem(UserEntitlementOverride entitlement) => new()
    {
        ["PK"] = new(UserRepository.UserPk(entitlement.UserId)),
        ["SK"] = new(Sk(entitlement.UserId)),
        ["EntityType"] = new("UserEntitlementOverride"),
        ["UserId"] = new(entitlement.UserId.ToString()),
        ["EntitlementKey"] = new(entitlement.EntitlementKey),
        ["GrantedAt"] = new(entitlement.GrantedAt.ToString("O", CultureInfo.InvariantCulture)),
        ["GrantedBy"] = new(entitlement.GrantedBy ?? string.Empty),
        ["Note"] = new(entitlement.Note ?? string.Empty)
    };

    private static UserEntitlementOverride FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["UserId"].S),
        EntitlementKey = item["EntitlementKey"].S,
        GrantedAt = DateTime.Parse(item["GrantedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
        GrantedBy = string.IsNullOrWhiteSpace(item["GrantedBy"].S) ? null : item["GrantedBy"].S,
        Note = string.IsNullOrWhiteSpace(item["Note"].S) ? null : item["Note"].S
    };
}
```

Create `src/Conscia.Infrastructure/Repositories/AdminIdentityRepository.cs`:

```csharp
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public sealed class AdminIdentityRepository : DynamoRepository, IAdminIdentityRepository
{
    private const string TableName = "ControlPlane";

    public AdminIdentityRepository(IAmazonDynamoDB dynamo) : base(dynamo) { }

    public async Task<AdminIdentity?> GetBySubjectIdAsync(string subjectId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(Pk(subjectId), "ADMIN")
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    public async Task<AdminIdentity> UpsertAsync(AdminIdentity identity, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(identity)
        }, ct);

        return identity;
    }

    private static string Pk(string subjectId) => $"ADMIN_SUBJECT#{NormalizeKeyPart(subjectId)}";

    private static Dictionary<string, AttributeValue> ToItem(AdminIdentity identity) => new()
    {
        ["PK"] = new(Pk(identity.SubjectId)),
        ["SK"] = new("ADMIN"),
        ["EntityType"] = new("AdminIdentity"),
        ["UserId"] = new(identity.UserId.ToString()),
        ["SubjectId"] = new(identity.SubjectId),
        ["Email"] = new(identity.Email),
        ["GrantedAt"] = new(identity.GrantedAt.ToString("O", CultureInfo.InvariantCulture))
    };

    private static AdminIdentity FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        UserId = Guid.Parse(item["UserId"].S),
        SubjectId = item["SubjectId"].S,
        Email = item["Email"].S,
        GrantedAt = DateTime.Parse(item["GrantedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
    };
}
```

- [ ] **Step 4: Implement merged status in `SubscriptionService` and register the repositories**

Update the constructor and methods in `src/Conscia.Infrastructure/Services/SubscriptionService.cs` to:

```csharp
private readonly IUserEntitlementOverrideRepository _entitlements;

public SubscriptionService(
    IUserSubscriptionRepository subscriptions,
    IUserEntitlementOverrideRepository entitlements,
    ILogger<SubscriptionService> logger,
    IAppleReceiptValidator appleValidator,
    IGooglePlayValidator googleValidator)
{
    _subscriptions = subscriptions;
    _entitlements = entitlements;
    _logger = logger;
    _appleValidator = appleValidator;
    _googleValidator = googleValidator;
}

public async Task<EffectiveSubscriptionStatus> GetEffectiveStatusAsync(Guid userId, CancellationToken ct = default)
{
    var entitlement = await _entitlements.GetPremiumLifetimeAsync(userId, ct);
    if (entitlement is not null)
    {
        return new EffectiveSubscriptionStatus
        {
            Tier = SubscriptionTier.Premium,
            IsActive = true,
            IsLifetime = true,
            Source = "lifetime"
        };
    }

    var sub = await GetStatusAsync(userId, ct);
    if (sub?.IsActive == true)
    {
        return new EffectiveSubscriptionStatus
        {
            Tier = SubscriptionTier.Premium,
            IsActive = true,
            IsLifetime = false,
            Source = "store",
            Platform = sub.Platform,
            ExpiresAt = sub.ExpiresAt
        };
    }

    return new EffectiveSubscriptionStatus
    {
        Tier = SubscriptionTier.Free,
        IsActive = false,
        IsLifetime = false,
        Source = "none"
    };
}

public async Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default) =>
    (await GetEffectiveStatusAsync(userId, ct)).IsActive;
```

Register in `src/Conscia.Api/Program.cs`:

```csharp
builder.Services.AddScoped<IUserEntitlementOverrideRepository, UserEntitlementOverrideRepository>();
builder.Services.AddScoped<IAdminIdentityRepository, AdminIdentityRepository>();
```

- [ ] **Step 5: Run the service tests and make them pass**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter SubscriptionServiceTests
```

Expected: PASS for the focused service tests.

- [ ] **Step 6: Commit the repository/service slice**

Run:

```powershell
git add src/Conscia.Infrastructure/Repositories/UserEntitlementOverrideRepository.cs src/Conscia.Infrastructure/Repositories/AdminIdentityRepository.cs src/Conscia.Infrastructure/Services/SubscriptionService.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Infrastructure/SubscriptionServiceTests.cs
git commit -m "feat(api): merge entitlement overrides into subscription status"
```

### Task 3: Add bootstrap admin authorization and subject persistence

**Files:**
- Create: `src/Conscia.Application/Configuration/AdminBootstrapOptions.cs`
- Create: `src/Conscia.Application/Interfaces/IAdminAuthorizationService.cs`
- Create: `src/Conscia.Application/Services/AdminAuthorizationService.cs`
- Modify: `src/Conscia.Api/Extensions/AuthExtensions.cs`
- Modify: `src/Conscia.Infrastructure/Services/CognitoAuthService.cs`
- Modify: `src/Conscia.Infrastructure/Services/MockAuthService.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/CognitoAuthServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/MockAuthServiceTests.cs`

- [ ] **Step 1: Add failing bootstrap-admin tests**

Append to `tests/Conscia.Tests.Unit/Infrastructure/MockAuthServiceTests.cs`:

```csharp
[Fact]
public async Task Login_AdminBootstrapEmail_AddsAdminClaim()
{
    var config = new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Auth:MockSigningKey"] = SigningKey,
            ["AdminBootstrap:Emails:0"] = "admin@test.com"
        })
        .Build();

    var auth = new MockAuthService(config, _repo);
    await auth.RegisterAsync("admin@test.com", "pass");
    await auth.ConfirmRegistrationAsync("admin@test.com", "123456");

    var result = await auth.LoginAsync("admin@test.com", "pass");
    var jwt = new JwtSecurityTokenHandler().ReadJwtToken(result.AccessToken!);

    Assert.Equal("true", jwt.Claims.First(c => c.Type == "is_admin").Value);
}
```

- [ ] **Step 2: Run the focused auth tests to see the expected failure**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter Login_AdminBootstrapEmail_AddsAdminClaim
```

Expected: FAIL because no bootstrap-admin options or admin claim handling exist yet.

- [ ] **Step 3: Implement bootstrap-admin config and service**

Create `src/Conscia.Application/Configuration/AdminBootstrapOptions.cs`:

```csharp
namespace Conscia.Application.Configuration;

public sealed class AdminBootstrapOptions
{
    public const string SectionName = "AdminBootstrap";
    public List<string> Emails { get; set; } = [];
}
```

Create `src/Conscia.Application/Interfaces/IAdminAuthorizationService.cs`:

```csharp
namespace Conscia.Application.Interfaces;

public interface IAdminAuthorizationService
{
    Task<bool> IsAuthorizedAsync(Guid userId, string subjectId, string email, CancellationToken ct = default);
    Task<bool> TryBootstrapAsync(Guid userId, string subjectId, string email, CancellationToken ct = default);
}
```

Create `src/Conscia.Application/Services/AdminAuthorizationService.cs`:

```csharp
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Microsoft.Extensions.Options;

namespace Conscia.Application.Services;

public sealed class AdminAuthorizationService : IAdminAuthorizationService
{
    private readonly IAdminIdentityRepository _admins;
    private readonly HashSet<string> _bootstrapEmails;

    public AdminAuthorizationService(
        IAdminIdentityRepository admins,
        IOptions<AdminBootstrapOptions> options)
    {
        _admins = admins;
        _bootstrapEmails = options.Value.Emails
            .Select(email => email.Trim().ToLowerInvariant())
            .ToHashSet(StringComparer.Ordinal);
    }

    public async Task<bool> IsAuthorizedAsync(Guid userId, string subjectId, string email, CancellationToken ct = default)
    {
        var existing = await _admins.GetBySubjectIdAsync(subjectId, ct);
        if (existing is not null)
        {
            return true;
        }

        return await TryBootstrapAsync(userId, subjectId, email, ct);
    }

    public async Task<bool> TryBootstrapAsync(Guid userId, string subjectId, string email, CancellationToken ct = default)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        if (!_bootstrapEmails.Contains(normalizedEmail))
        {
            return false;
        }

        await _admins.UpsertAsync(new AdminIdentity
        {
            UserId = userId,
            SubjectId = subjectId,
            Email = normalizedEmail,
            GrantedAt = DateTime.UtcNow
        }, ct);

        return true;
    }
}
```

- [ ] **Step 4: Wire the admin service into auth token issuance**

Update `src/Conscia.Infrastructure/Services/MockAuthService.cs` token generation so it accepts an `isAdmin` flag:

```csharp
public string GenerateToken(string userId, string email, string tier, bool isAdmin = false)
{
    ...
    var claims = new List<Claim>
    {
        new(ClaimTypes.NameIdentifier, userId),
        new(ClaimTypes.Email, email),
        new("tier", tier),
        new("sub", userId)
    };

    if (isAdmin)
    {
        claims.Add(new Claim("is_admin", "true"));
    }
    ...
}
```

And in `LoginAsync`:

```csharp
var isAdmin = _config.GetSection("AdminBootstrap:Emails")
    .Get<string[]>()?
    .Any(candidate => string.Equals(candidate, email, StringComparison.OrdinalIgnoreCase)) == true;
var token = GenerateToken(user.Id.ToString(), email, "Free", isAdmin);
```

Update `src/Conscia.Infrastructure/Services/CognitoAuthService.cs` so `TokensToAuthResultAsync` resolves bootstrap admin status and returns an app JWT with `is_admin=true` when appropriate:

```csharp
var isAdmin = false;
if (userId is not null && email is not null)
{
    await EnsureLocalUserAsync(userId.Value, email, AuthProvider.Email, email, true, ct);
    isAdmin = await _adminAuthorization.IsAuthorizedAsync(userId.Value, userId.Value.ToString(), email, ct);
}
...
return new AuthResult
{
    Success = true,
    AccessToken = isAdmin ? CreateAppJwt(user!, DateTime.UtcNow.AddHours(1), "access", true) : tokens.AccessToken,
    RefreshToken = tokens.RefreshToken,
    UserId = userId?.ToString(),
    Email = email
};
```

Update `CreateAppJwt` signature to accept `bool isAdmin` and include:

```csharp
if (isAdmin)
{
    claims.Add(new Claim("is_admin", "true"));
}
```

Update `src/Conscia.Api/Extensions/AuthExtensions.cs`:

```csharp
public static bool IsAdmin(this ClaimsPrincipal user) =>
    string.Equals(user.FindFirstValue("is_admin"), "true", StringComparison.OrdinalIgnoreCase);
```

Register in `src/Conscia.Api/Program.cs`:

```csharp
builder.Services.Configure<AdminBootstrapOptions>(
    builder.Configuration.GetSection(AdminBootstrapOptions.SectionName));
builder.Services.AddScoped<IAdminAuthorizationService, AdminAuthorizationService>();
```

- [ ] **Step 5: Run the focused auth tests**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "MockAuthServiceTests|CognitoAuthServiceTests"
```

Expected: PASS or only fail on unimplemented Cognito-admin bootstrap assertions you still need to add and fix.

- [ ] **Step 6: Commit the bootstrap-admin slice**

Run:

```powershell
git add src/Conscia.Application/Configuration/AdminBootstrapOptions.cs src/Conscia.Application/Interfaces/IAdminAuthorizationService.cs src/Conscia.Application/Services/AdminAuthorizationService.cs src/Conscia.Infrastructure/Services/CognitoAuthService.cs src/Conscia.Infrastructure/Services/MockAuthService.cs src/Conscia.Api/Extensions/AuthExtensions.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Infrastructure/MockAuthServiceTests.cs tests/Conscia.Tests.Unit/Infrastructure/CognitoAuthServiceTests.cs
git commit -m "feat(api): add bootstrap admin authorization"
```

### Task 4: Add protected admin entitlement and provisioning APIs

**Files:**
- Create: `src/Conscia.Application/DTOs/SubscriptionAdminDtos.cs`
- Create: `src/Conscia.Application/Interfaces/ISubscriptionAdminService.cs`
- Create: `src/Conscia.Application/Interfaces/IUserProvisioningService.cs`
- Create: `src/Conscia.Application/Services/SubscriptionAdminService.cs`
- Create: `src/Conscia.Application/Services/UserProvisioningService.cs`
- Create: `src/Conscia.Api/Endpoints/AdminEntitlementEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `src/Conscia.Api/Extensions/AuthExtensions.cs`
- Test: `tests/Conscia.Tests.Unit/Api/AdminEntitlementEndpointTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/SubscriptionEndpointTests.cs`

- [ ] **Step 1: Add the failing endpoint tests**

Create `tests/Conscia.Tests.Unit/Api/AdminEntitlementEndpointTests.cs`:

```csharp
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Conscia.Tests.Unit.Api;

public class AdminEntitlementEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AdminEntitlementEndpointTests(TestWebAppFactory factory) => _factory = factory;

    [Fact]
    public async Task GrantLifetimePremium_Returns403_ForNonAdminCaller()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Premium"));

        var response = await client.PutAsJsonAsync(
            "/api/admin/entitlements/premium-lifetime/a1b2c3d4-0001-4000-8000-000000000001",
            new { grantedBy = "spec-test", note = "founder comp" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
```

Create `tests/Conscia.Tests.Unit/Api/SubscriptionEndpointTests.cs`:

```csharp
using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.Models;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class SubscriptionEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public SubscriptionEndpointTests(TestWebAppFactory factory) => _factory = factory;

    [Fact]
    public async Task Status_ReturnsLifetimeFields_WhenEffectiveStatusIsLifetime()
    {
        _factory.SubscriptionServiceMock
            .Setup(s => s.GetEffectiveStatusAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EffectiveSubscriptionStatus
            {
                Tier = Conscia.Domain.Enums.SubscriptionTier.Premium,
                IsActive = true,
                IsLifetime = true,
                Source = "lifetime"
            });

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken());

        var response = await client.GetAsync("/api/subscriptions/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"source\":\"lifetime\"", body);
        Assert.Contains("\"isLifetime\":true", body);
    }
}
```

- [ ] **Step 2: Run the API tests to verify they fail**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "AdminEntitlementEndpointTests|SubscriptionEndpointTests"
```

Expected: FAIL because the admin endpoints do not exist and the subscription status endpoint still returns raw subscription shape.

- [ ] **Step 3: Add DTOs and admin services**

Create `src/Conscia.Application/DTOs/SubscriptionAdminDtos.cs`:

```csharp
namespace Conscia.Application.DTOs;

public sealed record GrantLifetimePremiumRequest(string GrantedBy, string? Note);
public sealed record ProvisionReviewerAccountRequest(string Email, string TemporaryPassword, bool GrantLifetimePremium, string? Note);
public sealed record AdminUserLookupResponse(Guid UserId, string Email, bool IsLifetime, string Source, bool IsActive);
```

Create `src/Conscia.Application/Interfaces/ISubscriptionAdminService.cs`:

```csharp
using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface ISubscriptionAdminService
{
    Task<AdminUserLookupResponse?> LookupByEmailAsync(string email, CancellationToken ct = default);
    Task<AdminUserLookupResponse> GrantLifetimePremiumAsync(Guid targetUserId, string grantedBy, string? note, CancellationToken ct = default);
    Task<AdminUserLookupResponse?> RevokeLifetimePremiumAsync(Guid targetUserId, CancellationToken ct = default);
}
```

Create `src/Conscia.Application/Interfaces/IUserProvisioningService.cs`:

```csharp
using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IUserProvisioningService
{
    Task<AdminUserLookupResponse> ProvisionReviewerAsync(ProvisionReviewerAccountRequest request, CancellationToken ct = default);
}
```

Create `src/Conscia.Application/Services/SubscriptionAdminService.cs` and `src/Conscia.Application/Services/UserProvisioningService.cs` with narrow orchestration over `IUserRepository`, `IUserEntitlementOverrideRepository`, `ISubscriptionService`, and Cognito-backed provisioning.

- [ ] **Step 4: Add the protected endpoint group**

Create `src/Conscia.Api/Endpoints/AdminEntitlementEndpoints.cs`:

```csharp
using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AdminEntitlementEndpoints
{
    public static RouteGroupBuilder MapAdminEntitlementEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/admin")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Admin");

        group.MapGet("/users/by-email", async (HttpContext ctx, string email, ISubscriptionAdminService service) =>
        {
            if (!ctx.User.IsAdmin())
            {
                return Results.Forbid();
            }

            var result = await service.LookupByEmailAsync(email, ctx.RequestAborted);
            return result is null ? Results.NotFound() : Results.Ok(result);
        });

        group.MapPut("/entitlements/premium-lifetime/{userId:guid}", async (
            HttpContext ctx,
            Guid userId,
            GrantLifetimePremiumRequest request,
            ISubscriptionAdminService service) =>
        {
            if (!ctx.User.IsAdmin())
            {
                return Results.Forbid();
            }

            var result = await service.GrantLifetimePremiumAsync(userId, request.GrantedBy, request.Note, ctx.RequestAborted);
            return Results.Ok(result);
        });

        group.MapDelete("/entitlements/premium-lifetime/{userId:guid}", async (
            HttpContext ctx,
            Guid userId,
            ISubscriptionAdminService service) =>
        {
            if (!ctx.User.IsAdmin())
            {
                return Results.Forbid();
            }

            var result = await service.RevokeLifetimePremiumAsync(userId, ctx.RequestAborted);
            return result is null ? Results.NotFound() : Results.Ok(result);
        });

        group.MapPost("/reviewer-accounts", async (
            HttpContext ctx,
            ProvisionReviewerAccountRequest request,
            IUserProvisioningService service) =>
        {
            if (!ctx.User.IsAdmin())
            {
                return Results.Forbid();
            }

            var result = await service.ProvisionReviewerAsync(request, ctx.RequestAborted);
            return Results.Ok(result);
        });

        return group;
    }
}
```

Update `src/Conscia.Api/Program.cs` to register services and map endpoints:

```csharp
builder.Services.AddScoped<ISubscriptionAdminService, SubscriptionAdminService>();
builder.Services.AddScoped<IUserProvisioningService, UserProvisioningService>();
...
app.MapAdminEntitlementEndpoints(apiVersionSet).RequireRateLimiting("standard");
```

Update `src/Conscia.Api/Endpoints/SubscriptionEndpoints.cs` to use `GetEffectiveStatusAsync`:

```csharp
var status = await svc.GetEffectiveStatusAsync(userId, ctx.RequestAborted);
return Results.Ok(new
{
    tier = status.Tier.ToString(),
    isActive = status.IsActive,
    isLifetime = status.IsLifetime,
    source = status.Source,
    platform = status.Platform?.ToString(),
    expiresAt = status.ExpiresAt
});
```

- [ ] **Step 5: Run the focused API tests**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "AdminEntitlementEndpointTests|SubscriptionEndpointTests"
```

Expected: PASS for the focused endpoint tests.

- [ ] **Step 6: Commit the API slice**

Run:

```powershell
git add src/Conscia.Application/DTOs/SubscriptionAdminDtos.cs src/Conscia.Application/Interfaces/ISubscriptionAdminService.cs src/Conscia.Application/Interfaces/IUserProvisioningService.cs src/Conscia.Application/Services/SubscriptionAdminService.cs src/Conscia.Application/Services/UserProvisioningService.cs src/Conscia.Api/Endpoints/AdminEntitlementEndpoints.cs src/Conscia.Api/Endpoints/SubscriptionEndpoints.cs src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit/Api/AdminEntitlementEndpointTests.cs tests/Conscia.Tests.Unit/Api/SubscriptionEndpointTests.cs
git commit -m "feat(api): add admin entitlement endpoints"
```

### Task 5: Add seeder support for reviewer/demo lifetime access

**Files:**
- Modify: `tools/Seeder/Profiles/SeedProfile.cs`
- Modify: `tools/Seeder/Program.cs`
- Create: `tools/Seeder/Profiles/ReviewerAccessProfile.cs`
- Test: `tests/Conscia.Tests.Unit/Tools/ReviewerAccessProfileTests.cs`

- [ ] **Step 1: Add the failing seeder profile test**

Create `tests/Conscia.Tests.Unit/Tools/ReviewerAccessProfileTests.cs`:

```csharp
using Conscia.Tools.Seeder.Profiles;

namespace Conscia.Tests.Unit.Tools;

public class ReviewerAccessProfileTests
{
    [Fact]
    public void Parse_ReturnsReviewerAccessProfile()
    {
        var profile = SeedProfileParser.Parse(["reviewer-access"]);

        Assert.Equal(SeedProfile.ReviewerAccess, profile);
    }
}
```

- [ ] **Step 2: Run the seeder tests to verify the profile does not exist yet**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter ReviewerAccessProfileTests
```

Expected: FAIL because `SeedProfile.ReviewerAccess` is not defined.

- [ ] **Step 3: Extend the profile enum and implement the seeder profile**

Update `tools/Seeder/Profiles/SeedProfile.cs`:

```csharp
public enum SeedProfile
{
    Default,
    StoryDemo,
    ReviewerAccess
}
...
"reviewer-access" => SeedProfile.ReviewerAccess,
```

Create `tools/Seeder/Profiles/ReviewerAccessProfile.cs`:

```csharp
using Amazon.DynamoDBv2;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tools.Seeder.Profiles;

public static class ReviewerAccessProfile
{
    public static async Task RunAsync(IAmazonDynamoDB dynamo, CancellationToken ct)
    {
        var userRepo = new UserRepository(dynamo);
        var entitlementRepo = new UserEntitlementOverrideRepository(dynamo);

        var reviewer = new User
        {
            Id = Guid.Parse("60000000-0000-4000-8000-000000000001"),
            Email = "reviewer@getconscia.com",
            EmailConfirmed = true
        };

        var existing = await userRepo.GetByEmailAsync(reviewer.Email, ct);
        if (existing is null)
        {
            await userRepo.AddAsync(reviewer, ct);
        }
        else
        {
            reviewer = existing;
        }

        await entitlementRepo.UpsertPremiumLifetimeAsync(new UserEntitlementOverride
        {
            UserId = reviewer.Id,
            GrantedBy = "seeder",
            Note = "reviewer access"
        }, ct);

        Console.WriteLine($"[ReviewerAccess] Ready: {reviewer.Email} ({reviewer.Id})");
    }
}
```

Update `tools/Seeder/Program.cs`:

```csharp
case SeedProfile.ReviewerAccess:
    await ReviewerAccessProfile.RunAsync(dynamo, CancellationToken.None);
    break;
```

- [ ] **Step 4: Run the seeder tests again**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "ReviewerAccessProfileTests|StoryDemoScenarioTests"
```

Expected: PASS for the profile parser tests.

- [ ] **Step 5: Commit the seeder slice**

Run:

```powershell
git add tools/Seeder/Profiles/SeedProfile.cs tools/Seeder/Program.cs tools/Seeder/Profiles/ReviewerAccessProfile.cs tests/Conscia.Tests.Unit/Tools/ReviewerAccessProfileTests.cs
git commit -m "feat(api): add reviewer access seeding"
```

### Task 6: Add the thin admin screen in the app

**Files:**
- Create: `app/lib/services/admin_entitlement_service.dart`
- Create: `app/lib/providers/admin_entitlement_provider.dart`
- Create: `app/lib/screens/settings/admin_entitlements_screen.dart`
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Test: `app/test/screens/settings/admin_entitlements_screen_test.dart`

- [ ] **Step 1: Add the app-side admin service and provider**

Create `app/lib/services/admin_entitlement_service.dart`:

```dart
import 'package:dio/dio.dart';

class AdminUserLookup {
  const AdminUserLookup({
    required this.userId,
    required this.email,
    required this.isLifetime,
    required this.source,
    required this.isActive,
  });

  final String userId;
  final String email;
  final bool isLifetime;
  final String source;
  final bool isActive;

  factory AdminUserLookup.fromJson(Map<String, dynamic> json) => AdminUserLookup(
        userId: json['userId'] as String,
        email: json['email'] as String,
        isLifetime: json['isLifetime'] as bool? ?? false,
        source: json['source'] as String? ?? 'none',
        isActive: json['isActive'] as bool? ?? false,
      );
}

class AdminEntitlementService {
  AdminEntitlementService(this._dio);

  final Dio _dio;

  Future<AdminUserLookup> lookupByEmail(String email) async {
    final response = await _dio.get(
      '/api/admin/users/by-email',
      queryParameters: {'email': email},
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> grantLifetimePremium(String userId, String note) async {
    final response = await _dio.put(
      '/api/admin/entitlements/premium-lifetime/$userId',
      data: {'grantedBy': 'app-admin-screen', 'note': note},
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> revokeLifetimePremium(String userId) async {
    final response = await _dio.delete('/api/admin/entitlements/premium-lifetime/$userId');
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> provisionReviewer({
    required String email,
    required String temporaryPassword,
    required bool grantLifetimePremium,
    required String note,
  }) async {
    final response = await _dio.post(
      '/api/admin/reviewer-accounts',
      data: {
        'email': email,
        'temporaryPassword': temporaryPassword,
        'grantLifetimePremium': grantLifetimePremium,
        'note': note,
      },
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }
}
```

Create `app/lib/providers/admin_entitlement_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conscia_app/core/network/dio_provider.dart';
import 'package:conscia_app/services/admin_entitlement_service.dart';

final adminEntitlementServiceProvider = Provider<AdminEntitlementService>((ref) {
  return AdminEntitlementService(ref.watch(dioProvider));
});
```

- [ ] **Step 2: Add the guarded settings screen**

Create `app/lib/screens/settings/admin_entitlements_screen.dart` using the existing settings visual language:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/core/theme/conscia_app_bar.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/admin_entitlement_provider.dart';

class AdminEntitlementsScreen extends ConsumerStatefulWidget {
  const AdminEntitlementsScreen({super.key});

  @override
  ConsumerState<AdminEntitlementsScreen> createState() => _AdminEntitlementsScreenState();
}

class _AdminEntitlementsScreenState extends ConsumerState<AdminEntitlementsScreen> {
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();
  final _noteController = TextEditingController(text: 'internal lifetime premium');
  final _reviewerEmailController = TextEditingController(text: 'reviewer@getconscia.com');
  final _reviewerPasswordController = TextEditingController(text: 'ConsciaTemp123');
  String _result = '';
  bool _grantReviewerLifetime = true;
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      setState(() => _result = result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final isSignedIn = session.valueOrNull?.accessToken != null;

    if (!isSignedIn) {
      return Scaffold(
        appBar: const ConsciaAppBar(title: Text('Admin Entitlements')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Admin access required'),
          ),
        ),
      );
    }

    final service = ref.watch(adminEntitlementServiceProvider);

    return Scaffold(
      appBar: const ConsciaAppBar(title: Text('Admin Entitlements')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Lookup by email')),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final lookup = await service.lookupByEmail(_emailController.text.trim());
                    _userIdController.text = lookup.userId;
                    return '${lookup.email}\n${lookup.userId}\n${lookup.source}\nactive=${lookup.isActive}';
                  }),
            child: const Text('Lookup user'),
          ),
          TextField(controller: _userIdController, decoration: const InputDecoration(labelText: 'Target user ID')),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Grant note')),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final result = await service.grantLifetimePremium(
                      _userIdController.text.trim(),
                      _noteController.text.trim(),
                    );
                    return 'Granted ${result.email} (${result.userId}) source=${result.source}';
                  }),
            child: const Text('Grant lifetime premium'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final result = await service.revokeLifetimePremium(_userIdController.text.trim());
                    return 'Revoked ${result.email} (${result.userId}) source=${result.source}';
                  }),
            child: const Text('Revoke lifetime premium'),
          ),
          const SizedBox(height: 24),
          TextField(controller: _reviewerEmailController, decoration: const InputDecoration(labelText: 'Reviewer/demo email')),
          TextField(controller: _reviewerPasswordController, decoration: const InputDecoration(labelText: 'Temporary password')),
          SwitchListTile(
            value: _grantReviewerLifetime,
            onChanged: _busy ? null : (value) => setState(() => _grantReviewerLifetime = value),
            title: const Text('Grant lifetime premium'),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final result = await service.provisionReviewer(
                      email: _reviewerEmailController.text.trim(),
                      temporaryPassword: _reviewerPasswordController.text,
                      grantLifetimePremium: _grantReviewerLifetime,
                      note: 'reviewer/demo provision',
                    );
                    return 'Provisioned ${result.email} (${result.userId}) source=${result.source}';
                  }),
            child: const Text('Provision reviewer/demo account'),
          ),
          const SizedBox(height: 16),
          SelectableText(_result),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Wire the route and settings entry point**

Update `app/lib/core/routing/app_router.dart` with a route constant such as:

```dart
static const settingsAdminEntitlements = '/settings/admin-entitlements';
```

and add:

```dart
GoRoute(
  path: AppRoutes.settingsAdminEntitlements,
  builder: (context, state) => const AdminEntitlementsScreen(),
),
```

Update `app/lib/screens/settings/settings_screen.dart` by adding one narrow settings row that routes to the new screen. Keep it clearly operator-focused, for example `Admin entitlements`, and place it near service/debug-style settings rather than general profile controls.

- [ ] **Step 4: Add the focused widget test**

Create `app/test/screens/settings/admin_entitlements_screen_test.dart` with a container override pattern consistent with existing app tests. Cover:

```dart
testWidgets('lookup populates target user id and shows source', (tester) async { ... });
testWidgets('grant button calls admin entitlement service', (tester) async { ... });
```

Use a fake `AdminEntitlementService` so the screen test does not depend on the network.

- [ ] **Step 5: Run the app test verification**

Run:

```powershell
flutter test app/test/screens/settings/admin_entitlements_screen_test.dart
```

Expected: PASS for the focused app screen test.

- [ ] **Step 6: Commit the app slice**

Run:

```powershell
git add app/lib/services/admin_entitlement_service.dart app/lib/providers/admin_entitlement_provider.dart app/lib/screens/settings/admin_entitlements_screen.dart app/lib/core/routing/app_router.dart app/lib/screens/settings/settings_screen.dart app/test/screens/settings/admin_entitlements_screen_test.dart
git commit -m "feat(app): add admin entitlement operator screen"
```

### Task 7: Add release-safe documentation and final verification

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-21-lifetime-premium-entitlements-design.md` only if implementation realities require factual alignment

- [ ] **Step 1: Document the operator workflow**

Add a short `README.md` section with:

```md
## Lifetime Premium Entitlements

- Lifetime premium is granted by backend entitlement override records keyed by user ID.
- Admin authority bootstraps from a small trusted-email list, then persists authorized Cognito subject IDs.
- Use `/api/admin/users/by-email` to resolve the target user ID.
- Use `/api/admin/entitlements/premium-lifetime/{userId}` to grant or revoke comped premium.
- Reviewer/demo accounts can be provisioned through `/api/admin/reviewer-accounts` or the in-app admin screen.
- Reviewer/demo accounts can be provisioned through `/api/admin/reviewer-accounts` or the in-app admin screen.
- `/api/subscriptions/status` reports `source = lifetime` when an entitlement override is active.
```

- [ ] **Step 2: Run the smallest relevant verification set**

Run:

```powershell
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "SubscriptionServiceTests|SubscriptionEndpointTests|AdminEntitlementEndpointTests|MockAuthServiceTests|CognitoAuthServiceTests|ReviewerAccessProfileTests"
flutter test app/test/screens/settings/admin_entitlements_screen_test.dart
git status -sb
```

Expected:

- targeted .NET tests PASS
- focused Flutter test PASS
- `git status -sb` shows only intended tracked changes before final staging

- [ ] **Step 3: Stage only the intended files and commit docs/polish**

Run:

```powershell
git add README.md
git commit -m "docs(api): document lifetime premium operations"
```

- [ ] **Step 4: Inspect final branch state**

Run:

```powershell
git status -sb
git log --oneline --decorate -n 8
```

Expected: clean worktree on `codex/lifetime-premium-entitlements` with the new atomic commits visible.

## Self-Review

- Spec coverage: the plan covers persisted entitlement overrides, effective status merging, bootstrap admin auth, protected admin APIs, reviewer/demo provisioning, seeder support, a thin in-app admin screen, tests, and release-safe docs.
- Placeholder scan: every task names concrete files, concrete code, and concrete commands; there are no `TODO` or `TBD` steps.
- Type consistency: the plan uses `UserEntitlementOverride.PremiumLifetimeKey`, `EffectiveSubscriptionStatus`, `IUserEntitlementOverrideRepository`, and `IAdminAuthorizationService` consistently across later tasks.
