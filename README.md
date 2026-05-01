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
| `POST` | `/api/v1/auth/register` | No | Register a new account |
| `POST` | `/api/v1/auth/login` | No | Authenticate and receive JWT tokens |

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

### Alerts

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/alerts` | Yes | List in-app alerts for current user |

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
