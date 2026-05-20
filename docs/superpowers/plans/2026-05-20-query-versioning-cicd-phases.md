# Query Versioning And CI/CD Phases Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `/api/v1` path-based API versioning with canonical query-string versioning, enforce current-plus-previous app compatibility, and rewrite the CI/CD setup docs into a practical 3-phase guide.

**Architecture:** The API host adopts ASP.NET API versioning so `/api/...` endpoints resolve version `1` from `?v=1` and optionally `X-Api-Version`, while a small app-compatibility layer reads `X-Conscia-App-Version` and rejects clients older than the previous supported release. Flutter keeps a stable `/api/` base URL and injects `v=1` plus app-version metadata in the shared Dio client so service code stays unchanged. Documentation is then updated around the new canonical request contract and phased deployment guidance.

**Tech Stack:** ASP.NET Core 8 Minimal APIs, `Asp.Versioning.Http`, Swashbuckle/OpenAPI, Flutter, Dio, Riverpod, package_info_plus, Markdown docs.

---

## File Structure

- Modify: `src/Conscia.Api/Conscia.Api.csproj`
  Adds ASP.NET API versioning packages needed for runtime readers and explorer support.
- Modify: `src/Conscia.Api/Program.cs`
  Configures API versioning, OpenAPI grouping, compatibility config/services, route root changes, and endpoint registration.
- Create: `src/Conscia.Api/Versioning/AppCompatibilityOptions.cs`
  Holds current and previous supported app-release config.
- Create: `src/Conscia.Api/Versioning/AppVersionMetadata.cs`
  Parses and compares `X-Conscia-App-Version` values.
- Create: `src/Conscia.Api/Versioning/AppCompatibilityMiddleware.cs`
  Blocks unsupported app releases before endpoint execution.
- Modify: `src/Conscia.Api/appsettings.json`
  Seeds production-facing compatibility config defaults.
- Modify: `src/Conscia.Api/appsettings.Development.json`
  Seeds development-friendly compatibility config defaults.
- Modify: `src/Conscia.Api/Endpoints/*.cs`
  Moves route groups from `/api/v1/...` to `/api/...`.
- Create: `tests/Conscia.Tests.Integration/ApiVersioningTests.cs`
  Verifies query-string canonical routing and optional header routing.
- Create: `tests/Conscia.Tests.Integration/AppCompatibilityTests.cs`
  Verifies current/previous supported app behavior and upgrade-required responses.
- Modify: `app/lib/core/constants/api_constants.dart`
  Changes base URL default from `/api/v1/` to `/api/`.
- Modify: `app/lib/core/network/dio_client.dart`
  Injects `v=1` and `X-Conscia-App-Version` centrally while preserving health checks.
- Modify: `app/test/core/network/dio_client_test.dart`
  Verifies version/query/header injection behavior.
- Modify: `app/lib/providers/app_availability_provider.dart`
  Maps backend upgrade-required responses into the existing update-required state.
- Modify: `app/pubspec.yaml`
  Keeps existing `package_info_plus` usage explicit for request metadata.
- Modify: `.github/CICD_SETUP.md`
  Rewrites the setup doc into 3 phases and updates API examples to `/api/` + `?v=1`.
- Modify: `.github/GITHUB_SECRETS.template.md`
  Aligns doc wording with phase boundaries and current wiring state.
- Modify: `README.md`
  Updates API examples, Flutter run commands, and route docs away from `/api/v1`.
- Modify: `release-matrix.md`
  Records API contract version plus current/previous supported app release policy.

### Task 1: Add ASP.NET API Versioning And App Compatibility Types

**Files:**
- Create: `src/Conscia.Api/Versioning/AppCompatibilityOptions.cs`
- Create: `src/Conscia.Api/Versioning/AppVersionMetadata.cs`
- Modify: `src/Conscia.Api/Conscia.Api.csproj`
- Modify: `src/Conscia.Api/appsettings.json`
- Modify: `src/Conscia.Api/appsettings.Development.json`
- Test: `tests/Conscia.Tests.Integration/AppCompatibilityTests.cs`

- [ ] **Step 1: Write the failing integration test for unsupported app versions**

