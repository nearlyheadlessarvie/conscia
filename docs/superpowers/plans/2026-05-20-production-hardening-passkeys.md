# Production Hardening, Invite Email, and Passkeys Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fail closed for fake production integrations, wire required runtime secrets into deployed API environments, add real family invite email deep links, remove faux biometric sign-in, and add Cognito-native passkeys for Conscia accounts.

**Architecture:** The rollout is staged. First, harden backend and infra so production no longer silently degrades into mock, stub, or no-op behavior. Next, add real invite email delivery alongside in-app alerts and push. Finally, replace the local-auth biometric shim with a Cognito-native passkey flow while leaving native Google and Apple sign-in on their current auth lane.

**Tech Stack:** ASP.NET Core, AWS CDK, AWS Lambda, Cognito User Pools, SES, Flutter, Riverpod, GitHub Actions

---

## File Map

### Backend hardening

- Modify: `src/Conscia.Infrastructure/Services/SubscriptionService.cs`
- Modify: `src/Conscia.Infrastructure/Services/ReceiptService.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Create: `src/Conscia.Api/Configuration/ProductionRuntimeOptions.cs`
- Create: `src/Conscia.Api/Configuration/ProductionRuntimeOptionsValidator.cs`
- Create: `src/Conscia.Infrastructure/Services/ConfiguredPushNotificationSender.cs` or equivalent real sender abstraction if implemented now
- Modify: `src/Conscia.Infrastructure/Services/NoopPushNotificationSender.cs`
- Modify: `src/Conscia.Infrastructure/Services/StubOcrService.cs`

### Family invites and email delivery

- Modify: `src/Conscia.Application/Services/FamilySpaceService.cs`
- Modify: `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
- Create: `src/Conscia.Application/Interfaces/IInviteEmailSender.cs`
- Create: `src/Conscia.Infrastructure/Services/SesInviteEmailSender.cs`
- Create: `src/Conscia.Application/Configuration/InviteEmailOptions.cs`
- Modify: `src/Conscia.Api/Endpoints/FamilySpaceEndpoints.cs`
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/family/family_invites_screen.dart`

### Infra and deploy wiring

- Modify: `infra/src/Conscia.Infra/ComputeStack.cs`
- Modify: `infra/src/Conscia.Infra/OutboxStack.cs`
- Modify: `.github/workflows/release-api.yml`
- Modify: `.github/workflows/release-infra.yml`
- Modify: `.github/CICD_SETUP.md`
- Modify: `.github/GITHUB_SECRETS.template.md`

### Passkeys and biometric replacement

- Modify: `app/pubspec.yaml`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Create: `app/lib/services/passkey_service.dart`
- Create: `app/lib/providers/passkey_provider.dart`
- Modify: `app/lib/providers/auth_provider.dart`
- Modify: `src/Conscia.Api/Endpoints/AuthEndpoints.cs`
- Create: `src/Conscia.Application/DTOs/PasskeyDtos.cs`
- Create: `src/Conscia.Application/Interfaces/IPasskeyAuthService.cs`
- Create: `src/Conscia.Infrastructure/Services/CognitoPasskeyAuthService.cs`

### Tests

- Modify: `tests/Conscia.Tests.Unit/...` relevant API/application tests
- Modify: `infra/tests/Conscia.Infra.Tests/StackTests.cs`
- Modify: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Modify: `app/test/screens/settings/settings_screen_test.dart`
- Modify: `app/test/screens/family/family_invites_screen_test.dart`
- Modify: `app/test/core/routing/app_router_test.dart`

---

### Task 1: Lock Down Subscription Verification

**Files:**
- Modify: `src/Conscia.Infrastructure/Services/SubscriptionService.cs`
- Test: `tests/Conscia.Tests.Unit/Application/SubscriptionServiceTests.cs`

- [ ] **Step 1: Write failing tests for unconfigured validators**

Add tests that assert iOS and Android verification reject requests when validators are not configured instead of granting a one-month Premium fallback.

```csharp
[Fact]
public async Task VerifyiOSReceiptAsync_Throws_WhenAppleValidationIsNotConfigured()
{
    var subscriptions = new InMemoryUserSubscriptionRepository();
    var service = new SubscriptionService(
        subscriptions,
        NullLogger<SubscriptionService>.Instance,
        new FakeAppleReceiptValidator(isConfigured: false),
        new FakeGooglePlayValidator(isConfigured: true));

    var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
        service.VerifyiOSReceiptAsync(Guid.NewGuid(), "receipt-token"));

    ex.Message.Should().Contain("Apple");
}

