# Session Refresh and Expiry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add silent token refresh with retry-once behavior and a dedicated session-expired experience instead of abrupt logout on `401`.

**Architecture:** Extend backend auth with a refresh endpoint, teach the app's Dio client to coordinate refresh/retry safely, and introduce an explicit session-expired auth state plus screen so expiry is handled intentionally.

**Tech Stack:** ASP.NET Core minimal APIs, Flutter, Riverpod, Dio, Flutter Secure Storage

---

### Task 1: Add backend refresh support

**Files:**
- Modify: `src/Conscia.Application/Interfaces/IAuthService.cs`
- Modify: `src/Conscia.Api/Endpoints/AuthEndpoints.cs`
- Modify: `src/Conscia.Infrastructure/Services/MockAuthService.cs`
- Test: `tests/Conscia.Tests.Unit/...` auth endpoint/service tests

- [ ] Add `RefreshAsync(string refreshToken, CancellationToken ct = default)` to `IAuthService`.
- [ ] Add a failing backend test for valid refresh token flow.
- [ ] Add a failing backend test for invalid refresh token rejection.
- [ ] Implement `POST /api/v1/auth/refresh`.
- [ ] Implement mock refresh-token parsing and token re-issuance in `MockAuthService`.
- [ ] Run focused backend tests.
- [ ] Commit with `feat:` or `fix:` conventional commit message.

### Task 2: Add explicit session-expired state to app auth

**Files:**
- Modify: `app/lib/providers/auth_provider.dart`
- Test: `app/test/...` auth or routing tests as needed

- [ ] Add an explicit `sessionExpired` auth status/state shape.
- [ ] Add notifier methods for session expiry transition separate from user logout.
- [ ] Add failing tests for session-expired state transitions.
- [ ] Implement the state changes.
- [ ] Run focused Flutter tests.
- [ ] Commit.

### Task 3: Implement Dio silent refresh and retry-once flow

**Files:**
- Modify: `app/lib/core/network/dio_client.dart`
- Modify: `app/lib/services/auth_service.dart`
- Possibly modify: `app/lib/providers/auth_provider.dart`
- Test: `app/test/...` network/auth integration tests

- [ ] Add failing tests for `401 -> refresh -> retry success`.
- [ ] Add failing tests for refresh failure -> session expired.
- [ ] Add refresh API method to `AuthService`.
- [ ] Replace immediate logout interceptor logic with refresh coordination.
- [ ] Ensure concurrent `401`s share one refresh attempt.
- [ ] Ensure original requests retry only once.
- [ ] Run focused Flutter tests.
- [ ] Commit.

### Task 4: Add session-expired screen and router handling

**Files:**
- Create: `app/lib/screens/onboarding/session_expired_screen.dart`
- Modify: `app/lib/core/routing/app_router.dart`
- Test: `app/test/core/routing/app_router_test.dart` or similar

- [ ] Add failing router/UI test for session-expired redirect.
- [ ] Implement a dedicated `Session expired` screen with sign-in CTA.
- [ ] Route session-expired auth state to that screen.
- [ ] Verify successful sign-in exits the expired state correctly.
- [ ] Run focused Flutter tests.
- [ ] Commit.

### Task 5: Regression verification

**Files:**
- Reuse changed files above

- [ ] Run focused backend auth tests.
- [ ] Run focused Flutter auth/router/session tests.
- [ ] Run `flutter analyze` on touched app files.
- [ ] Run `dotnet build` for API.
- [ ] Commit any final cleanup.