```csharp
[Fact]
public async Task GetUsersMe_ReturnsUpgradeRequired_WhenAppVersionIsOlderThanPreviousSupported()
{
    using var factory = new ConsciaApiFactory();
    using var client = factory.CreateClient();

    var request = new HttpRequestMessage(HttpMethod.Get, "/api/users/me?v=1");
    request.Headers.Add("X-Conscia-App-Version", "0.9.0+1");
    request.Headers.Authorization =
        new AuthenticationHeaderValue("Bearer", TestTokens.ValidMockJwt);

    var response = await client.SendAsync(request);

    Assert.Equal(HttpStatusCode.UpgradeRequired, response.StatusCode);
    var payload = await response.Content.ReadFromJsonAsync<JsonElement>();
    Assert.Equal("upgrade_required", payload.GetProperty("code").GetString());
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/Conscia.Tests.Integration --filter GetUsersMe_ReturnsUpgradeRequired_WhenAppVersionIsOlderThanPreviousSupported -v normal`
Expected: FAIL because no compatibility middleware/options exist yet.

- [ ] **Step 3: Add versioning packages and compatibility option types**

```xml
<PackageReference Include="Asp.Versioning.Http" Version="8.1.0" />
<PackageReference Include="Asp.Versioning.ApiExplorer" Version="8.1.0" />
```

```csharp
namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityOptions
{
    public const string SectionName = "AppCompatibility";

    public string CurrentSupportedAppVersion { get; set; } = "1.0.0+1";
    public string PreviousSupportedAppVersion { get; set; } = "1.0.0+1";
}
```

```csharp
namespace Conscia.Api.Versioning;

public sealed record AppVersionMetadata(int Major, int Minor, int Patch, int Build)
    : IComparable<AppVersionMetadata>
{
    public static bool TryParse(string? value, out AppVersionMetadata? version)
    {
        version = null;
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var parts = value.Split('+', 2, StringSplitOptions.TrimEntries);
        if (!Version.TryParse(parts[0], out var semantic))
        {
            return false;
        }

        var build = parts.Length == 2 && int.TryParse(parts[1], out var parsedBuild)
            ? parsedBuild
            : 0;

        version = new AppVersionMetadata(
            semantic.Major,
            semantic.Minor,
            semantic.Build,
            build);
        return true;
    }

    public int CompareTo(AppVersionMetadata? other)
    {
        if (other is null) return 1;
        var semanticComparison = Major.CompareTo(other.Major);
        if (semanticComparison != 0) return semanticComparison;
        semanticComparison = Minor.CompareTo(other.Minor);
        if (semanticComparison != 0) return semanticComparison;
        semanticComparison = Patch.CompareTo(other.Patch);
        if (semanticComparison != 0) return semanticComparison;
        return Build.CompareTo(other.Build);
    }
}
```

- [ ] **Step 4: Add compatibility config to appsettings**

```json
"AppCompatibility": {
  "CurrentSupportedAppVersion": "1.0.0+1",
  "PreviousSupportedAppVersion": "1.0.0+1"
}
```

- [ ] **Step 5: Run the targeted integration test again**

Run: `dotnet test tests/Conscia.Tests.Integration --filter GetUsersMe_ReturnsUpgradeRequired_WhenAppVersionIsOlderThanPreviousSupported -v normal`
Expected: FAIL because the middleware enforcement is still missing, but compile succeeds.

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Api/Conscia.Api.csproj src/Conscia.Api/appsettings.json src/Conscia.Api/appsettings.Development.json src/Conscia.Api/Versioning tests/Conscia.Tests.Integration/AppCompatibilityTests.cs
git commit -m "chore: add api versioning and compatibility config types"
```

### Task 2: Implement API Version Readers, `/api` Routes, And Compatibility Enforcement

**Files:**
- Modify: `src/Conscia.Api/Program.cs`
- Create: `src/Conscia.Api/Versioning/AppCompatibilityMiddleware.cs`
- Modify: `src/Conscia.Api/Endpoints/AuthEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/UserEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/RecurringEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/BudgetEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/CategoryEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/SubscriptionEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/AlertEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/PushNotificationEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/ReceiptEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/AIEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/ConscienceJourneyEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/SuggestionEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/ExchangeRateEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/UtteranceEndpoints.cs`
- Test: `tests/Conscia.Tests.Integration/ApiVersioningTests.cs`
- Test: `tests/Conscia.Tests.Integration/AppCompatibilityTests.cs`

- [ ] **Step 1: Write failing tests for query-string canonical routing and header fallback**

```csharp
[Fact]
public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByQuery()
{
    using var factory = new ConsciaApiFactory();
    using var client = factory.CreateClient();

    var response = await client.GetAsync("/api?v=1");

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
}

