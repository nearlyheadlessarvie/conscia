# Conscia MVP — Task Breakdown (v4)

Based on [conscia-implementation-plan.md v4](../../../conscia-implementation-plan.md).

**Estimated total: ~85 tasks across 10 phases.**

Legend:
- `[P]` — Can run in parallel with other `[P]` tasks in the same group
- `[B]` — Blocking; must complete before dependent tasks

---

## Phase 1: Project Scaffolding & Local Dev Environment

_Goal: Bootable solution with docker-compose, all local services running, empty API responding on localhost._

- [ ] [B] Create .NET 8 solution file `Conscia.sln` with project structure: `src/Conscia.Api`, `src/Conscia.Domain`, `src/Conscia.Application`, `src/Conscia.Infrastructure`, `src/Conscia.Infrastructure.Db`, `src/Conscia.AI`, `tests/Conscia.Tests.Unit`, `tests/Conscia.Tests.Integration`
- [ ] [B] Add NuGet packages to each project: AWSSDK.DynamoDBv2, AWSSDK.BedrockRuntime, AWSSDK.Textract, Amazon.Lambda.AspNetCoreServer.Hosting, FluentValidation, Npgsql.EntityFrameworkCore.PostgreSQL, NodaMoney, Serilog + sinks, Testcontainers
- [ ] [B] Create `docker-compose.yml` with all 7 services: postgres:16-alpine (5432), dynamodb-local (8000), minio (9000/9001), elasticmq (9324), ollama (11434), tesseract-api (8080), seq (5341/8081)
- [ ] [B] Create `docker-compose.ci.yml` with pinned image versions for GitHub Actions
- [ ] [P] Create `tools/DynamoSetup` console app — creates all 6 DynamoDB tables (Transactions, AIInteractions, BehaviorProfiles, SessionCache, OutboxEvents, InAppAlerts) with PK/SK/GSIs/TTL from plan
- [ ] [P] Create `appsettings.Development.json` with local service URLs (localhost:8000 for DynamoDB, localhost:9000 for S3, localhost:9324 for SQS, localhost:5341 for Seq, etc.)
- [ ] [B] Wire up `Program.cs` with `IHostEnvironment` check — DI registration switches between AWS and local implementations for IAmazonDynamoDB, IAmazonS3, IAmazonSQS, ILogger (Serilog CloudWatch vs Seq sink)
- [ ] [B] Verify: `docker-compose up -d` boots all services, `dotnet run --project src/Conscia.Api` starts on https://localhost:5001, health check endpoint returns 200
- [ ] Create `.github/workflows/ci.yml` — build + test pipeline using docker-compose.ci.yml, `dotnet test`, no AWS credentials needed

---

## Phase 2: Domain Layer — Entities, Value Objects, Enums

_Goal: Pure C# domain model with no infrastructure dependencies. All domain tests pass._

- [ ] [B] Write tests for `Money` value object: construction, equality, currency validation (ISO 4217), `ToString` with locale formatting, prevent silent conversion between currencies
- [ ] [B] Implement `Money` value object in `Conscia.Domain`: Amount (decimal), CurrencyCode (string), ExchangeRateToBase (decimal?)
- [ ] [P] Write tests for all domain entities: User, UserSubscription, Transaction (with RegretLevel), Budget, BehaviorProfile, AIInteraction, Receipt, OutboxEvent — test required fields, validation rules, enum constraints
- [ ] [P] Implement domain entities in `Conscia.Domain`:
  - `User` (Id, Email, CognitoSub, PreferredCurrency, Locale, CreatedAt)
  - `UserSubscription` (UserId, Tier enum [Free/Premium], Platform enum [iOS/Android], ExpiresAt, OriginalTransactionId)
  - `Transaction` (Id, UserId, Type enum [Income/Expense], Money, Category, Merchant, Date, Location, ExchangeRateToBase, RegretLevel nullable enum [WorthIt/NotSure/Regret])
  - `Budget` (Id, UserId, Category, MonthlyLimit, CurrencyCode)
  - `BehaviorProfile` (UserId, PreventedPurchases, Overrides, Regrets)
  - `AIInteraction` (Id, TransactionId, DevilMsg, AngelMsg, NeutralMsg, CreatedAt)
  - `Receipt` (Id, TransactionId, S3Key, ExtractedData, OcrConfidence, NeedsReview, Status enum)
  - `OutboxEvent` (Id, AggregateId, EventType, Payload, CreatedAt, ProcessedAt)