[Fact]
public async Task VerifyAndroidTokenAsync_Throws_WhenGoogleValidationIsNotConfigured()
{
    var subscriptions = new InMemoryUserSubscriptionRepository();
    var service = new SubscriptionService(
        subscriptions,
        NullLogger<SubscriptionService>.Instance,
        new FakeAppleReceiptValidator(isConfigured: true),
        new FakeGooglePlayValidator(isConfigured: false));

    var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
        service.VerifyAndroidTokenAsync(Guid.NewGuid(), "purchase-token"));

    ex.Message.Should().Contain("Google Play");
}
```

- [ ] **Step 2: Run the focused subscription tests and verify failure**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter SubscriptionService
```

Expected: FAIL because the service still falls back to `DateTime.UtcNow.AddMonths(1)`.

- [ ] **Step 3: Remove fail-open fallback from subscription verification**

Update `SubscriptionService` so unconfigured validators cause explicit rejection instead of subscription creation.

```csharp
if (!_appleValidator.IsConfigured)
{
    _logger.LogError(
        "Apple receipt verification attempted without Apple validator configuration for user {UserId}",
        userId);
    throw new InvalidOperationException("Apple subscription verification is not configured.");
}
```

```csharp
if (!_googleValidator.IsConfigured)
{
    _logger.LogError(
        "Google Play verification attempted without Google validator configuration for user {UserId}",
        userId);
    throw new InvalidOperationException("Google Play subscription verification is not configured.");
}
```

- [ ] **Step 4: Run the focused subscription tests and verify pass**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter SubscriptionService
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Infrastructure/Services/SubscriptionService.cs tests/Conscia.Tests.Unit
git commit -m "fix(api): fail closed on unconfigured subscription validation"
```

### Task 2: Disable Receipt Scan Until Real OCR Is Configured

**Files:**
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `src/Conscia.Infrastructure/Services/ReceiptService.cs`
- Modify: `src/Conscia.Infrastructure/Services/StubOcrService.cs`
- Test: `tests/Conscia.Tests.Unit/Api/ReceiptEndpointsTests.cs`

- [ ] **Step 1: Write a failing test for receipt scan when OCR is unavailable**

Add an API-level test that expects a clear configuration failure instead of a fake parsed receipt result.

```csharp
[Fact]
public async Task ScanReceipt_ReturnsServerError_WhenOcrIsNotConfigured()
{
    using var app = new TestWebAppFactory()
        .WithStubbedOcrUnavailable();

    using var client = app.CreateClient();
    using var content = new MultipartFormDataContent
    {
        { new StreamContent(new MemoryStream([1, 2, 3])), "image", "receipt.jpg" }
    };

    var response = await client.PostAsync("/api/receipts/scan?v=1", content);

    response.StatusCode.Should().Be(HttpStatusCode.ServiceUnavailable);
}
```

- [ ] **Step 2: Run the focused receipt scan test and verify failure**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter ScanReceipt_ReturnsServerError_WhenOcrIsNotConfigured
```

Expected: FAIL because scan still succeeds with stubbed output.

- [ ] **Step 3: Make receipt scanning fail closed when OCR is stubbed/unavailable**

Introduce an explicit “configured/unconfigured” concept on the OCR service path and reject scan requests when only stub behavior is available.

```csharp
if (!_ocr.IsConfigured)
{
    _logger.LogError("Receipt scanning attempted without OCR configuration");
    throw new InvalidOperationException("Receipt scanning is not configured.");
}
```

Map that failure to a non-success status in the receipt endpoint, for example `503 Service Unavailable`.

- [ ] **Step 4: Run the focused receipt scan test and verify pass**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter ScanReceipt_ReturnsServerError_WhenOcrIsNotConfigured
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Api/Program.cs src/Conscia.Infrastructure/Services/ReceiptService.cs src/Conscia.Infrastructure/Services/StubOcrService.cs tests/Conscia.Tests.Unit
git commit -m "fix(api): reject receipt scans when OCR is unconfigured"
```

### Task 3: Add Production Runtime Configuration Validation

**Files:**
- Create: `src/Conscia.Api/Configuration/ProductionRuntimeOptions.cs`
- Create: `src/Conscia.Api/Configuration/ProductionRuntimeOptionsValidator.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Test: `tests/Conscia.Tests.Unit/Api/ProductionRuntimeOptionsValidatorTests.cs`

