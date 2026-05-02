# Identity Linking + Social Auth Tasks

## Phase 1: Foundation (Domain Entities, Enum, EF Config, Schema)

- [ ] [B] Create `AuthProvider` enum in `src/Conscia.Domain/Enums/AuthProvider.cs` with values `Email`, `Google`, `Apple`
- [ ] [B] Create `UserIdentity` entity in `src/Conscia.Domain/Entities/UserIdentity.cs` with `Id`, `UserId`, `Provider` (AuthProvider), `ProviderSub`, `CreatedAt`
- [ ] [B] Remove `CognitoSub` property from `User` entity in `src/Conscia.Domain/Entities/User.cs`
- [ ] [B] Create `UserIdentityConfiguration` in `src/Conscia.Infrastructure/Persistence/Configurations/UserIdentityConfiguration.cs` — table `user_identities`, Provider as varchar(20), ProviderSub varchar(256) required, unique composite index on `(Provider, ProviderSub)`, index on `UserId`
- [ ] [B] Update `UserConfiguration.cs` — remove `CognitoSub` property config and its unique index, keep `Email` unique index
- [ ] [B] Add `DbSet<UserIdentity> UserIdentities` to `ConsciaDbContext.cs`
- [ ] [B] Update `seed-rds.sql` — remove `"CognitoSub"` column from users INSERT, add INSERT into `user_identities` for alice/bob/carol with `Provider='Email'` and their old cognito sub values as `ProviderSub`

## Phase 2: Core Logic — Repository & Service Refactor

- [ ] Write tests for `GetByProviderAsync` and `AddIdentityAsync` in `tests/Conscia.Tests.Unit/Infrastructure/UserRepositoryTests.cs` — test lookup via `UserIdentities` table, test adding a new identity row
- [ ] Update `IUserRepository.cs` — replace `GetByCognitoSubAsync` with `GetByProviderAsync(AuthProvider provider, string providerSub)`, add `AddIdentityAsync(UserIdentity identity)`
- [ ] Implement `GetByProviderAsync` and `AddIdentityAsync` in `UserRepository.cs` — query `UserIdentities` table joined to `Users`, add identity row with `SaveChangesAsync`
- [ ] Update existing `UserRepositoryTests.cs` — remove/replace `GetByCognitoSub_ReturnsCorrectUser` test, remove `CognitoSub` from all `User` object constructions
- [ ] Write tests for `GetByProviderAsync` delegation in `tests/Conscia.Tests.Unit/Application/UserServiceTests.cs`
- [ ] Update `IUserService.cs` — replace `GetByCognitoSubAsync` with `GetByProviderAsync(AuthProvider, string)`
- [ ] Update `UserService.cs` — replace `GetByCognitoSubAsync` delegation with `GetByProviderAsync`
- [ ] Update existing `UserServiceTests.cs` — replace `GetByCognitoSubAsync_DelegatesToRepo` test with `GetByProviderAsync` equivalent, remove `CognitoSub` from `User` constructions
- [ ] [P] Update `LambdaProxyUserRepository.cs` — replace `GetByCognitoSubAsync` with `GetByProviderAsync` proxy call, add `AddIdentityAsync` proxy call

## Phase 3: Core Logic — Auth Service Refactor

- [ ] [B] Add `LoginWithGoogleAsync(string idToken, CancellationToken)` and `LoginWithAppleAsync(string identityToken, string? authorizationCode, CancellationToken)` to `IAuthService.cs`
- [ ] Write tests for `LoginWithGoogleAsync` in `tests/Conscia.Tests.Unit/Infrastructure/MockAuthServiceTests.cs` — new user creation with Google identity, existing user linking by email, returning tokens
- [ ] Write tests for `LoginWithAppleAsync` in `MockAuthServiceTests.cs` — same pattern as Google but with Apple provider
- [ ] Write tests for updated `RegisterAsync` in `MockAuthServiceTests.cs` — verify it creates `UserIdentity(Provider=Email)` via repository
- [ ] Refactor `MockAuthService.cs` — inject `IUserRepository`, rewrite `RegisterAsync` to create `User` + `UserIdentity(Provider=Email)` in DB, rewrite `LoginAsync` to look up by email in DB, implement `LoginWithGoogleAsync` (decode mock token, lookup/create user + identity), implement `LoginWithAppleAsync` (same pattern), update `SeedUser` to create `UserIdentity` rows
- [ ] Update existing `MockAuthServiceTests.cs` setup — update constructor to provide a mock `IUserRepository`, fix all broken tests from the new constructor signature
- [ ] [P] Stub `LoginWithGoogleAsync` and `LoginWithAppleAsync` in `CognitoAuthService.cs` — log warnings, throw `NotImplementedException` (matching existing stub pattern)