- [ ] Write tests for `ITriggerEvaluator` interface contract and `BudgetWarningEvaluator` — 80% threshold logic, returns alert when triggered, returns nothing when below threshold
- [ ] Implement `ITriggerEvaluator` interface in `Conscia.Application` and `BudgetWarningEvaluator` implementation
- [ ] Define DTOs in `Conscia.Application`: CreateTransactionDto, UpdateTransactionDto, CreateBudgetDto, UpdateBudgetDto, RegretFeedbackDto, PrePurchaseRequestDto, ReceiptScanResultDto, UserProfileUpdateDto

---

## Phase 3: Infrastructure — Database Layer (EF Core + DynamoDB)

_Goal: RDS schema migrated, DynamoDB tables created, repositories working against local Docker services._

- [ ] [B] Create EF Core `ConsciaDbContext` in `Conscia.Infrastructure` with entity configurations for: User, UserSubscription, Budget, Receipt
- [ ] [B] Create initial EF Core migration — `InitialCreate` with all RDS tables, indexes, foreign keys
- [ ] [B] Verify: `dotnet ef database update` runs clean against local PostgreSQL
- [ ] [P] Write tests for `UserRepository` (EF Core): CRUD operations, find by CognitoSub, find by email
- [ ] [P] Implement `UserRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `BudgetRepository` (EF Core): CRUD, list by UserId
- [ ] [P] Implement `BudgetRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `ReceiptRepository` (EF Core): CRUD, find by TransactionId, status updates
- [ ] [P] Implement `ReceiptRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `TransactionRepository` (DynamoDB): put, get, query by UserId with date range, paginated query, delete, update RegretLevel
- [ ] [P] Implement `TransactionRepository` in `Conscia.Infrastructure` — DynamoDB TransactWriteItems (Transaction + OutboxEvent atomic write)
- [ ] [P] Write tests for `OutboxEventRepository` (DynamoDB): write, query pending (GSI1: ProcessedAt=null), mark processed
- [ ] [P] Implement `OutboxEventRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `AIInteractionRepository` (DynamoDB): write, query by TransactionId, query by UserId+Date (GSI1)
- [ ] [P] Implement `AIInteractionRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `BehaviorProfileRepository` (DynamoDB): get/upsert single item per user
- [ ] [P] Implement `BehaviorProfileRepository` in `Conscia.Infrastructure`
- [ ] [P] Write tests for `InAppAlertRepository` (DynamoDB): write alert with TTL, query by UserId
- [ ] [P] Implement `InAppAlertRepository` in `Conscia.Infrastructure`
- [ ] Write tests for `SessionCacheRepository` (DynamoDB): write with 5-min TTL, read, TTL expiry
- [ ] Implement `SessionCacheRepository` in `Conscia.Infrastructure`
- [ ] Create seed scripts: `seed-rds.sql` (3 users, 5 budgets, 10 receipts), `seed-dynamo.sh` (50 transactions, 20 AI interactions, profiles, outbox events, alerts), `seed-minio.sh` (10 receipt images)
- [ ] Create `tools/Seeder` console app that runs all seed scripts

---

## Phase 4: Infrastructure — AWS SDK Wrappers (S3, SQS, Cognito)

_Goal: All AWS service interactions abstracted behind interfaces, local implementations working._

- [ ] [P] Write tests for `IS3StorageService`: generate presigned upload URL, generate presigned download URL, verify file exists
- [ ] [P] Implement `S3StorageService` (AWS) and local implementation using MinIO — same SDK, different ServiceURL
- [ ] [P] Write tests for `ISqsQueueService`: publish message, receive message, delete message, DLQ handling
- [ ] [P] Implement `SqsQueueService` (AWS) and local implementation using ElasticMQ
- [ ] [B] Write tests for `IAuthService`: register, login (return JWT), validate token, extract claims (userId, tier)
- [ ] [B] Implement `CognitoAuthService` (AWS SDK) and `MockAuthService` (local — issues JWTs with symmetric key, configurable users/tiers)
- [ ] [B] Implement auth middleware in `Conscia.Api`: extract JWT from Authorization header, validate, set HttpContext.User with claims (userId, tier, email)
- [ ] Write tests for subscription tier middleware: premium endpoints (receipts/scan, receipts/confirm) reject free-tier users with 403, allow premium users

---

## Phase 5: Backend Services — Core Business Logic

_Goal: All service interfaces implemented, FluentValidation wired, outbox pattern working end-to-end._

- [ ] [B] Write tests for `ITransactionService`: create (atomic DynamoDB write with OutboxEvent), get by id, list paginated with filters, update, delete (reverse OutboxEvent), update RegretLevel
- [ ] [B] Implement `TransactionService` in `Conscia.Application`
- [ ] [B] Write tests for `IBudgetService`: create, list by user, compute current-month usage, update (limit/category), delete
- [ ] [B] Implement `BudgetService` in `Conscia.Application`
- [ ] [P] Write tests for `IUserService`: get profile, update profile (currency, locale), get subscription status
- [ ] [P] Implement `UserService` in `Conscia.Application`
- [ ] [P] Write tests for `ISubscriptionService`: verify iOS receipt, verify Android token, get current status, check tier entitlement
- [ ] [P] Implement `SubscriptionService` in `Conscia.Application` — writes to UserSubscription, caches tier in SessionCache (DynamoDB, 5-min TTL)
- [ ] [B] Write integration test for outbox pattern end-to-end: create Transaction → OutboxEvent written atomically → simulated Streams Lambda reads outbox → alert evaluated by BudgetWarningEvaluator using computed budget usage
- [ ] [B] Implement outbox processor Lambda function in `Conscia.Infrastructure`: reads DynamoDB Streams events, evaluates ITriggerEvaluator against computed budget usage, writes InAppAlert if triggered, marks OutboxEvent processed
- [ ] [P] Write tests for `IRegretPromptService`: query transactions 24-48h old with null RegretLevel for a user, return prompt candidates
- [ ] [P] Implement `IRegretPromptService` — simple DynamoDB query, no scheduler
- [ ] Write FluentValidation validators for all DTOs: CreateTransactionValidator, UpdateTransactionValidator, CreateBudgetValidator, UpdateBudgetValidator, PrePurchaseRequestValidator, UserProfileUpdateValidator
- [ ] Write tests for validators — invalid amounts, missing required fields, invalid currency codes, boundary conditions

---

## Phase 6: AI Engine — Dual-Personality System

_Goal: Context builder, prompt templates, 2-call pattern, receipt parsing all working against local Ollama._

- [ ] [B] Write tests for `ContextBuilder`: given a userId, builds context object with budget %, category trends, spending frequency, location, regret history, preferred currency
- [ ] [B] Implement `ContextBuilder` in `Conscia.AI` — queries DynamoDB (TransactionRepository, BehaviorProfileRepository) + RDS (BudgetRepository via VPC Lambda interface)
- [ ] [B] Write tests for `IAIService` 2-call pattern: given context, returns Devil + Angel + Neutral messages. Test parallel execution, timeout handling, fallback on single call failure
- [ ] [B] Implement `BedrockAIService` in `Conscia.AI`: Call 1 (Devil, temp 0.85-0.95, ~100 tokens), Call 2 (Angel+Neutral, temp 0.4-0.55, ~160 tokens), parallel via `Task.WhenAll`, parse structured responses
- [ ] [B] Implement `OllamaAIService` in `Conscia.AI`: same interface, HTTP client to localhost:11434, identical prompts, different model name
- [ ] [P] Write tests for prompt templates: Devil prompt uses emotional framing, Angel prompt uses data-driven framing, Neutral prompt asks reflective questions. Context variables injected correctly (budget %, currency, merchant, amount)
- [ ] [P] Implement prompt templates in `Conscia.AI` — System prompt + Context injection + Tone rules per persona
- [ ] [B] Write tests for `IOcrService` receipt parsing: given raw OCR text, Bedrock extracts structured JSON (merchant, total, date, currency, line items), returns OcrConfidence score
- [ ] [B] Implement `TextractOcrService` (AWS) and `TesseractOcrService` (local) — both return raw text
- [ ] [B] Implement receipt Bedrock parsing: raw text → structured JSON via Claude 3 Haiku prompt (~200 input + OCR text, ~80 output tokens)
- [ ] Write integration test: upload image to MinIO → Tesseract OCR → Ollama parsing → structured receipt data returned with confidence score

---

## Phase 7: API Endpoints — Minimal API Wiring

_Goal: All 19 endpoints responding correctly, auth middleware protecting routes, premium gate on receipt endpoints._

- [ ] [B] Write integration tests for auth endpoints: `POST /api/v1/auth/register` (creates user, returns token), `POST /api/v1/auth/login` (returns JWT)
- [ ] [B] Implement auth endpoints in `Conscia.Api` using Minimal APIs, wired to IAuthService
- [ ] [P] Write integration tests for transaction endpoints: GET (paginated, filtered), POST (creates + outbox), PUT (updates), DELETE (deletes + reverse outbox)
- [ ] [P] Implement transaction endpoints: GET/POST/PUT/DELETE `/api/v1/transactions`, POST `/api/v1/transactions/{id}/reflect`, POST `/api/v1/transactions/{id}/regret`
- [ ] [P] Write integration tests for budget endpoints: GET (list), POST (create), PUT (update), DELETE
- [ ] [P] Implement budget endpoints: GET/POST/PUT/DELETE `/api/v1/budgets`
- [ ] [P] Write integration tests for AI endpoints: `POST /api/v1/assistant/pre-purchase` returns Devil+Angel+Neutral, `POST /api/v1/transactions/{id}/reflect` returns reflection
- [ ] [P] Implement AI endpoints wired to IAIService + ContextBuilder
- [ ] [B] Write integration tests for receipt endpoints (premium gate): free-tier user gets 403, premium user succeeds. `POST /api/v1/receipts/scan` returns presigned URL + triggers OCR. `POST /api/v1/receipts/{id}/confirm` saves corrected data.
- [ ] [B] Implement receipt endpoints with subscription middleware gate
- [ ] [P] Write integration tests for user/subscription endpoints: `PUT /api/v1/users/me`, `POST /api/v1/subscriptions/verify`, `GET /api/v1/subscriptions/status`
- [ ] [P] Implement user + subscription endpoints
- [ ] [P] Write integration tests for webhook endpoints: `POST /api/v1/webhooks/appstore`, `POST /api/v1/webhooks/playstore` — verify signature, update UserSubscription
- [ ] [P] Implement webhook endpoints for App Store Server Notifications V2 + Google Play RTDN
- [ ] Wire global error handling middleware, request logging (Serilog), CORS configuration

---

## Phase 8: Flutter Frontend

_Goal: All 11 screens built, connected to local API, navigation working, multi-currency UX functional._

### 8a: Flutter Project Setup
- [ ] [B] Create Flutter project in `app/` directory, add packages: flutter_riverpod, go_router, dio, freezed, json_serializable, flutter_secure_storage, in_app_purchase, intl
- [ ] [B] Set up GoRouter with all routes: `/onboarding`, `/`, `/transactions`, `/transactions/:id`, `/transactions/add`, `/transactions/:id/edit`, `/scan`, `/receipts/:id/review`, `/assistant`, `/budgets`, `/settings`
- [ ] [B] Create Dio HTTP client with interceptors: base URL (localhost:5001 for dev), auth token injection from flutter_secure_storage, error handling, refresh token logic
- [ ] [B] Generate freezed models for all API response/request types: Transaction, Budget, User, AIResponse (Devil+Angel+Neutral), Receipt, Subscription, InAppAlert, RegretPromptCandidate

### 8b: Auth + Onboarding
- [ ] Write widget tests for Onboarding screen: welcome slides, sign-up form (email, password), sign-in form, currency picker, locale picker
- [ ] Implement Onboarding screen + Riverpod auth providers (register, login, store token in secure storage, navigate to Dashboard)

### 8c: Dashboard
- [ ] Write widget tests for Dashboard: budget summary cards, recent transactions list, quick-add FAB, regret prompt dismissible cards (24-48h old), budget warning cards
- [ ] Implement Dashboard screen + Riverpod providers: fetch budgets, recent transactions, regret prompt candidates (transactions 24-48h old with null RegretLevel), in-app alerts. Optimistic update on regret feedback tap.

### 8d: Transactions
- [ ] [P] Write widget tests for Transaction List: filterable, pull-to-refresh, infinite scroll pagination
- [ ] [P] Implement Transaction List screen + Riverpod providers
- [ ] [P] Write widget tests for Transaction Detail: amount with currency, category, merchant, date, AI reflection modal trigger
- [ ] [P] Implement Transaction Detail screen
- [ ] [P] Write widget tests for Add/Edit Transaction: category picker, amount input with currency badge (tap to switch), notes, location toggle, validation errors
- [ ] [P] Implement Add Transaction + Edit Transaction screens (shared form, different submit action)

### 8e: AI Screens
- [ ] Write widget tests for Pre-Purchase Assistant: input form (what are you thinking of buying?, amount, category), 3 message bubbles (Devil warm-tinted, Angel cool-tinted, Neutral minimal), typing indicator while loading
- [ ] Implement Pre-Purchase Assistant screen + Riverpod provider calling `POST /api/v1/assistant/pre-purchase`

### 8f: Budgets
- [ ] Write widget tests for Budgets screen: category list, LinearProgressIndicator per budget (color changes at 80%), currency-aware formatting, create/edit/delete actions
- [ ] Implement Budgets screen + Riverpod providers (CRUD operations, display in preferred currency with conversion)

### 8g: Receipt Scanning (Premium)
- [ ] Write widget tests for Receipt Scanner: camera capture, premium gate (show upgrade prompt for free users), OCR loading state, confidence indicator
- [ ] Implement Receipt Scanner screen — check subscription tier, upload to S3 presigned URL, call scan endpoint, navigate to Review
- [ ] Write widget tests for Receipt Review: editable fields (merchant, total, date, currency, line items) pre-filled from OCR, confirm button, mandatory review during calibration
- [ ] Implement Receipt Review screen — submit corrections via `POST /api/v1/receipts/{id}/confirm`

### 8h: Settings
- [ ] Write widget tests for Settings screen: profile info, currency picker, locale picker, subscription status + manage, sign out
- [ ] Implement Settings screen + Riverpod providers

### 8i: Subscriptions (In-App Purchase)
- [ ] Write tests for subscription flow: free user sees upgrade prompts, `in_app_purchase` package wired for iOS StoreKit 2 + Android Play Billing, purchase triggers `POST /api/v1/subscriptions/verify`, tier updates in local state
- [ ] Implement subscription purchase flow + Riverpod subscription provider (listen to purchase stream, verify with backend, update cached tier)

---

## Phase 9: AWS CDK Infrastructure

_Goal: All CDK stacks defined, deployable to AWS, split-Lambda pattern configured._

- [ ] [B] Create CDK app in `infra/` using C# (`cdk init app --language csharp`)
- [ ] [B] Implement `NetworkStack`: minimal VPC (2 AZs, private subnets for RDS + VPC Lambda, no NAT Gateway)
- [ ] [P] Implement `DatabaseStack`: RDS db.t4g.micro PostgreSQL (single-AZ, 20 GB, in VPC), DynamoDB tables (all 6, on-demand billing)
- [ ] [P] Implement `StorageStack`: S3 bucket with CORS for presigned uploads
- [ ] [P] Implement `AuthStack`: Cognito Essentials user pool + app client
- [ ] [B] Implement `ComputeStack`: non-VPC Lambda (1 GB, ReadyToRun, API Gateway HTTP API trigger) + environment variables for all service endpoints
- [ ] [B] Implement `DbAccessStack`: VPC Lambda (in same VPC as RDS, 512 MB, minimal handler for RDS queries)
- [ ] [P] Implement `AIStack`: Bedrock access IAM policy, SQS queue + DLQ, Lambda trigger for async AI processing
- [ ] [P] Implement `OutboxStack`: DynamoDB Streams event source on Transactions table → Lambda (outbox processor, budget update, trigger evaluation)
- [ ] [P] Implement `ObservabilityStack`: CloudWatch log groups, X-Ray tracing enabled on Lambdas
- [ ] [B] Implement `SecretsStack`: Secrets Manager for DB connection string + Cognito client secret
- [ ] [B] Write CDK snapshot tests: verify all stacks synthesize without errors, resource counts match expectations
- [ ] [B] Deploy to staging AWS account: `cdk deploy --all`, verify health check, test one endpoint end-to-end

---

## Phase 10: Refactor, Polish & Ship Readiness

_Goal: All tests green, code reviewed, CI passing, ready for first deploy._

- [ ] Run full test suite: `dotnet test` (unit + integration) — all green
- [ ] Run Flutter test suite: `flutter test` — all green
- [ ] Review and harden error handling: all endpoints return consistent error shapes (`{ error: string, details?: object }`)
- [ ] Add request rate limiting in API Gateway HTTP API configuration (CDK)
- [ ] Add structured logging to all service methods (Serilog with correlation IDs)
- [ ] Add X-Ray tracing annotations for Lambda cold starts, DynamoDB latency, Bedrock call duration
- [ ] Verify split-Lambda pattern: non-VPC Lambda calls DynamoDB/S3/SQS/Bedrock directly, VPC Lambda only handles RDS
- [ ] Verify outbox pattern end-to-end in staging: create transaction → budget updated within 2s → alert appears if threshold crossed
- [ ] Verify receipt scanning premium gate in staging: free user gets 403, premium user scans successfully
- [ ] Verify multi-currency: create transaction in MXN, view budget summary in USD, correct formatting per locale
- [ ] Create README.md with: architecture overview, local dev setup instructions, deployment guide, environment variables reference
- [ ] Manual QA checklist:
  - [ ] Onboarding flow (register, set currency + locale)
  - [ ] Add transaction (different currencies)
  - [ ] View dashboard (budget summary, regret prompts, budget warnings)
  - [ ] Pre-purchase assistant (Devil/Angel/Neutral responses)
  - [ ] Budget CRUD + progress bars
  - [ ] Receipt scan + review (premium account)
  - [ ] Receipt scan blocked (free account)
  - [ ] Settings (change currency, locale, sign out)
  - [ ] Subscription purchase flow