[Fact]
public async Task ApiRoot_ReturnsBadRequest_WhenVersionIsMissing()
{
    using var factory = new ConsciaApiFactory();
    using var client = factory.CreateClient();

    var response = await client.GetAsync("/api");

    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
}

[Fact]
public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByHeader()
{
    using var factory = new ConsciaApiFactory();
    using var client = factory.CreateClient();
    var request = new HttpRequestMessage(HttpMethod.Get, "/api");
    request.Headers.Add("X-Api-Version", "1");

    var response = await client.SendAsync(request);

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test tests/Conscia.Tests.Integration --filter "ApiRoot_" -v normal`
Expected: FAIL because the current API root is still `/api/v1` and version readers are not configured.

- [ ] **Step 3: Configure ASP.NET API versioning and compatibility middleware in `Program.cs`**

```csharp
using Asp.Versioning;
using Asp.Versioning.ApiExplorer;
using Conscia.Api.Versioning;
```

```csharp
builder.Services.Configure<AppCompatibilityOptions>(
    builder.Configuration.GetSection(AppCompatibilityOptions.SectionName));

builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = false;
    options.ReportApiVersions = true;
    options.ApiVersionReader = ApiVersionReader.Combine(
        new QueryStringApiVersionReader("v"),
        new HeaderApiVersionReader("X-Api-Version"));
})
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = false;
});
```

```csharp
app.UseMiddleware<AppCompatibilityMiddleware>();
```

- [ ] **Step 4: Implement compatibility middleware**

```csharp
namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityMiddleware
{
    private readonly RequestDelegate _next;

    public AppCompatibilityMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        IOptions<AppCompatibilityOptions> options)
    {
        if (!context.Request.Path.StartsWithSegments("/api"))
        {
            await _next(context);
            return;
        }

        if (!AppVersionMetadata.TryParse(
                context.Request.Headers["X-Conscia-App-Version"],
                out var requested))
        {
            await _next(context);
            return;
        }

        AppVersionMetadata.TryParse(options.Value.CurrentSupportedAppVersion, out var current);
        AppVersionMetadata.TryParse(options.Value.PreviousSupportedAppVersion, out var previous);

        if (previous is not null && requested!.CompareTo(previous) < 0)
        {
            context.Response.StatusCode = StatusCodes.Status426UpgradeRequired;
            await context.Response.WriteAsJsonAsync(new
            {
                code = "upgrade_required",
                message = "A newer version of Conscia is required.",
                currentSupportedAppVersion = options.Value.CurrentSupportedAppVersion
            });
            return;
        }

        await _next(context);
    }
}
```

- [ ] **Step 5: Move API routes from `/api/v1` to `/api`**

```csharp
app.MapGet("/api", () => Results.Ok(new { version = "1.0", service = "Conscia API" }))
    .HasApiVersion(new ApiVersion(1, 0))
    .WithName("ApiRoot")
    .WithTags("System");
```

```csharp
var group = routes.MapGroup("/api/auth").WithTags("Auth");
```

```csharp
return Results.Created($"/api/transactions/{txn.Id}", new
{
    txn.Id
});
```

- [ ] **Step 6: Run focused integration tests**

Run: `dotnet test tests/Conscia.Tests.Integration --filter "ApiRoot_|GetUsersMe_ReturnsUpgradeRequired_WhenAppVersionIsOlderThanPreviousSupported" -v normal`
Expected: PASS for query/header canonical version tests and upgrade-required behavior.

- [ ] **Step 7: Run full backend test suites**

Run: `dotnet test tests/Conscia.Tests.Unit -v normal`
Expected: PASS

Run: `dotnet test tests/Conscia.Tests.Integration -v normal`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add src/Conscia.Api tests/Conscia.Tests.Integration
git commit -m "feat: switch api to query string versioning"
```

### Task 3: Update Flutter Base URL, Inject Canonical API Version, And Send App Version