## Phase 4: API Endpoints

- [ ] Create request DTOs `GoogleLoginRequest(string IdToken)` and `AppleLoginRequest(string IdentityToken, string? AuthorizationCode)` in `AuthEndpoints.cs`
- [ ] Write tests for `POST /auth/google` in `tests/Conscia.Tests.Unit/Api/AuthEndpointTests.cs` — valid token returns 200 with `accessToken`/`refreshToken`/`userId`, missing token returns 400
- [ ] Write tests for `POST /auth/apple` in `AuthEndpointTests.cs` — valid token returns 200, missing token returns 400
- [ ] Implement `POST /auth/google` endpoint in `AuthEndpoints.cs` — call `IAuthService.LoginWithGoogleAsync`, return `{ accessToken, refreshToken, userId }`, apply rate limiting
- [ ] Implement `POST /auth/apple` endpoint in `AuthEndpoints.cs` — call `IAuthService.LoginWithAppleAsync`, return same shape, apply rate limiting
- [ ] Run full backend test suite: `dotnet test` from `conscia/tests/` — all existing + new tests must pass

## Phase 5: Flutter — Packages & Service Layer

- [ ] [B] Add `sign_in_with_apple: ^6.1.4` and `google_sign_in: ^6.2.2` to `app/pubspec.yaml`, run `flutter pub get`
- [ ] [B] Add `google` and `apple` paths to `ApiConstants` in `app/lib/core/constants/api_constants.dart`
- [ ] Implement `signInWithGoogle()` in `app/lib/services/auth_service.dart` — call `GoogleSignIn().signIn()`, extract `idToken`, POST to `/auth/google`, return `AuthTokens`
- [ ] Implement `signInWithApple()` in `app/lib/services/auth_service.dart` — call `SignInWithApple.getAppleIDCredential()`, extract `identityToken` + `authorizationCode`, POST to `/auth/apple`, return `AuthTokens`
- [ ] Add `signInWithGoogle()` to `AuthNotifier` in `app/lib/providers/auth_provider.dart` — respect `useMockAuth` flag (mock path returns mock tokens, real path calls `AuthService.signInWithGoogle`)
- [ ] Add `signInWithApple()` to `AuthNotifier` in `app/lib/providers/auth_provider.dart` — same mock/real pattern

## Phase 6: Flutter — UI (Sign-In & Sign-Up Buttons)

- [ ] Add "— or —" divider and "Sign in with Google" button to `app/lib/screens/onboarding/sign_in_screen.dart` — placed between the Sign In button and the "Don't have an account?" link, calls `ref.read(authProvider.notifier).signInWithGoogle()`
- [ ] Add "Sign in with Apple" button to `sign_in_screen.dart` — shown only when `defaultTargetPlatform == TargetPlatform.iOS`, placed above the Google button
- [ ] [P] Add "— or —" divider, "Sign up with Google" button, and conditional "Sign up with Apple" button to `app/lib/screens/onboarding/sign_up_screen.dart` — same layout pattern as sign-in screen

## Phase 7: Documentation & Polish

- [ ] Create `app/PLATFORM_SETUP.md` — document iOS setup (Sign in with Apple capability, `GoogleService-Info.plist`, URL scheme) and Android setup (`google-services.json`, SHA-1 fingerprint registration)
- [ ] Run `flutter analyze` — resolve any new warnings or errors
- [ ] Manual verification checklist:
  - [ ] `dotnet test` passes (all backend tests green)
  - [ ] `flutter analyze` clean
  - [ ] Mock auth flow: register with email creates `User` + `UserIdentity(Email)`
  - [ ] Mock auth flow: Google sign-in creates/links user with `UserIdentity(Google)`
  - [ ] Mock auth flow: Apple sign-in creates/links user with `UserIdentity(Apple)`
  - [ ] Sign-in screen shows Google button on all platforms, Apple button only on iOS
  - [ ] Sign-up screen shows Google button on all platforms, Apple button only on iOS
  - [ ] Seed SQL inserts into `user_identities` correctly
