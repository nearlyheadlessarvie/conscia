# Conscia

**Your Financial Conscience** — A subscription-based AI financial assistant with a dual-AI personality system that helps users make better spending decisions.

<!-- Badges -->
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![.NET](https://img.shields.io/badge/.NET-8.0-purple)
![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B)

Conscia uses two AI personas — **Impulse** (the spender) and **Reason** (the saver) — to debate every purchase before you make it. Each transaction gets a devil-on-your-shoulder take, an angel's perspective, and a neutral summary so you can decide with full awareness.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (iOS/Android)                  │
│   Riverpod · GoRouter · Dio · Material 3 · Freezed          │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                     API Gateway (REST)                        │
│   Rate limiting · CORS · Cognito Auth                        │
└───────────────────────────┬──────────────────────────────────┘
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
      ┌────────────┐ ┌────────────┐
      │ API Lambda │ │  Outbox    │
      │ (non-VPC)  │ │  Lambda    │
      └─────┬──────┘ └─────┬──────┘
            │              │
     ┌──────┼──────┐  DynamoDB
     │      │      │  Streams
     ▼      ▼      ▼
 DynamoDB  S3   Bedrock
 SQS    Textract
```

**Locally**, the API runs as a standard ASP.NET 8 process backed by Docker-managed services (DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq). **In production**, AWS CDK deploys non-VPC Lambdas that talk directly to DynamoDB, S3, SQS, Bedrock, Textract, Cognito, and SES. The old RDS/DbAccess path has been removed to keep standby cost and networking complexity low.

---

## Project Structure

```
conscia/
├── src/
│   ├── Conscia.Api/              # ASP.NET 8 Minimal API (Lambda entry point)
│   ├── Conscia.Domain/           # Entities, value objects (Money, RegretLevel)
│   ├── Conscia.Application/      # Interfaces, DTOs, services, validators
│   ├── Conscia.Infrastructure/   # DynamoDB repos, S3/SQS services, auth integrations
│   ├── Conscia.OutboxProcessor/  # DynamoDB stream/outbox processing Lambda
│   └── Conscia.AI/               # AI services (Ollama + Bedrock), prompt templates
├── tests/
│   ├── Conscia.Tests.Unit/
│   └── Conscia.Tests.Integration/
├── tools/
│   ├── DynamoSetup/              # Local DynamoDB table creation
│   └── Seeder/                   # Test data seeding
├── infra/
│   ├── src/Conscia.Infra/        # AWS CDK stacks (C#)
│   └── tests/Conscia.Infra.Tests/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── core/                 # Theme, routing, network, constants
│   │   ├── models/               # Freezed data models
│   │   ├── providers/            # Riverpod state management
│   │   ├── services/             # Dio API services
│   │   ├── screens/              # UI screens
│   │   └── widgets/              # Reusable widgets
│   └── pubspec.yaml
├── docker-compose.yml            # Local development services
├── Conscia.sln
└── README.md
```

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) | 8.0.x | Backend API, CDK infrastructure | [Download](https://dotnet.microsoft.com/download/dotnet/8.0) |
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | Latest | DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq | [Download](https://www.docker.com/products/docker-desktop/) |
| [Flutter SDK](https://flutter.dev/docs/get-started/install) | 3.2+ | Mobile app (iOS/Android) | [Download](https://docs.flutter.dev/get-started/install) |
| [Node.js](https://nodejs.org/) | 20 LTS | Marketing site (Astro) + CDK CLI | [Download](https://nodejs.org/) |
| [Git](https://git-scm.com/) | Latest | Version control | [Download](https://git-scm.com/) |

### Optional (deployment only)

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| [AWS CDK CLI](https://docs.aws.amazon.com/cdk/v2/guide/cli.html) | 2.x | Deploy infrastructure | `npm install -g aws-cdk` |
| [AWS CLI](https://aws.amazon.com/cli/) | 2.x | AWS account access | [Download](https://aws.amazon.com/cli/) |

### Per-Component Minimums

If you're only working on one part of the project, you don't need everything:

| Working on... | You need | Disk space |
|---------------|----------|------------|
| Backend API only | .NET 8 SDK + Docker | ~5.5 GB |
| Flutter app only | Flutter SDK (+ Docker + .NET for local API) | ~2 GB (app only) / ~8 GB (with API) |
| Marketing site only | Node.js 20 | ~200 MB |
| CDK infra only | .NET 8 SDK + Node.js (for CDK CLI) | ~1.7 GB |
| Full stack | All of the above | ~8 GB |

### Verify Installation

```bash
dotnet --version        # should show 8.0.x
flutter --version       # should show 3.x
node --version          # should show v20.x
docker --version        # should show 24.x+
git --version           # should show 2.x+
```

---

## Local Development Setup

### Full Stack (API + Flutter + Marketing Site)

```bash
# 1. Clone the repo
git clone <repo-url> && cd conscia

# 2. Start local services (DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq)
docker compose up -d

# 3. Pull an LLM model for Ollama (first time only)
docker exec -it conscia-ollama-1 ollama pull llama3.2

# 4. Create DynamoDB tables
dotnet run --project tools/DynamoSetup

# 5. Seed test data
dotnet run --project tools/Seeder

# 6. Run the API
dotnet run --project src/Conscia.Api

# 7. Run the Flutter app (in a separate terminal)
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run

# 8. Run the marketing site (in a separate terminal)
cd web
npm install
npm run dev
```

### Backend Only

```bash
docker compose up -d
dotnet run --project tools/DynamoSetup
dotnet run --project tools/Seeder
dotnet run --project src/Conscia.Api
```

### Marketing Site Only

```bash
cd web
npm install
npm run dev
# Opens at http://localhost:4321
```

### Health Check

```bash
# Basic health
curl http://localhost:5000/health

# Liveness (is the process alive?)
curl http://localhost:5000/health/live

# Readiness (can it serve traffic? checks all dependencies)
curl http://localhost:5000/health/ready
```

Swagger UI is available at `http://localhost:5000/swagger` in development mode.

### Seeded Test Accounts (mock auth)

| Email | Password | Tier |
|-------|----------|------|
| `alice@example.com` | `password123` | Premium |
| `bob@example.com` | `password123` | Free |
| `carol@example.com` | `password123` | Premium |

## Lifetime Premium Entitlements

- Lifetime premium is granted by backend entitlement override records keyed by user ID, not by app-side allowlists.
- `/api/subscriptions/status?v=1` reports `source = lifetime` and `isLifetime = true` when a lifetime override is active.
- Admin authority stays server-side on `UserIdentity.Role`; the mobile app uses the normal signed-in session and the backend returns `403` for non-admin callers.
- Admin operators can resolve a target user with `GET /api/admin/users/by-email?v=1`, then grant or revoke the override with `/api/admin/entitlements/premium-lifetime/{userId}?v=1`.
- Reviewer or demo accounts can be provisioned with `POST /api/admin/reviewer-accounts?v=1` or through the in-app `Settings -> Admin entitlements` screen.
- The `story-demo` seed now includes `story-admin@example.com` as an admin-capable operator account and `story-demo@example.com` with a backend-owned lifetime premium override so the app screen can be exercised locally.

## App Store Server Notifications

- Apple App Store Server Notifications V2 post to `POST /api/subscriptions/apple/notifications?v=1`.
- Configure both App Store Connect server URLs:
  - Production Server URL: `https://<your-api-host>/api/subscriptions/apple/notifications?v=1`
  - Sandbox Server URL: `https://<your-api-host>/api/subscriptions/apple/notifications?v=1`
- Initial user linking still happens through the existing client receipt verification flow. The Apple notification handler only updates subscriptions whose `originalTransactionId` is already linked to a user.
- The backend stores lifecycle state for renewal, cancellation, expiration, refund, billing retry, grace period, and revocation so subscription status stays current when the app is closed.
- Google Play RTDN is intentionally deferred for now because Pub/Sub infrastructure is not provisioned in this repo yet.

---

## Docker Compose Services

| Service | Port(s) | Purpose |
|---------|---------|---------|
| DynamoDB Local | `8000` | App data, account/settings control plane, transactions, AI interactions, alerts |
| MinIO | `9000`, `9001` (console) | S3-compatible object storage (receipts) |
| ElasticMQ | `9324` | SQS-compatible message queue |
| Ollama | `11434` | Local LLM for AI dual-personality responses |
| Tesseract API | `8080` | Local OCR for receipt scanning |
| Seq | `5341`, `8081` (UI) | Structured log viewer (Serilog sink) |

---

## Environment Variables

### Backend (.NET API)

All configuration is managed via `appsettings.json` / `appsettings.Development.json`. In production, these map to environment variables or AWS Parameter Store.

| Variable | Default (Dev) | Description |
|----------|---------------|-------------|
| `ASPNETCORE_ENVIRONMENT` | `Development` | Switches between local and AWS service clients |
| `AWS__DynamoDB__ServiceURL` | `http://localhost:8000` | DynamoDB endpoint |
| `AWS__S3__ServiceURL` | `http://localhost:9000` | S3/MinIO endpoint |
| `AWS__S3__ForcePathStyle` | `true` | Required for MinIO |
| `AWS__S3__BucketName` | `conscia-receipts` | Receipt storage bucket |
| `AWS__SQS__ServiceURL` | `http://localhost:9324` | SQS/ElasticMQ endpoint |
| `Ollama__BaseUrl` | `http://localhost:11434` | Ollama LLM endpoint |
| `Ollama__Model` | `llama3.2` | Local LLM model name |
| `Tesseract__BaseUrl` | `http://localhost:8080` | Local OCR endpoint |
| `AWS__Bedrock__ModelId` | — | `anthropic.claude-3-haiku-20240307-v1:0` (prod only) |
| `AWS__Bedrock__MaxTokens` | `200` | Max tokens per AI call |
| `Auth__UseMock` | `true` | Use mock JWT auth locally |
| `Auth__MockSigningKey` | `super-secret-dev-key-...` | Signing key for mock JWTs |
| `Auth__Cognito__UserPoolId` | — | Cognito user pool (prod only) |
| `Auth__Cognito__ClientId` | — | Cognito client (prod only) |
| `Auth__AppJwtSigningKey` | — | 32+ char secret used to issue app JWTs for native Google/Apple social sign-in |
| `Auth__AppJwtIssuer` | `conscia-app` | Issuer for app JWTs |
| `Auth__AppJwtAudience` | `conscia-api` | Audience for app JWTs |
| `Auth__Google__ClientId` / `Auth__Google__ClientIds__0` | — | Allowed Google OAuth client ID(s) for native social sign-in |
| `Auth__Apple__ClientId` | — | Allowed Apple token audience, usually the iOS bundle id |

Production email/password auth uses Cognito email verification. Keep `Auth__UseMock=true` locally unless you have a Cognito user pool available; set it to `false` in deployed API environments so `/api/auth/register?v=1` sends a confirmation code, `/api/auth/confirm?v=1` verifies it, and login/refresh exchange Cognito tokens.

Native Google/Apple social auth is intentionally not Cognito Hosted UI. Flutter uses the platform SDKs, sends provider identity tokens to the API, and the API verifies those tokens, creates/links a `UserIdentity`, creates a suppressed Cognito shadow user on first social sign-in, then returns app-signed JWTs. Production API auth accepts both Cognito JWTs and these app JWTs.

### Flutter App

Compile-time constants passed via `--dart-define`:

| Variable | Default | Description |
|----------|---------|-------------|
| `MOCK_AUTH` | `true` | Use mock authentication (bypasses Cognito, creates local JWT) |
| `API_BASE_URL` | `http://localhost:5248/api/` | Backend API base URL |
| `PUSH_NOTIFICATIONS_ENABLED` | `false` | Enables Firebase Cloud Messaging token registration after the user signs in |
| `GOOGLE_SERVER_CLIENT_ID` | empty | Google web/server OAuth client ID used by native Google sign-in to request an ID token |

```bash
# Run with defaults (local dev)
flutter run

# Run against a deployed API with real auth
flutter run --dart-define=MOCK_AUTH=false --dart-define=API_BASE_URL=https://api.getconscia.com/api/ --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

The Flutter client automatically appends `?v=1` to API requests, so `API_BASE_URL` should stay on the stable `/api/` base path and should not include the version.

### Device Push Notification Setup

The app can request notification permission, read the Firebase Cloud Messaging token, and register it with `POST /api/push/device-tokens?v=1`. In production, the API and outbox worker now use Firebase Admin/FCM for real device delivery when the backend Firebase credentials are configured.

Keep `PUSH_NOTIFICATIONS_ENABLED=false` for normal local web/dev runs. Browser/web push is not wired yet; the current scaffold is for Android/iOS device token registration.

When Firebase is ready:

1. Create a Firebase project in the Firebase Console.
2. Add Android and iOS apps using the real production package/bundle identifiers. The current Android package id is `com.example.conscia_app`; update it before production if needed.
3. Download and place Firebase config files locally:
   ```text
   app/android/app/google-services.json
   app/ios/Runner/GoogleService-Info.plist
   ```
   These files are gitignored and should not be committed.
4. Configure native Firebase using FlutterFire:
   ```bash
   cd app
   dart pub global activate flutterfire_cli
   flutterfire configure
   flutter pub get
   ```
   This may generate `app/lib/firebase_options.dart`. Treat it as environment-specific unless we decide to standardize a committed non-secret Firebase client config.
5. For iOS production push, configure APNs in Firebase:
   - Apple Developer account → create an APNs Auth Key.
   - Firebase Console → Project Settings → Cloud Messaging → upload the APNs key.
6. Run local Dynamo setup again so the token table exists:
   ```bash
   dotnet run --project tools/DynamoSetup
   ```
7. Enable push registration at runtime on an Android/iOS device or emulator:
   ```bash
   cd app
   flutter run --dart-define=PUSH_NOTIFICATIONS_ENABLED=true
   ```
8. For CI/builds, provide the Firebase config files as GitHub secrets and write them into the paths above during the mobile build job. Do not store them in source.
9. For actual push delivery, add Firebase Admin credentials on the backend side and set:
   ```text
   Firebase__AdminServiceAccountJson
   Firebase__ProjectId
   ```
   The deployed API/outbox processes will read active `PushDeviceTokens` and send the alert payload through FCM.

Cost note: Firebase Cloud Messaging itself has no per-message charge. This scaffold only adds tiny DynamoDB reads/writes for device-token registration. When we add server-side delivery, we can use the existing API/background jobs with Firebase Admin credentials, so there should be no new always-on infrastructure unless we later choose a dedicated worker.

### Shared Conscia Setup

Shared Conscia uses relational Family Space tables for membership/invites and the existing record stores for explicitly shared transactions, budgets, and recurring schedules.

Production requirements:
- Run the Family Space EF migrations before enabling the feature.
- Keep Family Space creation Premium-only; invited contributors/viewers can participate without separate subscriptions.
- Deploy the existing Outbox Lambda stack so family invite events can create in-app alerts, email invites, and device notifications.
- Configure SES and Firebase Admin credentials before production so invite emails and push delivery do not fail closed.
- Set DynamoDB read/write budget alerts after release because family import and family AI context add extra record lookups.

Privacy model:
- Personal records never become Family records automatically.
- Users explicitly import/share selected records.
- Hidden salary is represented as contribution records or recurring contribution schedules, not exact salary disclosure.
- No settlement or who-owes-whom workflow is part of MVP.
- Invite emails now deep-link into the app through `https://getconscia.com/open/family-invite?inviteId=<guid>`, which the mobile app resolves to the Family Invite screen.

## Social Authentication Setup

The app supports native Sign in with Google and Sign in with Apple. This is **not** Cognito Hosted UI: the Flutter buttons use platform SDKs, then the API verifies the returned provider token and returns app JWTs. This keeps the iOS/Android auth experience native while still using Cognito for email/password auth and keeping a Cognito user record for social accounts.

> **Mock auth is on by default.** During local development, `MOCK_AUTH=true` bypasses real OAuth entirely. You only need to follow these steps when you're ready to test real sign-in flows. See [Disabling Mock Auth](#disabling-mock-auth) at the end of this section.

### Backend Requirements

Set these in production API configuration or AWS/GitHub deployment secrets:

```text
Auth__UseMock=false
Auth__Cognito__UserPoolId=<your Cognito user pool id>
Auth__Cognito__ClientId=<your Cognito app client id>
Auth__AppJwtSigningKey=<random 32+ char secret>
Auth__AppJwtIssuer=conscia-app
Auth__AppJwtAudience=conscia-api
Auth__Google__ClientId=<Google web/server OAuth client id>
Auth__Apple__ClientId=<iOS bundle id, for example com.getconscia.app.ai>
```

If you need multiple Google audiences, use array-style environment variables:

```text
Auth__Google__ClientIds__0=<web client id>
Auth__Google__ClientIds__1=<ios client id>
Auth__Google__ClientIds__2=<android client id>
```

The social endpoints are already present:

- `POST /api/auth/google?v=1` with `{ "idToken": "<Google ID token>" }`
- `POST /api/auth/apple?v=1` with `{ "identityToken": "<Apple identity token>", "authorizationCode": "<code>" }`

On first social sign-in, the API creates or links the local `User`, stores `UserIdentity(provider, providerSub)`, creates a suppressed Cognito shadow user for operational consistency, and returns `{ accessToken, refreshToken, userId }`. New social users then enter onboarding because `HasCompletedOnboarding` defaults to `false`.

---

### Sign in with Google

#### Step 1 — Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a new project (e.g., "Conscia").
2. In **APIs & Services → Library**, search for "Google Identity" and enable the **Google Identity** API.

#### Step 2 — Create OAuth 2.0 Client IDs

You need one client ID per platform. Go to **APIs & Services → Credentials → Create Credentials → OAuth Client ID** for each:

**iOS client ID**
1. Application type: **iOS**
2. Bundle ID: `com.getconscia.app.ai` (must match your `ios/Runner.xcodeproj` bundle ID)
3. Download `GoogleService-Info.plist` → place it at `app/ios/Runner/GoogleService-Info.plist`
4. Open `app/ios/Runner/Info.plist` and add a URL scheme so the app can receive the OAuth redirect:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```
   Replace `YOUR_IOS_CLIENT_ID` with the value from `GoogleService-Info.plist` → `REVERSED_CLIENT_ID`.

**Android client ID**
1. Application type: **Android**
2. Package name: `com.getconscia.app.ai`
3. SHA-1 fingerprint — run this to get your debug key fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
   ```
   Copy the `SHA1:` line from the output.
4. Download `google-services.json` → place it at `app/android/app/google-services.json`
5. In `app/android/build.gradle` add the Google Services plugin to the `buildscript` classpath:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.0'
   ```
6. In `app/android/app/build.gradle` apply the plugin at the top:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

**Web client ID** (needed for `serverClientId` — required even if you don't have a web app)
1. Application type: **Web application**
2. No redirect URI is needed for the mobile-only flow; this client ID is used to request an `idToken` on device.

#### Step 3 — Configure the OAuth Consent Screen

1. In **APIs & Services → OAuth consent screen**, fill in your app name, support email, and developer contact.
2. Add any test user emails during development so they can sign in before the app is verified.
3. Scopes: `email` and `profile` are sufficient for Conscia.

#### Step 4 — Pass the Web Client ID to the Flutter App

Pass the Web client ID at run/build time so `GoogleSignIn` can request an ID token for the backend:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

#### Step 5 — Configure Backend Audience

Set the Google web/server client ID as `Auth__Google__ClientId` (or include it in `Auth__Google__ClientIds__0`). The API validates Google ID tokens against Google's JWKS, issuer, and this configured audience before creating/linking the user.

---

### Sign in with Apple

> Apple sign-in is iOS-only. The button is conditionally rendered and will not appear on Android.

#### Step 1 — Enable the Capability in Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com/) → **Certificates, Identifiers & Profiles → Identifiers**.
2. Select your App ID (`com.getconscia.app.ai`) -> enable **Sign in with Apple** -> save.

#### Step 2 — Add the Capability in Xcode

1. Open `app/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities** tab → click `+` → add **Sign in with Apple**.
3. Xcode adds the entitlement automatically; no extra Flutter config is needed — the `sign_in_with_apple` package handles the rest.

#### Step 3 — Configure Backend Audience

Set `Auth__Apple__ClientId` to the audience Apple places in the identity token. For the native iOS app this is usually the bundle id, such as `com.getconscia.app.ai`. The API validates Apple identity tokens against Apple's JWKS, issuer, and this configured audience before creating/linking the user.

> **Important:** Apple only sends the user's name and email during the **first** sign-in. Store them immediately when you create the account — subsequent sign-ins will not include them.

---

## Passkeys For Conscia Accounts

Conscia-native email/password accounts can now register and use passkeys through Cognito WebAuthn. This replaces the old faux local-biometric toggle.

How it fits with the rest of auth:

- Cognito-native lane: email/password plus passkeys
- Native social lane: Google and Apple stay native and continue to use the current backend token-verification flow

Important rollout notes:

- Passkeys require real-device testing. Emulators and simulators are not enough for release confidence.
- iOS and Android rely on associated-domain metadata served from `https://getconscia.com/.well-known/...`.
- The web release generates those association files from CI variables:
  - `APPLE_TEAM_ID`
  - `IOS_BUNDLE_ID`
  - `GOOGLE_PLAY_PACKAGE_NAME`
  - `ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS`

Once those are configured and `release-web.yml` has published the association files, the app can:

- show `Sign in with Passkey` on the sign-in screen when the device supports it
- show `Set Up Passkey` in Settings for Cognito-authenticated users

---

### Disabling Mock Auth

`MOCK_AUTH=true` is the compile-time default (see `ApiConstants`). It lets you run the app locally without real credentials. To switch to real OAuth, pass the flag at run time:

```bash
cd app && flutter run --dart-define=MOCK_AUTH=false --dart-define=API_BASE_URL=https://your-api-host/api/
```

---

## Running Tests

```bash
# Backend unit tests
dotnet test tests/Conscia.Tests.Unit

# Backend integration tests (requires docker-compose up)
dotnet test tests/Conscia.Tests.Integration

# CDK infrastructure tests
dotnet test infra/tests/Conscia.Infra.Tests

# Flutter tests
cd app && flutter test
```

---

## API Endpoints

All `/api/...` endpoints require API version `v=1` during this release. Query-string versioning is the canonical contract, so requests should use `?v=1`. The API also accepts `X-Api-Version: 1` as a secondary input for non-Flutter clients.

The Flutter app automatically appends `?v=1` and sends `X-Conscia-App-Version`, so most app code should treat `API_BASE_URL` as `.../api/` and avoid hand-building versioned URLs.

## Release Automation

Component releases are prepared with release PRs rather than cut directly from every merge. We use Conventional Commits to drive semver for each deployable unit:

- `app/vX.Y.Z`
- `api/vX.Y.Z`
- `infra/vX.Y.Z`
- `web/vX.Y.Z`

When an app release PR is prepared, the repo also syncs the API compatibility window so the backend continues to support the current app build and the previous one. See [release-matrix.md](./release-matrix.md) for the live contract and support window.

The app release workflow now builds signed mobile artifacts and targets non-production store channels by default:

- Android uploads to Google Play `internal`
- iOS uploads to TestFlight
- both artifacts are also uploaded to GitHub Actions as release artifacts

Promotion to production tracks remains manual.

Production runtime hardening now also fails closed in these cases:

- subscription verification is rejected if Apple/Google validation settings are missing
- receipt OCR returns `503` if no real OCR provider is configured
- production startup fails if required auth, invite email, push, or app-compatibility settings are missing

All endpoints (except Auth and health) require a Bearer JWT in the `Authorization` header.

### System

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api?v=1` | No | API version info |
| `GET` | `/health` | No | Full health check (PostgreSQL, DynamoDB, AI) |
| `GET` | `/health/live` | No | Liveness probe |
| `GET` | `/health/ready` | No | Readiness probe |

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/auth/register?v=1` | No | Register with email/password and request email confirmation |
| `POST` | `/api/auth/confirm?v=1` | No | Confirm registration with the email verification code |
| `POST` | `/api/auth/resend-confirmation?v=1` | No | Resend the email verification code |
| `POST` | `/api/auth/login?v=1` | No | Authenticate with email/password |
| `POST` | `/api/auth/google?v=1` | No | Sign in with Google (ID token) |
| `POST` | `/api/auth/apple?v=1` | No | Sign in with Apple (identity token) |

### Users

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/users/me?v=1` | Yes | Get current user profile |
| `PUT` | `/api/users/me?v=1` | Yes | Update currency/locale preferences |

### Transactions

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/transactions?v=1` | Yes | Create a transaction |
| `GET` | `/api/transactions?v=1` | Yes | List transactions (paginated, filterable by category) |
| `GET` | `/api/transactions/{id}?v=1` | Yes | Get transaction detail |
| `PUT` | `/api/transactions/{id}?v=1` | Yes | Update a transaction |
| `DELETE` | `/api/transactions/{id}?v=1` | Yes | Delete a transaction |
| `POST` | `/api/transactions/{id}/regret?v=1` | Yes | Submit regret-level feedback |

### Budgets

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/budgets?v=1` | Yes | Create a budget |
| `GET` | `/api/budgets?v=1` | Yes | List all budgets with spend tracking |
| `GET` | `/api/budgets/{id}?v=1` | Yes | Get budget detail |
| `PUT` | `/api/budgets/{id}?v=1` | Yes | Update a budget |
| `DELETE` | `/api/budgets/{id}?v=1` | Yes | Delete a budget |

### Subscriptions

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/subscriptions/status?v=1` | Yes | Get current subscription tier |
| `POST` | `/api/subscriptions/verify/ios?v=1` | Yes | Verify iOS App Store receipt |
| `POST` | `/api/subscriptions/verify/android?v=1` | Yes | Verify Android Play Store token |

### AI (Dual-Personality)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/ai/pre-purchase?v=1` | Yes | Get Impulse/Reason advice before buying |
| `POST` | `/api/ai/reflection?v=1` | Yes | Get post-purchase reflection on a transaction |

### Receipts (Premium)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/receipts/scan?v=1` | Yes | Upload and scan a receipt image |
| `POST` | `/api/receipts/{id}/confirm?v=1` | Yes | Confirm extracted data and create transaction |

### Alerts

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/alerts?v=1` | Yes | List in-app alerts for current user |

### Push Notifications

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/push/device-tokens?v=1` | Yes | Register or refresh the current device's Firebase Cloud Messaging token |

---

## Deployment

```bash
# Build Lambda packages
dotnet publish src/Conscia.Api -c Release -r linux-arm64 --self-contained -o publish/api
dotnet publish src/Conscia.OutboxProcessor -c Release -r linux-arm64 --self-contained -o publish/outbox
dotnet publish src/Conscia.PatternAggregator -c Release -r linux-arm64 --self-contained -o publish/pattern-aggregator

# Deploy all CDK stacks
cd infra && cdk deploy --all
```

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **Split-Lambda pattern** | API Lambda runs non-VPC for fast cold starts and low cost. Background/event work is handled by dedicated Lambdas such as the outbox processor. |
| **No NAT Gateway** | Saves ~$32+/mo. Non-VPC Lambdas access DynamoDB/S3/SQS/SES/Cognito directly. |
| **No WAF** | Application-layer rate limiting (fixed-window, 60 req/min standard, 10 req/min AI) saves ~$6+/mo. |
| **DynamoDB for hot data** | PAY_PER_REQUEST billing, DynamoDB streams for outbox processing, and no always-on relational standby costs. |
| **Outbox pattern** | DynamoDB `TransactWriteItems` for atomic writes. DynamoDB Streams trigger eventual consistency processing. |
| **Dual-AI personality** | "Impulse" (high temperature) and "Reason" (low temperature) run in parallel. A neutral summary reconciles both perspectives. |
| **Ollama locally, Bedrock in prod** | Free local development with open-source models. Claude 3 Haiku in production for quality and speed. |
| **Receipt scanning gated to Premium** | Textract/OCR costs are controlled by limiting the feature to paid subscribers. |
| **Mock auth in development** | Seeded JWT auth avoids Cognito dependency locally while matching the same Bearer token flow. |

---

## Cost Profile

| Phase | Monthly Estimate |
|-------|-----------------|
| **Standby** (0 users) | ~$3–5 |
| **Bootstrap** (<1K MAU) | ~$10–25 |
| **Growth** (1K–10K MAU) | ~$50–150 |

Key cost drivers: RDS `db.t4g.micro`, Bedrock per-token billing, DynamoDB on-demand, S3 storage.

---

## Observability

- **Structured logging** via Serilog with correlation IDs. Seq UI at `http://localhost:8081` in development; CloudWatch in production.
- **Distributed tracing** via OpenTelemetry with ASP.NET Core and HttpClient instrumentation. Console exporter locally, OTLP in production.
- **Health checks** at `/health`, `/health/live`, and `/health/ready` covering PostgreSQL, DynamoDB, and AI service availability.
- **Custom metrics** via `Conscia.Api` meter — tracks transactions created and regret feedback submitted.

---

## License

MIT