- [ ] **Step 1: Write failing validator tests**

Add tests that assert production runtime validation fails when required auth/runtime configuration is missing.

```csharp
[Fact]
public void Validate_ProductionConfig_Fails_WhenAppJwtSigningKeyMissing()
{
    var options = new ProductionRuntimeOptions
    {
        EnvironmentName = "Production",
        CognitoClientId = "client",
        CognitoUserPoolId = "pool",
        GoogleClientId = "google-client",
        AppleClientId = "com.conscia.app"
    };

    var validator = new ProductionRuntimeOptionsValidator();
    var result = validator.Validate(string.Empty, options);

    result.Failed.Should().BeTrue();
}
```

- [ ] **Step 2: Run the focused validator tests and verify failure**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter ProductionRuntimeOptionsValidator
```

Expected: FAIL because validator does not exist yet.

- [ ] **Step 3: Implement production runtime validation and wire it into startup**

Create a startup validation model that checks required values when `ASPNETCORE_ENVIRONMENT=Production`.

```csharp
builder.Services
    .AddOptions<ProductionRuntimeOptions>()
    .BindConfiguration("ProductionRuntime")
    .ValidateOnStart();
builder.Services.AddSingleton<IValidateOptions<ProductionRuntimeOptions>, ProductionRuntimeOptionsValidator>();
```

Use raw configuration binding or mapped fields, but ensure the validator checks the real auth/store settings you depend on.

- [ ] **Step 4: Run the focused validator tests and verify pass**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter ProductionRuntimeOptionsValidator
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Api/Configuration src/Conscia.Api/Program.cs tests/Conscia.Tests.Unit
git commit -m "fix(api): validate production runtime configuration on startup"
```

### Task 4: Wire Runtime Secrets and Config Through Deployments

**Files:**
- Modify: `infra/src/Conscia.Infra/ComputeStack.cs`
- Modify: `.github/workflows/release-api.yml`
- Modify: `.github/workflows/release-infra.yml`
- Modify: `.github/CICD_SETUP.md`
- Modify: `.github/GITHUB_SECRETS.template.md`
- Test: `infra/tests/Conscia.Infra.Tests/StackTests.cs`

- [ ] **Step 1: Write failing infra tests for missing Lambda environment wiring**

Add assertions that the API Lambda template includes the required env vars for auth and store validation.

```csharp
[Fact]
public void ComputeStack_EmitsExpectedAuthEnvironmentVariables()
{
    var template = Template.FromStack(CreateComputeStack());

    template.HasResourceProperties("AWS::Lambda::Function", new Dictionary<string, object>
    {
        ["Environment"] = new Dictionary<string, object>
        {
            ["Variables"] = Match.ObjectLike(new Dictionary<string, object>
            {
                ["Auth__AppJwtSigningKey"] = Match.AnyValue(),
                ["Auth__Google__ClientId"] = Match.AnyValue(),
                ["Auth__Apple__ClientId"] = Match.AnyValue()
            })
        }
    });
}
```

- [ ] **Step 2: Run the infra tests and verify failure**

Run:

```bash
dotnet test infra/tests/Conscia.Infra.Tests
```

Expected: FAIL because the variables are not injected yet.

- [ ] **Step 3: Thread deploy secrets from GitHub Actions into CDK and Lambda**

Update the release workflows to pass required environment values into `cdk deploy`, and update `ComputeStack` to place them into Lambda environment variables.

Representative workflow pattern:

```yaml
env:
  AUTH_APP_JWT_SIGNING_KEY: ${{ secrets.AUTH_APP_JWT_SIGNING_KEY }}
  AUTH_GOOGLE_CLIENT_ID: ${{ secrets.AUTH_GOOGLE_CLIENT_ID }}
  AUTH_APPLE_CLIENT_ID: ${{ secrets.AUTH_APPLE_CLIENT_ID }}
```

Representative CDK environment mapping:

```csharp
["Auth__AppJwtSigningKey"] = Environment.GetEnvironmentVariable("AUTH_APP_JWT_SIGNING_KEY") ?? string.Empty,
["Auth__Google__ClientId"] = Environment.GetEnvironmentVariable("AUTH_GOOGLE_CLIENT_ID") ?? string.Empty,
["Auth__Apple__ClientId"] = Environment.GetEnvironmentVariable("AUTH_APPLE_CLIENT_ID") ?? string.Empty,
```