**Files:**
- Modify: `app/lib/core/constants/api_constants.dart`
- Modify: `app/lib/core/network/dio_client.dart`
- Modify: `app/test/core/network/dio_client_test.dart`
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Write failing Dio tests for injected version query and app-version header**

```dart
test('injects canonical v=1 query parameter for relative api requests', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final adapter = _CapturingAdapter();
  final dio = container.read(dioProvider)..httpClientAdapter = adapter;

  await dio.get<dynamic>('/transactions');

  expect(adapter.lastRequestOptions!.queryParameters['v'], '1');
});

test('adds X-Conscia-App-Version header to relative api requests', () async {
  final container = ProviderContainer(
    overrides: [appVersionProvider.overrideWithValue('1.0.0+1')],
  );
  addTearDown(container.dispose);
  final adapter = _CapturingAdapter();
  final dio = container.read(dioProvider)..httpClientAdapter = adapter;

  await dio.get<dynamic>('/transactions');

  expect(adapter.lastRequestOptions!.headers['X-Conscia-App-Version'], '1.0.0+1');
});
```

- [ ] **Step 2: Run Flutter network tests to verify they fail**

Run: `flutter test app/test/core/network/dio_client_test.dart`
Expected: FAIL because the client does not inject query/version metadata yet.

- [ ] **Step 3: Change the base URL default and add a package-info-backed version provider**

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5248/api/',
);
```

```dart
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});
```

- [ ] **Step 4: Inject canonical query-string version and app-version header in `dio_client.dart`**

```dart
onRequest: (options, handler) async {
  if (!_isHealthRequest(options)) {
    options.queryParameters = <String, dynamic>{
      ...options.queryParameters,
      'v': options.queryParameters['v'] ?? '1',
    };

    final version = await ref.read(appVersionProvider.future);
    options.headers['X-Conscia-App-Version'] = version;
  }

  if (_isPublicRequest(options)) {
    return handler.next(options);
  }
```

- [ ] **Step 5: Keep health requests unversioned in tests**

```dart
test('does not inject v=1 for absolute health urls', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final adapter = _CapturingAdapter();
  final dio = container.read(dioProvider)..httpClientAdapter = adapter;

  await dio.get<dynamic>('http://localhost:5248/health/live');

  expect(adapter.lastRequestOptions!.queryParameters.containsKey('v'), isFalse);
});
```

- [ ] **Step 6: Run Flutter test file and then full app tests**

Run: `flutter test app/test/core/network/dio_client_test.dart`
Expected: PASS

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/lib/core/constants/api_constants.dart app/lib/core/network/dio_client.dart app/test/core/network/dio_client_test.dart app/pubspec.yaml
git commit -m "feat: send api version and app version from flutter client"
```

### Task 4: Map Backend Upgrade Responses Into The Existing App Availability Flow

**Files:**
- Modify: `app/lib/providers/app_availability_provider.dart`
- Modify: `app/lib/services/api_availability_service.dart`
- Modify: `app/test/providers/app_availability_provider_test.dart`

- [ ] **Step 1: Write failing provider test for upgrade-required API response**

```dart
test('maps backend upgrade required into updateRequired availability issue', () async {
  final notifier = AppAvailabilityNotifier(
    connectivityService: _OnlineConnectivityService(),
    apiAvailabilityService: _UpgradeRequiredApiAvailabilityService(),
    appUpdateService: _NoStoreUpdateService(),
    autoRefresh: false,
    refreshOnInit: false,
  );

  await notifier.refresh();

  expect(notifier.state.issue, AvailabilityIssue.updateRequired);
  expect(notifier.state.errorMessage, contains('required'));
});
```

- [ ] **Step 2: Run the provider test to verify it fails**

Run: `flutter test app/test/providers/app_availability_provider_test.dart`
Expected: FAIL because backend upgrade-required is treated like generic API unavailability.

- [ ] **Step 3: Add a typed upgrade-required exception path**

```dart
class ApiUpgradeRequiredException implements Exception {
  const ApiUpgradeRequiredException(this.message);
  final String message;
}
```

```dart
if (error.response?.statusCode == 426) {
  throw ApiUpgradeRequiredException(
    error.response?.data['message'] as String? ??
        'A newer version of Conscia is required.',
  );
}
```

