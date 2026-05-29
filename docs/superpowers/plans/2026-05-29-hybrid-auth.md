# Hybrid Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore in-app email auth, add in-app password reset with auto sign-in, keep Google/Apple through Cognito, add passkey-first account selection, and remove Cognito managed-login styling.

**Architecture:** Email/password flows use the app API backed by Cognito SDK calls. Social auth continues to use Cognito hosted OAuth for provider handoff and JWT issuance. Passkey-first state is local to the device and only includes emails that completed passkey registration locally.

**Tech Stack:** Flutter, Riverpod, GoRouter, Dio, SharedPreferences, ASP.NET minimal APIs, AWS Cognito Identity Provider, AWS CDK.

---

### Task 1: Add API Password Reset Contract

**Files:**
- Modify: `src/Conscia.Application/Interfaces/IAuthService.cs`
- Modify: `src/Conscia.Infrastructure/Services/CognitoAuthService.cs`
- Modify: `src/Conscia.Api/Endpoints/AuthEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/AuthEndpointTests.cs`

- [ ] Add a failing endpoint test for `POST /api/auth/password-reset/start` with a valid email returning success.
- [ ] Add a failing endpoint test for `POST /api/auth/password-reset/confirm` with email, code, and password returning success.
- [ ] Add `StartPasswordResetAsync(email)` and `ConfirmPasswordResetAsync(email, code, newPassword)` to `IAuthService`.
- [ ] Implement the methods in `CognitoAuthService` with `ForgotPasswordAsync` and `ConfirmForgotPasswordAsync`.
- [ ] Add minimal endpoint request records and route handlers.
- [ ] Run `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter AuthEndpointTests`.
- [ ] Commit with `feat(api): add password reset endpoints`.

### Task 2: Add App Password Reset Service and Provider Methods

**Files:**
- Modify: `app/lib/core/constants/api_constants.dart`
- Modify: `app/lib/services/auth_service.dart`
- Modify: `app/lib/providers/auth_provider.dart`
- Test: `app/test/providers/auth_provider_test.dart`

- [ ] Add failing provider tests proving `startPasswordReset(email)` calls the service and stores the reset email.
- [ ] Add failing provider tests proving `confirmPasswordReset(code, password)` confirms reset and auto signs in.
- [ ] Add `passwordResetStart` and `passwordResetConfirm` API constants.
- [ ] Add `AuthService.startPasswordReset` and `AuthService.confirmPasswordReset`.
- [ ] Add `AuthNotifier.startPasswordReset` and `AuthNotifier.confirmPasswordReset`, reusing token persistence after auto sign-in.
- [ ] Run `flutter test test/providers/auth_provider_test.dart` from `app`.
- [ ] Commit with `feat(app): add password reset auth state`.

### Task 3: Restore Email Sign-In, Sign-Up, and Add Reset UI

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_up_screen.dart`
- Create: `app/lib/screens/onboarding/password_reset_screen.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Test: `app/test/screens/onboarding/sign_up_screen_test.dart`
- Create: `app/test/screens/onboarding/password_reset_screen_test.dart`

- [ ] Add failing widget tests for restored sign-in password field, normal login submission, forgot-password navigation, and quiet social cancellation.
- [ ] Add failing widget tests for restored sign-up password and confirm password fields.
- [ ] Add failing widget tests for the reset screen email step, code/new-password step, and auto sign-in success route.
- [ ] Restore the email/password sign-in UI from pre-managed-login history while preserving current visual style.
- [ ] Restore the sign-up password fields and validation from pre-managed-login history.
- [ ] Add `AppRoutes.passwordReset` and a route for `PasswordResetScreen`.
- [ ] Implement the reset screen with email, code, password, and confirm password fields.
- [ ] Run the three onboarding widget test files.
- [ ] Commit with `feat(app): restore in-app email auth screens`.

### Task 4: Add Local Passkey-First Registry and Preference

**Files:**
- Modify: `app/lib/providers/passkey_provider.dart`
- Modify: `app/lib/services/passkey_service.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Test: `app/test/services/passkey_service_test.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`

- [ ] Add failing service/provider tests for storing, loading, and removing locally registered passkey emails.
- [ ] Add failing sign-in widget tests for one registered account, multiple registered accounts, and "Sign in with email".
- [ ] Store the current user email after successful passkey registration.
- [ ] Add a local passkey-first preference backed by `SharedPreferences`.
- [ ] Show passkey-first UI only when the preference is enabled and the local registry has accounts.
- [ ] Keep email sign-in available from passkey-first mode.
- [ ] Run passkey service tests and sign-in widget tests.
- [ ] Commit with `feat(app): add passkey-first sign-in preference`.

### Task 5: Clean Up Managed Login Branding and Social Cancellation

**Files:**
- Modify: `app/lib/providers/auth_provider.dart`
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `infra/src/Conscia.Infra/AuthStack.cs`
- Modify: `infra/tests/Conscia.Infra.Tests/StackTests.cs`
- Test: `app/test/providers/auth_provider_test.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Test: `infra/tests/Conscia.Infra.Tests/StackTests.cs`

- [ ] Add failing app tests proving managed-login cancellation from Google/Apple leaves no inline error.
- [ ] Add failing infra tests proving `AWS::Cognito::ManagedLoginBranding` is absent while Google/Apple IdPs remain configured.
- [ ] Map `CognitoManagedLoginCancelledException` to a quiet no-op for social auth.
- [ ] Remove custom managed-login branding constants, assets, and settings from `AuthStack`.
- [ ] Run focused app and infra tests.
- [ ] Commit with `fix(app): silence cancelled social sign-in` and `fix(infra): remove managed login branding`.

### Task 6: Final Verification

**Files:**
- Read: `git status -sb`
- Read: relevant diffs

- [ ] Run `flutter test test/providers/auth_provider_test.dart test/screens/onboarding/sign_in_screen_test.dart test/screens/onboarding/sign_up_screen_test.dart test/screens/onboarding/password_reset_screen_test.dart test/services/passkey_service_test.dart` from `app`.
- [ ] Run `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "AuthEndpointTests|ReleaseInfraWorkflowTests"`.
- [ ] Run `dotnet test infra/tests/Conscia.Infra.Tests/Conscia.Infra.Tests.csproj --filter StackTests`.
- [ ] Inspect `git status -sb` and confirm only intended files remain changed.
