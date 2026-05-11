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
      ┌────────────┐ ┌───────────┐ ┌────────────┐
      │ API Lambda │ │ DB Access │ │  Outbox    │
      │ (non-VPC)  │ │  Lambda   │ │  Lambda    │
      │            │ │  (VPC)    │ │  (VPC)     │
      └─────┬──────┘ └─────┬─────┘ └─────┬──────┘
            │              │              │
     ┌──────┼──────┐       │         DynamoDB
     │      │      │       │         Streams
     ▼      ▼      ▼       ▼
 DynamoDB  S3   Bedrock  PostgreSQL
 SQS    Textract
```

**Locally**, the API runs as a standard ASP.NET 8 process backed by Docker-managed services (PostgreSQL, DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq). **In production**, AWS CDK deploys a split-Lambda architecture where the API Lambda stays outside the VPC for fast cold starts and the DB-access Lambda runs inside the VPC for RDS connectivity.

---

## Project Structure

```
conscia/
├── src/
│   ├── Conscia.Api/              # ASP.NET 8 Minimal API (Lambda entry point)
│   ├── Conscia.Domain/           # Entities, value objects (Money, RegretLevel)
│   ├── Conscia.Application/      # Interfaces, DTOs, services, validators
│   ├── Conscia.Infrastructure/   # DynamoDB repos, outbox processor, S3/SQS services
│   ├── Conscia.Infrastructure.Db/# EF Core 8 + PostgreSQL repos
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
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | Latest | PostgreSQL, DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq | [Download](https://www.docker.com/products/docker-desktop/) |
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

# 2. Start local services (PostgreSQL, DynamoDB Local, MinIO, ElasticMQ, Ollama, Seq)
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

---

## Docker Compose Services

| Service | Port(s) | Purpose |
|---------|---------|---------|
| PostgreSQL 16 | `5432` | Relational data (users, budgets, subscriptions) |
| DynamoDB Local | `8000` | Document store (transactions, AI interactions, alerts) |
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
| `ConnectionStrings__PostgreSQL` | `Host=localhost;Port=5432;Database=conscia;Username=conscia;Password=conscia_dev` | PostgreSQL connection string |
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

Production email/password auth uses Cognito email verification. Keep `Auth__UseMock=true` locally unless you have a Cognito user pool available; set it to `false` in deployed API environments so `/api/v1/auth/register` sends a confirmation code, `/api/v1/auth/confirm` verifies it, and login/refresh exchange Cognito tokens.

### Flutter App

Compile-time constants passed via `--dart-define`:

| Variable | Default | Description |
|----------|---------|-------------|
| `MOCK_AUTH` | `true` | Use mock authentication (bypasses Cognito, creates local JWT) |
| `API_BASE_URL` | `http://localhost:5248/api/v1` | Backend API base URL |
| `PUSH_NOTIFICATIONS_ENABLED` | `false` | Enables Firebase Cloud Messaging token registration after the user signs in |

```bash
# Run with defaults (local dev)
flutter run

# Run against a deployed API with real auth
flutter run --dart-define=MOCK_AUTH=false --dart-define=API_BASE_URL=https://api.getconscia.com/api/v1
```

### Device Push Notification Setup

Device push is scaffolded but intentionally disabled until Firebase credentials are ready. Today the app can request notification permission, read the Firebase Cloud Messaging token, and register it with `POST /api/v1/push/device-tokens`. The API stores tokens in DynamoDB table `PushDeviceTokens`; actual push delivery can be wired to Firebase Admin/FCM after credentials are available.

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
9. For actual push delivery, add Firebase Admin credentials on the backend side. Store the service account JSON in AWS Secrets Manager or GitHub Actions secrets for deployment, then wire a server-side FCM sender that reads active `PushDeviceTokens` and sends the digest/alert payload.

Cost note: Firebase Cloud Messaging itself has no per-message charge. This scaffold only adds tiny DynamoDB reads/writes for device-token registration. When we add server-side delivery, we can use the existing API/background jobs with Firebase Admin credentials, so there should be no new always-on infrastructure unless we later choose a dedicated worker.

## Social Authentication Setup

The app supports Sign in with Google and Sign in with Apple. The Flutter UI and service code are already in place. Follow these steps to wire up the credentials and backend endpoints.

> **Mock auth is on by default.** During local development, `MOCK_AUTH=true` bypasses real OAuth entirely. You only need to follow these steps when you're ready to test real sign-in flows. See [Disabling Mock Auth](#disabling-mock-auth) at the end of this section.

---

### Sign in with Google

#### Step 1 — Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a new project (e.g., "Conscia").
2. In **APIs & Services → Library**, search for "Google Identity" and enable the **Google Identity** API.

#### Step 2 — Create OAuth 2.0 Client IDs

You need one client ID per platform. Go to **APIs & Services → Credentials → Create Credentials → OAuth Client ID** for each:

**iOS client ID**
1. Application type: **iOS**
2. Bundle ID: `com.conscia.app` (must match your `ios/Runner.xcodeproj` bundle ID)
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
2. Package name: `com.conscia.app`
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

Open `app/lib/services/auth_service.dart` and pass the Web client ID to `GoogleSignIn`:

```dart
final googleUser = await GoogleSignIn(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
).signIn();
```

#### Step 5 — Implement the Backend Endpoint

Add `POST /api/v1/auth/google` to your .NET backend:

- **Request body:** `{ "idToken": "<Google ID token from device>" }`
- **What the backend does:**
  1. Verify the `idToken` using Google's tokeninfo endpoint or the `google-auth-library`
  2. Look up the user by Google subject ID (`sub` claim); create the account on first sign-in
  3. Issue your own JWT access and refresh tokens
- **Response:** `{ "accessToken": "...", "refreshToken": "...", "userId": "..." }`

---

### Sign in with Apple

> Apple sign-in is iOS-only. The button is conditionally rendered and will not appear on Android.

#### Step 1 — Enable the Capability in Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com/) → **Certificates, Identifiers & Profiles → Identifiers**.
2. Select your App ID (`com.conscia.app`) → enable **Sign in with Apple** → save.

#### Step 2 — Add the Capability in Xcode

1. Open `app/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities** tab → click `+` → add **Sign in with Apple**.
3. Xcode adds the entitlement automatically; no extra Flutter config is needed — the `sign_in_with_apple` package handles the rest.

#### Step 3 — Implement the Backend Endpoint

Add `POST /api/v1/auth/apple` to your .NET backend:

- **Request body:** `{ "identityToken": "<Apple identity token>", "authorizationCode": "<code>" }`
- **What the backend does:**
  1. Fetch Apple's public keys from `https://appleid.apple.com/auth/keys` and verify the `identityToken` JWT
  2. Look up the user by Apple subject ID; create the account on first sign-in
  3. Issue your own JWT access and refresh tokens
- **Response:** `{ "accessToken": "...", "refreshToken": "...", "userId": "..." }`

> **Important:** Apple only sends the user's name and email during the **first** sign-in. Store them immediately when you create the account — subsequent sign-ins will not include them.

---

### Disabling Mock Auth

`MOCK_AUTH=true` is the compile-time default (see `ApiConstants`). It lets you run the app locally without real credentials. To switch to real OAuth, pass the flag at run time:

```bash
cd app && flutter run --dart-define=MOCK_AUTH=false --dart-define=API_BASE_URL=https://your-api-host/api/v1/
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

All endpoints (except Auth and health) require a Bearer JWT in the `Authorization` header.

### System

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1` | No | API version info |
| `GET` | `/health` | No | Full health check (PostgreSQL, DynamoDB, AI) |
| `GET` | `/health/live` | No | Liveness probe |
| `GET` | `/health/ready` | No | Readiness probe |

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/auth/register` | No | Register with email/password and request email confirmation |
| `POST` | `/api/v1/auth/confirm` | No | Confirm registration with the email verification code |
| `POST` | `/api/v1/auth/resend-confirmation` | No | Resend the email verification code |
| `POST` | `/api/v1/auth/login` | No | Authenticate with email/password |
| `POST` | `/api/v1/auth/google` | No | Sign in with Google (ID token) |
| `POST` | `/api/v1/auth/apple` | No | Sign in with Apple (identity token) |

### Users

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/users/me` | Yes | Get current user profile |
| `PUT` | `/api/v1/users/me` | Yes | Update currency/locale preferences |

### Transactions

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/transactions` | Yes | Create a transaction |
| `GET` | `/api/v1/transactions` | Yes | List transactions (paginated, filterable by category) |
| `GET` | `/api/v1/transactions/{id}` | Yes | Get transaction detail |
| `PUT` | `/api/v1/transactions/{id}` | Yes | Update a transaction |
| `DELETE` | `/api/v1/transactions/{id}` | Yes | Delete a transaction |
| `POST` | `/api/v1/transactions/{id}/regret` | Yes | Submit regret-level feedback |

### Budgets

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/budgets` | Yes | Create a budget |
| `GET` | `/api/v1/budgets` | Yes | List all budgets with spend tracking |
| `GET` | `/api/v1/budgets/{id}` | Yes | Get budget detail |
| `PUT` | `/api/v1/budgets/{id}` | Yes | Update a budget |
| `DELETE` | `/api/v1/budgets/{id}` | Yes | Delete a budget |

### Subscriptions

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/subscriptions/status` | Yes | Get current subscription tier |
| `POST` | `/api/v1/subscriptions/verify/ios` | Yes | Verify iOS App Store receipt |
| `POST` | `/api/v1/subscriptions/verify/android` | Yes | Verify Android Play Store token |

### AI (Dual-Personality)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/ai/pre-purchase` | Yes | Get Impulse/Reason advice before buying |
| `POST` | `/api/v1/ai/reflection` | Yes | Get post-purchase reflection on a transaction |

### Receipts (Premium)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/receipts/scan` | Yes | Upload and scan a receipt image |
| `POST` | `/api/v1/receipts/{id}/confirm` | Yes | Confirm extracted data and create transaction |

### Alerts

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/alerts` | Yes | List in-app alerts for current user |

### Push Notifications

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/push/device-tokens` | Yes | Register or refresh the current device's Firebase Cloud Messaging token |

---

## Deployment

```bash
# Build Lambda packages
dotnet publish src/Conscia.Api -c Release -o publish/api
dotnet publish src/Conscia.Infrastructure.Db -c Release -o publish/db-access

# Deploy all CDK stacks
cd infra && cdk deploy --all
```

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **Split-Lambda pattern** | API Lambda runs non-VPC for fast cold starts and low cost. DB-access Lambda runs in VPC for RDS/PostgreSQL connectivity. |
| **No NAT Gateway** | Saves ~$32+/mo. DB credentials are passed via environment variables; non-VPC Lambda accesses DynamoDB/S3/SQS directly. |
| **No WAF** | Application-layer rate limiting (fixed-window, 60 req/min standard, 10 req/min AI) saves ~$6+/mo. |
| **DynamoDB for hot data** | PAY_PER_REQUEST billing, TTL-based caching replaces ElastiCache for session/interaction data. |
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