Also wire Apple, Google Play, invite email, and push-related settings needed by the runtime.

- [ ] **Step 4: Run the infra tests and verify pass**

Run:

```bash
dotnet test infra/tests/Conscia.Infra.Tests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add infra/src/Conscia.Infra/ComputeStack.cs infra/tests/Conscia.Infra.Tests .github/workflows/release-api.yml .github/workflows/release-infra.yml .github/CICD_SETUP.md .github/GITHUB_SECRETS.template.md
git commit -m "fix(infra): wire production runtime secrets into api deploys"
```

### Task 5: Restore Correct API Gateway Throttling Rules

**Files:**
- Modify: `infra/src/Conscia.Infra/ComputeStack.cs`
- Test: `infra/tests/Conscia.Infra.Tests/StackTests.cs`

- [ ] **Step 1: Write a failing test for current route throttles**

Assert the synthesized API stage method options target `/api/...` instead of `/api/v1/...`.

```csharp
[Fact]
public void ComputeStack_UsesQueryVersionedRoutePathsForApiGatewayThrottleOverrides()
{
    var template = Template.FromStack(CreateComputeStack());
    template.HasResourceProperties("AWS::ApiGateway::Stage", Match.SerializedJson(Match.Not(Match.StringLikeRegexp("/api/v1/"))));
}
```

- [ ] **Step 2: Run the infra tests and verify failure**

Run:

```bash
dotnet test infra/tests/Conscia.Infra.Tests --filter ComputeStack_UsesQueryVersionedRoutePathsForApiGatewayThrottleOverrides
```

Expected: FAIL because overrides still reference `/api/v1/...`.

- [ ] **Step 3: Update throttle paths to current routes**

Replace the old method option keys with `/api/ai/pre-purchase/POST`, `/api/ai/reflection/POST`, and `/api/receipts/scan/POST`.

- [ ] **Step 4: Run the infra tests and verify pass**

Run:

```bash
dotnet test infra/tests/Conscia.Infra.Tests --filter ComputeStack_UsesQueryVersionedRoutePathsForApiGatewayThrottleOverrides
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add infra/src/Conscia.Infra/ComputeStack.cs infra/tests/Conscia.Infra.Tests
git commit -m "fix(infra): align api gateway throttles with query versioned routes"
```

### Task 6: Add Real Invite Email Delivery and Deep Links

**Files:**
- Create: `src/Conscia.Application/Interfaces/IInviteEmailSender.cs`
- Create: `src/Conscia.Application/Configuration/InviteEmailOptions.cs`
- Create: `src/Conscia.Infrastructure/Services/SesInviteEmailSender.cs`
- Modify: `src/Conscia.Infrastructure/Services/OutboxProcessor.cs`
- Modify: `src/Conscia.Application/Services/FamilySpaceService.cs`
- Test: `tests/Conscia.Tests.Unit/Application/OutboxProcessorTests.cs`

- [ ] **Step 1: Write failing tests for invite email dispatch**

Add tests covering:
- invite to unregistered email still sends email
- existing user gets in-app alert and email
- email contains deep link target

```csharp
[Fact]
public async Task FamilyInviteCreated_SendsInviteEmail_WhenTargetUserDoesNotExist()
{
    var emailSender = new FakeInviteEmailSender();
    var processor = CreateOutboxProcessor(emailSender: emailSender, existingUser: null);

    await processor.ProcessBatchAsync(CancellationToken.None);

    emailSender.Sent.Should().ContainSingle();
    emailSender.Sent[0].DeepLink.Should().Contain("/settings/family-space/invites");
}
```

- [ ] **Step 2: Run the focused outbox tests and verify failure**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter FamilyInviteCreated
```

Expected: FAIL because no invite email sender exists yet.

- [ ] **Step 3: Implement invite email sender and deep link email path**

Create an invite email abstraction and call it from outbox processing before or alongside user-specific alert handling.

```csharp
await inviteEmailSender.SendFamilyInviteAsync(new FamilyInviteEmail(
    invite.Email,
    invite.FamilySpaceName,
    invite.Role,
    invite.ExpiresAt,
    inviteLink));
```

Use a configurable HTTPS app link such as `https://getconscia.com/open/family-invite?...` that ultimately routes into the app’s family invite screen.

