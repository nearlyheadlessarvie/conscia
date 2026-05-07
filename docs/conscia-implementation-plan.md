# Conscia — Implementation Plan (v4 — MVP Scope Tightened)

**AWS + .NET 8 + EF Core + CDK + Flutter — AI Financial Assistant**
Multi-currency, online-first MVP. MediatR dropped, costs re-validated, cross-store consistency designed, split-Lambda kept at $0. Scope tightened: LocationAggregates, Insights, push notifications, regret scheduler deferred. Receipt scanning premium-only. Smart triggers reduced to Budget Warning only.

---

## 1. Architecture

### High-Level Architecture

Clean Architecture with vertical slices. API layer (ASP.NET 8 Minimal APIs), Domain layer (pure C# entities + Money value object), Application layer (service interfaces + FluentValidation), Infrastructure layer (EF Core, AWS SDK). Multi-currency from day one. Online-first MVP — offline deferred.

> **Bootstrap Compute: Split-Lambda Pattern ($0 Networking)**
> Main API Lambda runs outside VPC — direct access to Bedrock, Textract, Cognito, SQS, S3, DynamoDB without NAT Gateway. A thin VPC-attached Lambda handles RDS queries within the same VPC as PostgreSQL. No NAT Gateway ($33/mo saved), no VPC endpoints ($21/mo saved). Tradeoff: ~50ms extra latency on DB-heavy requests + two deploy targets. Acceptable for 1-2 person team pre-revenue. Revisit when debugging cost exceeds $0/mo savings.

### Repository Structure

| Directory | Purpose |
|---|---|
| `src/Conscia.Api/` | ASP.NET 8 Minimal API host, middleware, endpoints (`/api/v1`) |
| `src/Conscia.Domain/` | Entities, Money value object, enums, domain events |
| `src/Conscia.Application/` | Service interfaces, FluentValidation validators, DTOs, `ITriggerEvaluator` interface |
| `src/Conscia.Infrastructure/` | EF Core DbContext, repositories, AWS SDK wrappers |
| `src/Conscia.Infrastructure.Db/` | VPC Lambda — thin RDS access layer (separate deploy target) |
| `src/Conscia.AI/` | AI prompt engine, personality system |
| `infra/` | AWS CDK (C#) — all infrastructure as code |
| `app/` | Flutter app — iOS and Android |
| `tests/` | Unit, integration, and E2E tests |

### AWS Service Map (Bootstrap)

| AWS Service | Role | Scale Strategy |
|---|---|---|
| Lambda (non-VPC) | Main API compute — calls all AWS services directly | Auto-scales to zero, pay-per-request |
| Lambda (VPC) | RDS access only — same VPC as PostgreSQL | Scales independently, minimal cold starts |
| API Gateway HTTP | HTTP routing, throttling, CORS | $1/M requests, built-in rate limiting |
| RDS PostgreSQL | Relational data (users, budgets, receipts) | Vertical scaling, then multi-AZ + replicas |
| DynamoDB | Transactions, behavior, AI cache, sessions | On-demand, infinite scale |
| SQS | Async AI processing queue | Decouple AI from request path |
| S3 | Receipt image storage (premium feature) | Lifecycle policies for cost |
| Amazon Bedrock | LLM inference (Claude 3 Haiku) — 2 parallel calls | On-demand, no infra to manage |
| Amazon Textract | OCR for receipt scanning (DetectText, premium only) | Serverless, per-page pricing |
| Cognito Essentials | User authentication (migration-safe from day one) | Free under 10K MAU |

### Key Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Compute topology | Split-Lambda: non-VPC (main) + VPC (RDS) | $0 networking. 1-2 person team — ops complexity is manageable, $33-54/mo saved matters pre-revenue |
| Dispatch pattern | Plain service classes (no MediatR) | 17 endpoints, 1-2 devs — MediatR adds 3 files/endpoint, assembly scanning cold start, debugging indirection for zero benefit at this scale |
| AI call strategy | 2 parallel Bedrock calls (not 1 batched) | Different temperatures per persona — Devil needs high temp, Angel needs low |
| MVP scope | Online-only, no offline sync | Offline adds massive complexity (CRDT, conflict resolution) — defer to post-MVP |
| API versioning | `/api/v1` prefix on all endpoints | Non-breaking evolution, mobile clients may lag behind |
| Currency | Money value object (amount + currency code) | Multi-currency from day one, locale-aware formatting |
| Cross-store writes | Outbox pattern for Transaction durability only | DynamoDB write + outbox event (atomic); budget usage is computed from transactions on read |
| Auth provider | Cognito Essentials (not Lite) | Same free tier, but no migration risk when scaling past 10K MAU |
| Trigger extensibility | `ITriggerEvaluator` interface — Budget Warning first | Clean abstraction allows adding new triggers (Repeated Spending, Location Pattern, etc.) by implementing a new class |
| Receipt scanning | Premium-only from day one | 26% of variable costs — must drive revenue, not drain free tier |
| Regret prompts | In-app Dashboard card (not push notifications) | Eliminates EventBridge scheduler, push notification stack, firebase_messaging dependency |

---

## 2. Backend — .NET 8 + EF Core

> **Stack:** ASP.NET 8 Minimal APIs with plain service classes (no MediatR). FluentValidation. EF Core 8 + PostgreSQL. DynamoDB SDK. Runs on Lambda via Web Adapter (1 GB memory, ReadyToRun compilation). Same code deploys to Fargate later.

### Why No MediatR?

MediatR adds a command/handler indirection layer that makes sense at 50+ endpoints with 5+ developers. At 17 endpoints with 1-2 devs, it means 3 files per endpoint (Command, Handler, Validator) instead of 1 service method. Plain service interfaces (`ITransactionService`, `IBudgetService`, etc.) give the same testability and separation with direct call stacks, better debugging, and faster Lambda cold starts (no assembly scanning at startup). Re-evaluate if the team grows past 4 developers.

### Domain Entities

| Entity | Key Fields | Storage |
|---|---|---|
| User | Id, Email, CognitoSub, PreferredCurrency, Locale, CreatedAt | RDS |
| UserSubscription | UserId, Tier, Platform, ExpiresAt, OriginalTransactionId | RDS |
| Transaction | Id, UserId, Type, Money(Amount+CurrencyCode), Category, Merchant, Date, Location, ExchangeRateToBase, RegretLevel | DynamoDB |
| Budget | Id, UserId, Category, MonthlyLimit, CurrencyCode | RDS |
| BehaviorProfile | UserId, PreventedPurchases, Overrides, Regrets | DynamoDB |
| AIInteraction | Id, TransactionId, DevilMsg, AngelMsg, NeutralMsg, CreatedAt | DynamoDB |
| Receipt | Id, TransactionId, S3Key, ExtractedData, OcrConfidence, NeedsReview, Status | RDS + S3 |
| OutboxEvent | Id, AggregateId, EventType, Payload, CreatedAt, ProcessedAt | DynamoDB (TTL) |

> **Removed from MVP:** `PendingRegretPrompt` (replaced by in-app prompt logic), `LocationAggregate` (deferred — Transaction already stores Location for future backfill), `RegretFeedback` as separate entity (merged into `Transaction.RegretLevel`).

### Money Value Object

| Property | Type | Notes |
|---|---|---|
| Amount | decimal | Always stored in original transaction currency |
| CurrencyCode | string (ISO 4217) | USD, EUR, MXN, etc. |
| ExchangeRateToBase | decimal? | Null if same as user's preferred currency |

Amounts never silently converted. Display uses user's locale for formatting (comma vs period, symbol position). Conversion only for budget aggregation, using ECB daily rates cached in DynamoDB (TTL 24h).

### Cross-Store Consistency (Transaction + Budget)

> **Current Design:** Budgets store only monthly limit metadata. Usage is derived from the current month's expense transactions at read time, so there is no cross-store "update budget spend" write to keep in sync.

**Solution:** When a Transaction is written to DynamoDB, an OutboxEvent is written in the same DynamoDB transaction (TransactWriteItems — atomic) for downstream workflows like alerts and analytics. Budget usage is computed from the transaction source of truth, which eliminates projection drift and monthly reset issues. The Flutter UI can still show an optimistic update immediately and reconcile with the computed server response on refresh.

### API Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Cognito user creation |
| POST | `/api/v1/auth/login` | Cognito token exchange |
| GET | `/api/v1/transactions` | Paginated list with filters |
| POST | `/api/v1/transactions` | Add income/expense (writes OutboxEvent atomically) |
| PUT | `/api/v1/transactions/{id}` | Edit transaction |
| DELETE | `/api/v1/transactions/{id}` | Delete transaction (writes reverse OutboxEvent) |
| POST | `/api/v1/transactions/{id}/reflect` | Trigger AI reflection |
| POST | `/api/v1/transactions/{id}/regret` | Worth-it / not-sure / regret feedback (updates Transaction.RegretLevel) |
| POST | `/api/v1/assistant/pre-purchase` | Devil + Angel + Neutral response |
| GET | `/api/v1/budgets` | List budgets |
| POST | `/api/v1/budgets` | Create budget |
| PUT | `/api/v1/budgets/{id}` | Update budget (limit, category) |
| DELETE | `/api/v1/budgets/{id}` | Delete budget |
| POST | `/api/v1/receipts/scan` | Upload + OCR via Textract (premium only) |
| POST | `/api/v1/receipts/{id}/confirm` | Confirm/correct OCR result (premium only) |
| PUT | `/api/v1/users/me` | Update profile (currency, locale) |
| POST | `/api/v1/subscriptions/verify` | Validate iOS/Android receipt |
| GET | `/api/v1/subscriptions/status` | Current subscription state |

### In-App Regret Prompt (Replaces Scheduler)

When the user opens the app, the Dashboard queries: "Transactions from 24-48h ago where `RegretLevel IS NULL`." If any exist, a dismissible card appears: "Was [purchase] worth it?" The user taps Worth It / Not Sure / Regret, which writes to `Transaction.RegretLevel`. No EventBridge, no scheduler Lambda, no PendingRegretPrompt table, no push notifications. If the user doesn't open the app within the 24-48h window, the prompt appears on their next visit (no data loss, just delayed feedback).

### Budget Warning Trigger

> **Interface: `ITriggerEvaluator`** — designed for extensibility. Budget Warning is the first implementation. Future triggers (Repeated Spending, Location Pattern, Large Purchase, Regret Trend) implement the same interface.

When a Transaction is created, the outbox pipeline can still evaluate triggers. `BudgetWarningEvaluator` checks computed budget usage for the current month and triggers when spend is `>= 80%` of `MonthlyLimit`. If triggered, an in-app alert is stored (DynamoDB, TTL 7 days) and shown as a Dashboard card on next app open. No push notification in MVP — all alerts are in-app.

### Receipt Scanning Flow (Premium Only)

1. Subscription middleware verifies premium tier before allowing scan.
2. Flutter uploads image to S3 via presigned URL.
3. Lambda calls Textract DetectText (raw OCR, $1.50/1K pages).
4. Raw text is sent to a small Bedrock call (Claude 3 Haiku) to extract structured fields: merchant, total, date, currency, line items.
5. Result returned with an OcrConfidence score.
6. If confidence is below threshold, Flutter UI shows a manual correction screen with editable fields pre-filled from OCR.
7. User confirms or corrects, then `POST /receipts/{id}/confirm` saves the final version.

> **Receipt Confidence Calibration (P3):** The initial threshold is a starting guess. Plan: first 100 receipts go through mandatory manual review regardless of confidence. Collect accuracy data per field (merchant, total, date). Set threshold per field based on real error rates. Expected: 2-4 weeks post-launch to calibrate. Until then, all receipts show the review screen.

### Key NuGet Packages

| Package | Purpose |
|---|---|
| AWSSDK.DynamoDBv2 | DynamoDB data access |
| AWSSDK.BedrockRuntime | LLM inference |
| AWSSDK.Textract | OCR processing |
| Amazon.Lambda.AspNetCoreServer.Hosting | Lambda Web Adapter hosting |
| FluentValidation | Input validation |
| Npgsql.EntityFrameworkCore.PostgreSQL | EF Core PostgreSQL provider |
| NodaMoney (or custom Money VO) | Multi-currency value object |

---

## 3. Infrastructure — AWS CDK (C#)

> **Progressive Infrastructure:** CDK stacks are toggled by environment config. Bootstrap mode deploys minimal resources. Growth/Scale modes add services reactively based on real metrics.

### CDK Stack Breakdown

| Stack | Bootstrap | Production |
|---|---|---|
| ComputeStack | Lambda (non-VPC) + API Gateway HTTP | ECS Fargate + ALB (when >250K MAU) |
| DbAccessStack | Lambda (VPC) — thin RDS proxy | Merged into ComputeStack when on Fargate |
| DatabaseStack | RDS db.t4g.micro + DynamoDB on-demand | RDS db.r6g.large multi-AZ + replica |
| StorageStack | S3 bucket | S3 + lifecycle policies (IA at 30 days) |
| AuthStack | Cognito Essentials (migration-safe) | Cognito Essentials |
| AIStack | Bedrock access + SQS + Lambda triggers | Same + dead-letter queues |
| OutboxStack | DynamoDB Streams Lambda (outbox + budget trigger eval) | Same + monitoring alarms |
| NetworkStack | Minimal VPC (for RDS + DbAccess Lambda only) | Full VPC, optional NAT Gateway or VPC endpoints |
| SecurityStack | Not deployed — app-layer security | WAF + Shield (when metrics justify) |
| CacheStack | Not deployed — DynamoDB TTL | ElastiCache Redis (when p99 <1ms needed) |
| ObservabilityStack | CloudWatch basic + X-Ray | Dashboards + alarms + SNS |

> **Removed from Bootstrap:** SchedulerStack (EventBridge + Regret/Location Lambdas). Regret prompts are in-app. Location aggregation deferred. Outbox processing handled by DynamoDB Streams Lambda in OutboxStack.

### Split-Lambda: Escape Hatch

If split-Lambda debugging becomes painful (cold start stacking, retry failures, observability gaps), the escape hatch is straightforward: move to single VPC Lambda + 3 VPC endpoints (~$21/mo). Same code, same deploy pipeline — just change CDK config to put the main Lambda in the VPC and add interface endpoints for Bedrock, SQS, Secrets Manager. DynamoDB and S3 gateway endpoints are free. Total migration: CDK config change + one deploy.

### DynamoDB Table Design

| Table | PK | SK | GSIs | TTL |
|---|---|---|---|---|
| Transactions | USER#{userId} | TXN#{date}#{id} | GSI1: Category+Date for reports | No |
| AIInteractions | TXN#{transactionId} | AI#{timestamp} | GSI1: USER#{userId}+Date for history | 90 days |
| BehaviorProfiles | USER#{userId} | PROFILE | None — single item per user | No |
| SessionCache | SESSION#{token} | — | None | 5 min |
| OutboxEvents | AGG#{aggregateId} | EVENT#{timestamp} | GSI1: ProcessedAt=null for pending | 7 days after processed |
| InAppAlerts | USER#{userId} | ALERT#{timestamp} | None | 7 days |

> **Removed from MVP:** PendingRegretPrompts table (replaced by in-app query on Transaction.RegretLevel), LocationAggregates table (deferred — Transaction stores Location for future backfill).

### Cognito: Essentials from Day One

> **Why Not Start on Lite?** Migrating from Cognito Lite to Essentials can require recreating the user pool — risking user data loss and auth disruption. Essentials is free under 10K MAU (same as Lite) but includes advanced security features and a smooth upgrade path. No cost penalty, eliminates a future migration risk.

---

## 4. AWS Cost Analysis — Re-Validated Against AWS Pricing

All numbers re-calculated from AWS pricing pages (May 2026). Lambda free tier (1M requests + 400K GB-sec) applied correctly. Bedrock per-token ($0.25/M input, $1.25/M output). DynamoDB at post-2024 rates ($0.25/M RRU, $1.25/M WRU). Split-Lambda at $0 networking. Receipt scanning costs now premium-only (lower usage assumed).

### Standby Cost (0 Users, 0 Requests)

| Service | Config | Why | Monthly |
|---|---|---|---:|
| Lambda (non-VPC + VPC) | 1 GB, 0 invocations | Scale-to-zero, $0 at idle | $0.00 |
| API Gateway HTTP | HTTP API, 0 requests | $1/M requests, $0 at idle | $0.00 |
| RDS PostgreSQL | db.t4g.micro, single-AZ, 20 GB | Only fixed cost — schema must exist | $14.48 |
| DynamoDB | On-demand, empty tables | $0 with no reads/writes | $0.00 |
| S3 | Empty bucket | $0 with no objects | $0.00 |
| Cognito Essentials | User pool, 0 MAU | Free under 10K MAU | $0.00 |
| Bedrock / Textract / SQS | No calls | All pay-per-use | $0.00 |
| CloudWatch | Basic metrics | Free tier covers it | $0.00 |
| Secrets Manager | 2 secrets (DB + Cognito) | $0.40/secret/mo | $0.80 |
| **Total** | | | **$15.28** |

> **Monthly Standby: $15** | **Annual Burn: $183** | **Fixed-Cost Services: 1 (RDS)**

> Standby reduced from v3: removed EventBridge + Scheduler Lambda (was $0 anyway, but now zero infra to manage).

---

### With 1K MAU — Corrected Math

Assumes 15 AI interactions/user/mo (2 Bedrock calls each), 30 transactions/user/mo. Receipt scanning is premium-only — estimated 10% premium conversion = 100 premium users × 5 receipts = 500 receipts/mo (down from 5,000).

| Service | Usage at 1K MAU | Calculation | Monthly |
|---|---|---|---:|
| Lambda (all functions) | ~350K inv, ~130K GB-sec | Within free tier (1M req + 400K GB-sec) | $0.00 |
| API Gateway HTTP | ~250K requests | 250K × $1/M | $0.25 |
| RDS PostgreSQL | db.t4g.micro, 20 GB | Fixed | $14.48 |
| DynamoDB | 400K reads, 160K writes | 0.4M × $0.25 + 0.16M × $1.25 + Streams | $0.30 |
| S3 | 0.5 GB receipts (premium only), 1K requests | Storage + requests | $0.02 |
| Cognito Essentials | 1K MAU | Free tier | $0.00 |
| Bedrock — AI (30K calls) | 9M input + 3.9M output tokens | 9 × $0.25 + 3.9 × $1.25 | $7.13 |
| Bedrock — receipts (500 calls) | 100K input + 40K output tokens | Negligible | $0.08 |
| Textract DetectText | 500 pages (premium only) | 500 × $1.50/K | $0.75 |
| SQS | 40K messages | Free tier | $0.00 |
| CloudWatch | 4 GB logs | Free tier (5 GB) | $0.00 |
| Secrets Manager | 2 secrets | $0.40/secret | $0.80 |
| **Total** | | | **$23.81** |

> **Monthly at 1K MAU: $24** (down from $32 in v3) | **Per User/Month: $0.024** | **Lambda: $0 (free tier!)**

> **Savings vs v3:** -$7.78/mo. Receipt scanning dropped from 5K to 500 pages (premium gate). Removed scheduler Lambda invocations. Fewer DynamoDB operations (no LocationAggregate writes, no PendingRegretPrompt writes).

---

### Growth Phase — 5K MAU

Estimated 15% premium conversion = 750 premium users × 5 receipts = 3,750 receipts/mo.

| Service | Usage | Calculation | Monthly |
|---|---|---|---:|
| Lambda (all functions) | ~1.8M inv, ~650K GB-sec | (650K-400K) × $0.0000167 + (1.8M-1M) × $0.20/M | $4.33 |
| API Gateway HTTP | ~1.3M requests | 1.3M × $1/M | $1.30 |
| RDS PostgreSQL | db.t4g.small, 30 GB | Upgraded | $26.38 |
| DynamoDB | 2M reads, 800K writes | 2 × $0.25 + 0.8 × $1.25 + Streams | $1.50 |
| S3 | 4 GB, 8K requests | | $0.10 |
| Cognito Essentials | 5K MAU | Free tier | $0.00 |
| Bedrock — AI (150K calls) | 45M in + 19.5M out tokens | 45 × $0.25 + 19.5 × $1.25 | $35.63 |
| Bedrock — receipts (3.75K) | 750K in + 300K out tokens | | $0.56 |
| Textract DetectText | 3.75K pages | 3.75K × $1.50/K | $5.63 |
| SQS | 200K messages | Free tier | $0.00 |
| CloudWatch | 15 GB logs | Free 5 GB + 10 × $0.50 | $5.00 |
| Secrets Manager | 3 secrets | | $1.20 |
| **Total** | | | **~$82** |

> **~$82/mo at 5K MAU — $0.016/user** (down from ~$124 in v3)

---

### Growth Phase — 10K MAU

Estimated 20% premium conversion = 2,000 premium users × 5 receipts = 10,000 receipts/mo.

| Service | Usage | Calculation | Monthly |
|---|---|---|---:|
| Lambda (all functions) | ~3.5M inv, ~1.3M GB-sec | (1.3M-400K) × $0.0000167 + (3.5M-1M) × $0.20/M | $15.52 |
| API Gateway HTTP | ~2.5M requests | | $2.50 |
| RDS PostgreSQL | db.t4g.small, 50 GB | | $30.18 |
| DynamoDB | 4M reads, 1.6M writes | 4 × $0.25 + 1.6 × $1.25 + Streams | $3.00 |
| S3 | 10 GB, 20K requests | | $0.25 |
| Cognito Essentials | 10K MAU | Free tier edge | $0.00 |
| Bedrock — AI (300K calls) | 90M in + 39M out tokens | | $71.25 |
| Bedrock — receipts (10K) | 2M in + 0.8M out tokens | | $1.50 |
| Textract DetectText | 10K pages | | $15.00 |
| SQS | 400K messages | | $0.16 |
| CloudWatch | 40 GB (sampled 20%) | 8 GB ingested | $1.50 |
| Secrets Manager | 3 secrets | | $1.20 |
| **Total** | | | **~$142** |

> **~$142/mo at 10K MAU — $0.014/user** (down from ~$217 in v3)

### Decision Points — Add Services Reactively

| Metric | Threshold | Action | Added Cost |
|---|---|---|---|
| Lambda cold starts | p99 > 3s annoying users | Enable Provisioned Concurrency (5 instances) | +$15/mo |
| Split-Lambda debugging | Spending >2h/week on inter-Lambda issues | Switch to single VPC Lambda + VPC endpoints | +$21/mo |
| RDS connections | Peak > 80 concurrent | Upgrade to db.t4g.medium | +$12/mo |
| Cognito MAU | Crosses 10K free tier | Essentials at $0.0065/MAU (no migration needed) | +$65/mo at 20K MAU |
| API read latency | p99 > 500ms | Add DynamoDB DAX cache cluster | +$35/mo |
| Security posture | Before funding / compliance audit | Add WAF | +$14/mo |
| User engagement | Users not opening app for regret prompts | Add push notifications (firebase_messaging + EventBridge) | +$0 infra, ~1 day dev |
| Location patterns | Users active 60+ days, enough data for patterns | Add LocationAggregate system (DynamoDB Streams Lambda) | +$2/mo |

> **Key Insight:** At 10K MAU, Bedrock AI ($71.25) is now 50% of total cost (was 65% when receipts were free-tier). Premium-gating receipts cut Textract+Bedrock receipt costs by 80%.

---

### Scale Phase — 100K MAU

Estimated 25% premium conversion = 25,000 premium users × 5 receipts = 125,000 receipts/mo.

| Service | Config | Monthly |
|---|---|---:|
| Lambda (all functions) | ~35M invocations, ~13M GB-sec | $226.07 |
| Provisioned Concurrency | 20 instances | $58.40 |
| API Gateway HTTP | ~25M requests | $25.00 |
| RDS PostgreSQL | db.r6g.large, multi-AZ + replica | $503.52 |
| DynamoDB | 40M reads, 16M writes | $28.50 |
| S3 | 125 GB + IA lifecycle | $3.01 |
| Cognito Essentials | 100K MAU ($0.0065 past 10K) | $585.00 |
| Bedrock AI (3M calls) | 900M in + 390M out tokens | $712.50 |
| Bedrock receipts (125K) | 25M in + 10M out tokens | $18.75 |
| Textract DetectText | 125K pages (premium only) | $187.50 |
| SQS | 4M messages | $1.60 |
| CloudWatch | 150 GB (sampled 10%) | $5.00 |
| WAF (added) | 1 ACL + 10 rules, 25M requests | $61.00 |
| Secrets Manager | 6 secrets | $2.40 |
| **Total** | | **~$2,417** |

> **~$2,417/mo at 100K MAU — $0.024/user** (down from ~$2,792 in v3)

### Cost Summary

| Scale | Monthly (v4) | Monthly (v3) | Savings |
|---|---:|---:|---|
| Standby (0 users) | $15 | $15 | Same (less infra to manage) |
| 1K MAU | $24 | $32 | -25% |
| 5K MAU | $82 | $124 | -34% |
| 10K MAU | $142 | $217 | -35% |
| 100K MAU | $2,417 | $2,792 | -13% |

> **Philosophy: Add Services When They Earn Their Keep.** Split-Lambda = $0 networking. No WAF until 10K+ MAU. No ECS/ALB until 250K+ MAU. No ElastiCache until p99 demands it. No push notifications until engagement data demands it. Cognito Essentials from day one — no migration risk. Receipt scanning = premium revenue driver, not free-tier cost center. Every dollar justified by a real metric.

---

## 5. Frontend — Flutter (iOS + Android)

> **Online-Only MVP.** Riverpod 2.x for DI and reactive state. GoRouter for declarative navigation. Dio for HTTP with interceptors. Offline-first deferred to post-MVP.

### Screen Map

| Screen | Route | Features |
|---|---|---|
| Onboarding | `/onboarding` | Welcome slides, sign-up / sign-in, preferred currency + locale picker |
| Dashboard | `/` | Budget summary (computed from current-month transactions), recent transactions, quick-add FAB, **regret prompt cards** (24-48h old unreviewed transactions), **budget warning cards** |
| Transactions | `/transactions` | Filterable list, pull-to-refresh, infinite scroll |
| Transaction Detail | `/transactions/:id` | Detail card, tap triggers AI reflection modal |
| Add Transaction | `/transactions/add` | Category picker, amount + currency, notes, location toggle |
| Edit Transaction | `/transactions/:id/edit` | Pre-filled form, same layout as Add |
| Receipt Scanner | `/scan` | Camera capture, OCR auto-fill, confidence indicator **(premium only)** |
| Receipt Review | `/receipts/:id/review` | Editable fields pre-filled from OCR, confirm button (mandatory during calibration phase) **(premium only)** |
| Pre-Purchase | `/assistant` | Devil/Angel/Neutral conversation UI |
| Budgets | `/budgets` | Category budget list, progress bars (`LinearProgressIndicator`), currency-aware formatting |
| Settings | `/settings` | Profile, location, subscription, currency + locale |

> **Deferred screens:** Insights (`/insights` — trends, analytics). Added when users have 60+ days of data.

### Multi-Currency UX

| Scenario | Behavior |
|---|---|
| Entering a transaction | Default currency = user's preferred. Tap currency badge to switch (e.g., MXN while traveling). |
| Displaying amounts | Always show original currency. Budget screens show converted total in preferred currency. |
| Locale formatting | Inferred from device locale, overridable in Settings. Controls decimal separator, symbol position. |
| Budget aggregation | Sums converted to preferred currency using cached ECB daily rate. Current-month spend is computed from transactions on read. |
| AI personality messages | Amounts quoted in the transaction's original currency for accuracy. |

### Key Packages

| Package | Purpose |
|---|---|
| flutter_riverpod | State management + DI |
| go_router | Declarative routing with deep links |
| dio | HTTP client with interceptors |
| freezed / json_serializable | Immutable models + JSON |
| flutter_secure_storage | Secure token storage |
| in_app_purchase | iOS App Store + Android Play Store |
| intl | Locale-aware number/date/currency formatting |

> **Deferred packages:** `firebase_messaging` (push notifications — add when engagement data demands pull-back notifications), `fl_chart` (add when Insights screen ships with trend lines and spending breakdowns).

### AI Response UI

Chat-style with three distinct message bubbles — Devil (warm-tinted), Angel (cool-tinted), Neutral (minimal). Two parallel API calls return all three personas. Responses rendered synchronously (no SSE — API Gateway HTTP API limitation). Typing indicators shown while waiting (~1-2s).

---

## 6. AI Engine — Dual-Personality System

> **MVP Simplicity First.** Ship with temperature variance + dynamic context injection only. Defer anti-repetition system (Jaccard similarity, phrase cache, rotation index) until real users report repetitive responses. Premature complexity for a problem that may not exist.

### Prompt Architecture (2 Layers for MVP)

| Layer | Inputs | Implementation |
|---|---|---|
| Context Layer | Budget %, category trends, spending frequency, location, regret history, currency | ContextBuilder queries DynamoDB + RDS (via VPC Lambda) |
| Tone Layer | Context signals + personality-specific framing rules | Devil (emotional, high temp), Angel (data-driven, low temp), Neutral (reflective question, low temp) |

> **Deferred: Variation Layer (Post-MVP).** Jaccard similarity on last 20 responses, phrase-recency cache (DynamoDB TTL), rotation index. Add when users report repetition — expected trigger: 3-6 months post-launch when power users have 100+ interactions.

### 2-Call Pattern (Temperature Fix)

> **Why Not a Single Batched Call?** Devil needs high temperature (0.8-0.95) for creative output. Angel needs low temperature (0.4-0.6) for precision. A single API call can only have one temperature. Solution: 2 parallel calls.

| Call | Personas | Temperature | Max Tokens | Why |
|---|---|---|---|---|
| Call 1 (high temp) | Devil only | 0.85-0.95 | ~100 | Creative, unpredictable output |
| Call 2 (low temp) | Angel + Neutral | 0.4-0.55 | ~160 (120 + 40) | Data-driven precision, reflective tone |

Both calls fire in parallel (`Task.WhenAll`). Total latency = max(call1, call2) ~ 1-2s. Per-interaction cost: ~$0.00048 with Claude 3 Haiku. Saves 33% vs 3 separate calls by combining Angel + Neutral.

### Smart Intervention Triggers (MVP: Budget Warning Only)

| Trigger | Condition | Action | Status |
|---|---|---|---|
| Budget Warning | Category spend >= 80% | In-app Dashboard card with Angel insight | **MVP** |
| Repeated Spending | 3+ same category in 7 days | Auto-trigger reflection | Deferred |
| Location Pattern | 3+ visits same merchant in 14 days | Location-aware insight | Deferred (requires LocationAggregate) |
| Large Purchase | Amount > 2x category average | Suggest pre-purchase assistant | Deferred |
| Regret Trend | 3+ regrets same category | Stronger Angel tone | Deferred |

> **Extensibility:** All triggers implement `ITriggerEvaluator`. Adding a new trigger = new class + register in DI. No changes to existing code.

### Receipt Parsing via Bedrock (Premium Only)

Textract DetectText returns raw lines of text. A small Bedrock call (~200 input tokens + OCR text, ~80 output tokens) extracts structured JSON: merchant, total, date, currency, line items. Replaces AnalyzeExpense ($15/1K pages) with DetectText ($1.50/1K) + Bedrock (~$0.15/1K) = 90% cheaper. Gated to premium subscribers — subscription middleware validates tier before allowing scan.

---

## 7. Subscriptions — iOS App Store + Android Marketplace

> **Platform-Specific.** iOS: StoreKit 2 + App Store Server Notifications V2. Android: Play Billing 6.x + Real-Time Developer Notifications.

### Tiers

| Feature | Free | Premium |
|---|---|---|
| Manual Tracking | Unlimited | Unlimited |
| Budgets | 3 categories | Unlimited |
| Pre-Purchase Assistant | 5/month | Unlimited |
| Transaction Reflections | 10/month | Unlimited |
| Receipt Scanning | **No** | Unlimited |
| Location Insights | No | Yes (when shipped) |
| Behavior Analytics | Basic | Full + trends (when shipped) |
| Multi-Currency | 1 currency only | Unlimited currencies |

> **Changed from v3:** Receipt scanning moved from "5 free/month" to "premium-only." This turns the most expensive feature from a cost center into a revenue driver.

### Backend Endpoints

| Endpoint | Purpose |
|---|---|
| POST `/api/v1/subscriptions/verify-ios` | Validate App Store receipt, activate premium |
| POST `/api/v1/subscriptions/verify-android` | Validate Play Store token, activate premium |
| POST `/api/v1/webhooks/appstore` | App Store Server Notification V2 handler |
| POST `/api/v1/webhooks/playstore` | Google Play RTDN handler |
| GET `/api/v1/subscriptions/status` | Current subscription state |

Entitlements stored on UserSubscription entity: Tier, Platform, ExpiresAt, OriginalTransactionId. API middleware checks tier with 5-min DynamoDB TTL cache (SessionCache table).

> **Removed from v3:** EventBridge scheduled Lambda for subscription reconciliation. Instead, webhook handlers update state in real-time. A manual reconciliation CLI tool can be run if drift is suspected.

---

## 8. Local Development — Zero AWS Cost

> **Full Stack Locally.** Docker Compose replaces every AWS service. Same .NET code, same EF Core migrations, same DynamoDB table schemas — just different connection strings via DI. Zero AWS spend during development.

### AWS to Local Replacements

| AWS Service | Local Replacement | Fidelity |
|---|---|---|
| RDS PostgreSQL | PostgreSQL 16 (Docker) | Exact — same engine, same EF Core migrations |
| DynamoDB | DynamoDB Local (Amazon Docker image) | High — supports all operations, GSIs, TTL, Streams |
| S3 | MinIO (S3-compatible API) | High — same AWS SDK calls, presigned URLs work |
| SQS | ElasticMQ (SQS-compatible) | High — same SDK, FIFO support |
| Bedrock (Claude 3 Haiku) | Ollama (llama3.2 or mistral) | Medium — different model, same prompt format |
| Textract | Tesseract OCR API (Docker) | Medium — raw text matches DetectText |
| Cognito | Mock Cognito (custom ASP.NET middleware) | High — JWT validation, same token format |
| CloudWatch | Seq (structured logging) | High — better DX, Serilog sink |

### docker-compose.yml Services

| Service | Image | Ports | Notes |
|---|---|---|---|
| postgres | postgres:16-alpine | 5432:5432 | POSTGRES_DB=conscia, POSTGRES_USER=conscia |
| dynamodb-local | amazon/dynamodb-local:latest | 8000:8000 | -sharedDb flag for single table namespace |
| minio | minio/minio:latest | 9000:9000, 9001:9001 | MINIO_ROOT_USER/PASSWORD, console on 9001 |
| elasticmq | softwaremill/elasticmq:latest | 9324:9324 | SQS-compatible, queues configured via .conf |
| ollama | ollama/ollama:latest | 11434:11434 | GPU passthrough optional, CPU works for dev |
| tesseract-api | hertzg/tesseract-server:latest | 8080:8080 | HTTP API wrapping Tesseract OCR engine |
| seq | datalust/seq:latest | 5341:5341, 8081:80 | Structured log viewer, Serilog integration |

> **Removed from v3:** Hangfire container (was for EventBridge/scheduler simulation). No scheduler in MVP — regret prompts are query-based.

### DI Wiring — Environment Switch

A single `IHostEnvironment` check in `Program.cs` swaps all infrastructure bindings. No MediatR assembly scanning — just direct service registration via built-in DI.

| Interface | AWS Implementation | Local Implementation |
|---|---|---|
| IAmazonDynamoDB | AmazonDynamoDBClient (default) | AmazonDynamoDBClient(config with ServiceURL = localhost:8000) |
| IAmazonS3 | AmazonS3Client (default) | AmazonS3Client(config with ServiceURL = localhost:9000, ForcePathStyle) |
| IAmazonSQS | AmazonSQSClient (default) | AmazonSQSClient(config with ServiceURL = localhost:9324) |
| IAIService | BedrockAIService (Claude 3 Haiku) | OllamaAIService (HTTP client to localhost:11434) |
| IOcrService | TextractOcrService | TesseractOcrService (HTTP client to localhost:8080) |
| IAuthService | CognitoAuthService | MockAuthService (valid JWT, configurable user) |
| ITransactionService | TransactionService (DynamoDB + outbox) | Same code, local DynamoDB |
| IBudgetService | BudgetService (EF Core) | Same code, local PostgreSQL |
| ITriggerEvaluator | BudgetWarningEvaluator | Same code, local data |
| ILogger (Serilog) | CloudWatch sink | Seq sink (localhost:5341) |

### Ollama — Local AI Setup

After `docker-compose up`, pull a model once: `ollama pull llama3.2` (2.0 GB). OllamaAIService implements `IAIService`. Prompts are identical — only HTTP transport and model name differ.

> **Model Fidelity:** Local models won't match Claude 3 Haiku quality. Local dev validates flow, UI, and integration. AI quality testing requires staging with real Bedrock.

### Mock Cognito

Custom ASP.NET middleware: issues JWTs with configurable claims, validates with local symmetric key, exposes `/auth/register` and `/auth/login` matching Cognito surface, supports multiple test users with different tiers.

### Database Seeding

| Script | Purpose | Data |
|---|---|---|
| seed-rds.sql | PostgreSQL seed data | 3 test users (free, premium, expired), 5 budgets, 10 receipts |
| seed-dynamo.sh | DynamoDB seed data | 50 transactions (with RegretLevel samples), 20 AI interactions, behavior profiles, outbox events, in-app alerts |
| seed-minio.sh | S3 receipt images | 10 sample receipt images for OCR testing |

### Developer Workflow

| Step | Command | Notes |
|---|---|---|
| 1. Start infra | `docker-compose up -d` | All local services boot in ~15s |
| 2. Run migrations | `dotnet ef database update -p src/Conscia.Infrastructure` | EF Core against local PostgreSQL |
| 3. Create DynamoDB tables | `dotnet run --project tools/DynamoSetup` | Creates all tables + GSIs locally |
| 4. Seed data | `dotnet run --project tools/Seeder` | Runs all seed scripts |
| 5. Start API | `dotnet run --project src/Conscia.Api` | https://localhost:5001, ASPNETCORE_ENVIRONMENT=Development |
| 6. Start Flutter | `flutter run` | Connects to localhost API, hot reload |
| 7. View logs | http://localhost:8081 | Seq dashboard |
| 8. View MinIO | http://localhost:9001 | Browse uploaded receipts |

### Integration Testing — Testcontainers

Testcontainers spins up disposable Docker containers per test class. Fresh PostgreSQL + DynamoDB Local per test. EF Core migrations run automatically.

| Test Category | Container | Validates |
|---|---|---|
| Repository tests | PostgreSQL + DynamoDB Local | EF Core queries, DynamoDB ops, outbox pattern |
| AI integration | Ollama (llama3.2) | Prompt formatting, response parsing, 2-call pattern |
| Receipt pipeline | MinIO + Tesseract API | S3 upload, OCR, Bedrock parsing mock |
| Auth tests | Mock Cognito (in-process) | JWT issuance, tier checks, premium gate |
| Queue tests | ElasticMQ | SQS publish/consume, DLQ handling |
| Trigger tests | DynamoDB Local | BudgetWarningEvaluator, ITriggerEvaluator interface compliance |

> **CI Pipeline:** GitHub Actions runs the same Testcontainers. docker-compose.ci.yml pins image versions. Tests run in ~90s on a 4-core runner. No AWS credentials needed.

---

## 9. Deferred Features — Retrofit Roadmap

Features explicitly deferred from MVP. Each includes the prerequisite already preserved in the current design, estimated retrofit cost, and the trigger metric for when to build it.

| Feature | Retrofit Cost | Prerequisite Preserved | Build Trigger |
|---|---|---|---|
| **LocationAggregate system** | Trivial | Transaction stores Location + MerchantName | Users active 60+ days, enough data for merchant patterns |
| **Insights screen** | Trivial | Transaction + Budget data model supports all aggregation queries | Users ask "what patterns do you see?" or retention drops |
| **Smart triggers** (Repeated Spending, Location Pattern, Large Purchase, Regret Trend) | Moderate | `ITriggerEvaluator` interface, Budget Warning validates pipeline | Budget Warning engagement > 30% open rate |
| **Push notifications** | Moderate | RegretLevel on Transaction, in-app alert infrastructure | Users not opening app within 48h of transactions |
| **Regret scheduler** (push-based) | Moderate | RegretLevel field on Transaction, in-app prompt validates UX | Push notification infra already added, in-app regret < 20% response rate |
| **AI anti-repetition** (Variation Layer) | Moderate | Context + Tone layers stable, DynamoDB TTL cache ready | Power users with 100+ interactions report repetition (3-6 months) |
| **fl_chart** (trend visualizations) | Trivial | None needed | Insights screen ships |
| **Offline-first sync** | Painful | Online-only MVP validates core UX | Strong demand from users in low-connectivity regions |

> **Key principle:** Every deferred feature has a clear data-driven trigger. Don't build it because it's cool — build it when a metric demands it. The MVP validates the core loop: manual tracking + budgets + Devil/Angel/Neutral AI + multi-currency + premium receipt scanning.