```dart
} on ApiUpgradeRequiredException catch (error) {
  state = state.copyWith(
    issue: AvailabilityIssue.updateRequired,
    isLoading: false,
    lastChecked: checkedAt,
    errorMessage: error.message,
  );
  return;
}
```

- [ ] **Step 4: Run the provider test and app tests**

Run: `flutter test app/test/providers/app_availability_provider_test.dart`
Expected: PASS

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/providers/app_availability_provider.dart app/lib/services/api_availability_service.dart app/test/providers/app_availability_provider_test.dart
git commit -m "feat: surface backend upgrade requirements in app availability"
```

### Task 5: Rewrite CI/CD Setup Docs Into 3 Phases And Update Route Examples

**Files:**
- Modify: `.github/CICD_SETUP.md`
- Modify: `.github/GITHUB_SECRETS.template.md`
- Modify: `README.md`
- Modify: `release-matrix.md`

- [ ] **Step 1: Write the docs changes directly against the agreed design**

```md
## Phase 1 — Core Deploy Prerequisites
- AWS_DEPLOY_ROLE_ARN
- AWS_REGION
- CONSCIA_DOMAIN_NAME
- CONSCIA_WWW_DOMAIN_NAME
- CONSCIA_API_DOMAIN_NAME
- ROUTE53_HOSTED_ZONE_ID

Use these to enable:
- release-infra.yml
- release-api.yml
- release-web.yml
```

```md
## Phase 2 — Production Runtime Secrets And Backend Wiring
- AUTH_APP_JWT_SIGNING_KEY
- AUTH_GOOGLE_CLIENT_ID
- AUTH_APPLE_CLIENT_ID
- FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON
- GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

```md
## Phase 3 — Mobile Release Automation
- ANDROID_KEYSTORE_BASE64
- GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON
- APP_STORE_CONNECT_API_KEY_ID
- IOS_CERTIFICATE_P12_BASE64
```

```md
API base URL: `https://api.getconscia.com/api/`
Canonical version input: `?v=1`
Optional supported version header: `X-Api-Version: 1`
```

- [ ] **Step 2: Update route examples in README and release matrix**

```md
| `GET` | `/api?v=1` | No | API version info |
| `POST` | `/api/auth/login?v=1` | No | Authenticate with email/password |
```

```md
| Flutter App (app/) | API | api contract v=1 and current/previous supported app release |
```

- [ ] **Step 3: Review docs for stale `/api/v1` examples**

Run: `rg -n "/api/v1|API_BASE_URL=.*api/v1|https://api.getconscia.com/api/v1" README.md .github release-matrix.md`
Expected: no matches in updated primary docs.

- [ ] **Step 4: Commit**

```bash
git add .github/CICD_SETUP.md .github/GITHUB_SECRETS.template.md README.md release-matrix.md
git commit -m "docs: phase cicd setup and query versioning guidance"
```

### Task 6: Final Verification And Release Notes Sweep

**Files:**
- Modify: `release-matrix.md` (if verification reveals any missing compatibility note)
- Modify: `README.md` (if verification reveals any stale commands)

- [ ] **Step 1: Run backend verification**

Run: `dotnet test tests/Conscia.Tests.Unit -v normal`
Expected: PASS

Run: `dotnet test tests/Conscia.Tests.Integration -v normal`
Expected: PASS

- [ ] **Step 2: Run Flutter verification**

Run: `flutter test`
Expected: PASS

- [ ] **Step 3: Run targeted stale-reference scan**

Run: `rg -n "/api/v1|http://localhost:5248/api/v1|https://api.getconscia.com/api/v1" src app README.md .github release-matrix.md`
Expected: only historical/spec/archive references remain, with active runtime/docs paths updated.

- [ ] **Step 4: Summarize coordinated release notes**

```md
- API routes moved from `/api/v1/...` to `/api/...`
- Canonical API version input is now `?v=1`
- `X-Api-Version` is accepted as secondary support
- Flutter app sends `X-Conscia-App-Version`
- Backend supports only current + previous app release
```

- [ ] **Step 5: Commit any final cleanup**

```bash
git add README.md release-matrix.md
git commit -m "chore: finalize query versioning rollout notes"
```