- [ ] **Step 4: Run the focused outbox tests and verify pass**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter FamilyInviteCreated
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Application src/Conscia.Infrastructure tests/Conscia.Tests.Unit
git commit -m "feat(api): send family invite emails with app deep links"
```

### Task 7: Route Invite Deep Links Into the App

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/family/family_invites_screen.dart`
- Test: `app/test/core/routing/app_router_test.dart`

- [ ] **Step 1: Write a failing app routing test for family invite deep links**

Add a test that opens the deep-link route and lands on the invites screen.

```dart
testWidgets('family invite deep link opens invites screen', (tester) async {
  await pumpRouterApp(
    tester,
    initialLocation: '/settings/family-space/invites',
  );

  expect(find.text('Review your invites'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused routing test and verify failure**

Run:

```bash
flutter test test/core/routing/app_router_test.dart --plain-name "family invite deep link opens invites screen"
```

Expected: FAIL if route/deep-link handling is incomplete.

- [ ] **Step 3: Make the family invite route fully deep-linkable**

Ensure the route is addressable directly, does not depend on prior navigation state, and renders pending invites affordances on entry.

- [ ] **Step 4: Run the focused routing test and verify pass**

Run:

```bash
flutter test test/core/routing/app_router_test.dart --plain-name "family invite deep link opens invites screen"
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/routing/app_router.dart app/lib/screens/family/family_invites_screen.dart app/test/core/routing/app_router_test.dart
git commit -m "feat(app): support deep links into family invites"
```

### Task 8: Remove Faux Biometric Sign-In

**Files:**
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Test: `app/test/screens/settings/settings_screen_test.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`

- [ ] **Step 1: Write failing UI tests for biometric removal**

Add tests asserting the old toggle and button are no longer shown.

```dart
testWidgets('settings does not show legacy biometric toggle', (tester) async {
  await pumpSettingsScreen(tester);
  expect(find.text('Biometric Sign-In'), findsNothing);
});

testWidgets('sign in screen does not show legacy biometric sign in button', (tester) async {
  await pumpSignInScreen(tester);
  expect(find.text('Sign in with Biometrics'), findsNothing);
});
```

- [ ] **Step 2: Run the focused Flutter tests and verify failure**

Run:

```bash
flutter test test/screens/settings/settings_screen_test.dart test/screens/onboarding/sign_in_screen_test.dart
```

Expected: FAIL because the old UI is still present.

- [ ] **Step 3: Remove local-auth biometric UI and stored-token unlock path**

Delete the old biometric toggle, sign-in button, and local-auth-only session restore path from the sign-in and settings screens.

- [ ] **Step 4: Run the focused Flutter tests and verify pass**

Run:

```bash
flutter test test/screens/settings/settings_screen_test.dart test/screens/onboarding/sign_in_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/settings/settings_screen.dart app/lib/screens/onboarding/sign_in_screen.dart app/test/screens/settings/settings_screen_test.dart app/test/screens/onboarding/sign_in_screen_test.dart
git commit -m "refactor(app): remove faux biometric sign in"
```

### Task 9: Add Passkey Service Contract and Backend Endpoints

**Files:**
- Create: `src/Conscia.Application/DTOs/PasskeyDtos.cs`
- Create: `src/Conscia.Application/Interfaces/IPasskeyAuthService.cs`
- Create: `src/Conscia.Infrastructure/Services/CognitoPasskeyAuthService.cs`
- Modify: `src/Conscia.Api/Endpoints/AuthEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/PasskeyEndpointsTests.cs`

- [ ] **Step 1: Write failing API tests for passkey endpoints**

Add tests for:
- begin registration
- complete registration
- begin sign-in
- complete sign-in

```csharp
[Fact]
public async Task BeginPasskeySignIn_ReturnsChallengePayload()
{
    using var app = new TestWebAppFactory()
        .WithPasskeyService(new FakePasskeyAuthService());
    using var client = app.CreateClient();

    var response = await client.PostAsJsonAsync("/api/auth/passkeys/begin-sign-in?v=1", new
    {
        email = "demo@example.com"
    });

    response.StatusCode.Should().Be(HttpStatusCode.OK);
}
```

- [ ] **Step 2: Run the focused passkey endpoint tests and verify failure**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter Passkey
```

Expected: FAIL because the endpoints and service do not exist yet.

- [ ] **Step 3: Introduce passkey DTOs, service interface, and Cognito-backed endpoint surface**

Add endpoint contracts such as:

```csharp
group.MapPost("/passkeys/begin-sign-in", async (BeginPasskeySignInRequest req, IPasskeyAuthService svc, HttpContext ctx) =>
{
    var challenge = await svc.BeginSignInAsync(req.Email, ctx.RequestAborted);
    return Results.Ok(challenge);
});
```

Keep the service boundary narrow so the Flutter app only depends on stable DTOs, not Cognito internals.

- [ ] **Step 4: Run the focused passkey endpoint tests and verify pass**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit --filter Passkey
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Conscia.Application src/Conscia.Infrastructure src/Conscia.Api tests/Conscia.Tests.Unit
git commit -m "feat(api): add cognito passkey auth endpoints"
```

### Task 10: Add Flutter Passkey Client and UI

**Files:**
- Modify: `app/pubspec.yaml`
- Create: `app/lib/services/passkey_service.dart`
- Create: `app/lib/providers/passkey_provider.dart`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Test: `app/test/screens/settings/settings_screen_test.dart`

- [ ] **Step 1: Write failing Flutter tests for passkey actions**

Add tests for:
- `Sign in with Passkey` button on sign-in screen
- `Set up Passkey` or `Manage Passkey` action in settings for Cognito-native users

```dart
testWidgets('sign in screen shows passkey sign in action', (tester) async {
  await pumpSignInScreen(tester);
  expect(find.text('Sign in with Passkey'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused Flutter tests and verify failure**

Run:

```bash
flutter test test/screens/onboarding/sign_in_screen_test.dart test/screens/settings/settings_screen_test.dart
```

Expected: FAIL because passkey UI does not exist yet.

- [ ] **Step 3: Implement Flutter passkey service and wire UI**

Add a passkey service abstraction that talks to the new backend endpoints and invokes the platform passkey flow through the chosen Flutter integration.

Representative service shape:

```dart
class PasskeyService {
  Future<void> signInWithPasskey(String email);
  Future<void> registerPasskey();
}
```

Settings should expose passkey enrollment for Cognito-native users only. Sign-in screen should expose passkey sign-in without surfacing it as a Google/Apple replacement.

- [ ] **Step 4: Run the focused Flutter tests and verify pass**

Run:

```bash
flutter test test/screens/onboarding/sign_in_screen_test.dart test/screens/settings/settings_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/pubspec.yaml app/lib/services/passkey_service.dart app/lib/providers/passkey_provider.dart app/lib/screens/onboarding/sign_in_screen.dart app/lib/screens/settings/settings_screen.dart app/test/screens/onboarding/sign_in_screen_test.dart app/test/screens/settings/settings_screen_test.dart
git commit -m "feat(app): add cognito passkey sign in and enrollment"
```

### Task 11: Verify End-to-End and Update Docs

**Files:**
- Modify: `README.md`
- Modify: `.github/CICD_SETUP.md`
- Modify: `.github/GITHUB_SECRETS.template.md`

- [ ] **Step 1: Update docs for fail-closed behavior and passkeys**

Document:
- receipt scan requirements
- subscription verification requirements
- invite email setup
- passkey support scope
- removal of old biometric sign-in

- [ ] **Step 2: Run backend verification**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit -v minimal
```

Expected: PASS

- [ ] **Step 3: Run infra verification**

Run:

```bash
dotnet test infra/tests/Conscia.Infra.Tests -v minimal
cd infra
cdk synth Conscia-Compute
```

Expected: PASS and successful synth

- [ ] **Step 4: Run Flutter verification**

Run:

```bash
flutter analyze
flutter test
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md .github/CICD_SETUP.md .github/GITHUB_SECRETS.template.md
git commit -m "docs: document hardened production setup and passkeys"
```

---

## Self-Review

### Spec coverage

- Fail-closed subscriptions: covered by Task 1
- Receipt scan hardening: covered by Task 2
- Production runtime validation: covered by Task 3
- Runtime secret/config wiring: covered by Task 4
- Throttling fix: covered by Task 5
- Invite email and deep links: covered by Tasks 6 and 7
- Remove faux biometrics: covered by Task 8
- Cognito-native passkeys: covered by Tasks 9 and 10
- Docs and verification: covered by Task 11

### Placeholder scan

- No `TODO`, `TBD`, or “similar to above” placeholders remain
- Code-oriented steps include concrete file targets and representative code shapes

### Type consistency

- Backend passkey work consistently uses `IPasskeyAuthService`
- Invite email work consistently uses `IInviteEmailSender`
- Passkey UI consistently replaces biometric UI rather than coexisting with it

