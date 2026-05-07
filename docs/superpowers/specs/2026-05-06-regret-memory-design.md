# Regret Memory System — Design Spec

**Date:** 2026-05-06
**Phase:** 3
**Status:** Approved

---

## Goal

Surface the user's past regret patterns as reactive insights — on the dashboard as a glimpse card and on a dedicated Insights screen — so they can see which merchants and categories are chronic sources of regret, with projections of what that costs them over time.

## Scope

Phase 3 is **reactive insights only** (no pre-purchase warnings). Pre-purchase memory alerts are deferred to a later phase.

---

## Architecture

### What already exists

- `RegretLevel` enum (`WorthIt`, `NotSure`, `Regret`) stored on every `Transaction`
- `POST /api/v1/transactions/{id}/regret` endpoint and `UpdateRegretLevelAsync` service method
- `WeeklyInsights` table, entity, repository, and `BehavioralInsightsService` — computes weekly mood + top-3 category regret rates for the dashboard mood card. Has `InsightsProcessor` service but **no scheduled trigger** (currently on-demand only)
- `BehaviorProfile` table — entity and repository defined but entirely unused; will remain dormant

### What we're building

A `PurchasePatterns` DynamoDB table populated nightly, a set of read-only Insights API endpoints, and the Flutter Insights screen with drill-down.

---

## Data Model

### `PurchasePatterns` table

Single-table design. PK = `USER#{userId}`. Three SK patterns:

| SK | Purpose | Key attributes |
|---|---|---|
| `SUMMARY` | Dashboard glimpse card | `RegrettedAmount` (decimal), `RegrettedCategory` (string), `AvgRegretRate` (decimal), `PatternCount` (int), `UpdatedAt` |
| `CAT#{category}` | Per-category stats | `TotalSpend` (decimal), `RegrettedSpend` (decimal), `RegretRate` (decimal), `TransactionCount` (int), `ProjectedAnnual` (decimal), `UpdatedAt` |
| `MER#{merchant}` | Per-merchant stats | `VisitCount` (int), `RegretCount` (int), `RegretRate` (decimal), `LastVisitDate` (string yyyy-MM-dd), `UpdatedAt` |

> **Merchant name normalisation:** before writing `MER#{merchant}` keys, the aggregator trims whitespace and lowercases the merchant name. The stored `merchant` display value uses the most recently seen casing. This prevents "amazon" and "Amazon" splitting into two records.

No GSI required — all reads are by `USER#{userId}` with SK prefix filters (`begins_with`).

**Aggregation window:** rolling 30 days of transactions.

**`ProjectedAnnual`** = `(RegrettedSpend / 30) * 365`

**`SUMMARY.RegrettedAmount`** = the single largest `RegrettedSpend` value across all categories (the worst offender). `RegrettedCategory` is that category's name.

**`SUMMARY.PatternCount`** = number of `CAT#*` records with `RegretRate >= 0.4` (i.e. categories where 40%+ of spend is regretted).

---

## Backend

### Nightly aggregation Lambda — `conscia-pattern-aggregator`

New .NET 8 Lambda project: `src/Conscia.PatternAggregator/`.

**Runs two jobs per invocation:**
1. **PurchasePatterns aggregation** — for each user with transactions in the last 30 days, compute all `CAT#*`, `MER#*`, and `SUMMARY` records and batch-write to `PurchasePatterns`
2. **WeeklyInsights calculation** — call the existing `BehavioralInsightsService.CalculateAndStoreWeeklyInsightsAsync` for each active user (reuses existing logic, no duplication)

**Schedule:** EventBridge Scheduler, nightly at 02:00 UTC.

**User discovery:** scan the Transactions table for distinct `UserId` values with `Date >= today - 30 days` via `GSI-Date`. Only processes users with recent activity.

**New CDK stack:** `PatternAggregatorStack` — defines the Lambda, EventBridge Scheduler rule, and grants read on `TransactionsTable` + read/write on `PurchasePatterns` + read/write on `WeeklyInsightsTable`.

### New files in `src/Conscia.Application/`

- `Interfaces/IPurchasePatternRepository.cs`
  - `GetSummaryAsync(Guid userId)`
  - `GetCategoriesAsync(Guid userId)`
  - `GetMerchantsAsync(Guid userId)`
  - `UpsertManyAsync(Guid userId, IEnumerable<PurchasePatternRecord> records)`

- `Interfaces/IPurchasePatternService.cs`
  - `GetSummaryAsync(Guid userId)`
  - `GetCategoriesAsync(Guid userId)`
  - `GetMerchantsAsync(Guid userId)`

- `Services/PurchasePatternService.cs` — thin pass-through; returns nulls gracefully when no patterns exist yet

- `DTOs/InsightsDtos.cs` — response shapes for all endpoints

### New files in `src/Conscia.Infrastructure/`

- `Repositories/PurchasePatternRepository.cs` — DynamoDB CRUD, batch writes via `TransactWriteItems`

### New endpoints — `src/Conscia.Api/Endpoints/InsightsEndpoints.cs`

All require auth. All return `404` when no patterns exist yet (user has not had data processed).

| Method | Path | Returns |
|---|---|---|
| `GET` | `/api/v1/insights/summary` | SUMMARY record |
| `GET` | `/api/v1/insights/categories` | All `CAT#*` records, sorted by `RegretRate` desc |
| `GET` | `/api/v1/insights/categories/{category}` | Single category stats + last 10 transactions in that category |
| `GET` | `/api/v1/insights/merchants` | All `MER#*` records, sorted by `RegretRate` desc |
| `GET` | `/api/v1/insights/merchants/{merchant}` | Single merchant stats + last 10 transactions at that merchant |

Detail endpoints (`/categories/{category}` and `/merchants/{merchant}`) return pre-aggregated stats from `PurchasePatterns` plus a live transaction query from the Transactions table so individual items are always fresh.

### Infrastructure updates

- `DatabaseStack.cs` — add `PurchasePatterns` table (PK only, no SK index, no GSI)
- `DynamoSetup/Program.cs` — mirror the same table definition for local dev
- `ComputeStack.cs` — add `PurchasePatternsTable` env var to API Lambda
- New `PatternAggregatorStack.cs` — Lambda + EventBridge Scheduler + IAM grants
- `infra/.../Program.cs` (CDK app entry) — instantiate `PatternAggregatorStack`

---

## Frontend

### Dashboard

New `RegretSummaryCard` widget in `app/lib/screens/dashboard/widgets/regret_summary_card.dart`.

- Reads from `insightsSummaryProvider`
- Shows: `"£{amount} regretted on {category} last month"`
- Taps to push `/insights`
- Shows `SizedBox.shrink()` when summary is null (no data yet) — no empty state card

### Insights Screen

`app/lib/screens/insights/insights_screen.dart`

Three sections in a single scroll:

1. **Stats header** — three `Column`s in a `Row`:
   - Biggest regretted spend (amount + category)
   - Avg regret rate (percentage)
   - Patterns found (count of high-regret categories)

2. **`MerchantSpotlightCard`** (`widgets/merchant_spotlight_card.dart`) — worst merchant by regret rate, visit count, regret count, horizontal progress bar. Taps to `/insights/merchants`

3. **`CategoryTrendCard`** (`widgets/category_trend_card.dart`) — worst category by regret rate, regretted spend, projected annual spend. Taps to `/insights/categories`

Both cards show a "No data yet" placeholder when providers return empty lists.

### Drill-down screens (all under `app/lib/screens/insights/`)

- `merchant_list_screen.dart` — all merchants ranked by `RegretRate` desc, `ListTile` with rate + visit count. Taps to `/insights/merchants/:merchant`
- `merchant_detail_screen.dart` — merchant stats header + last 10 transactions (reuses `TransactionTile`)
- `category_list_screen.dart` — all categories ranked, same pattern. Taps to `/insights/categories/:category`
- `category_detail_screen.dart` — category stats header + projected annual spend + last 10 transactions

### Providers

`app/lib/providers/insights_provider.dart`

- `insightsSummaryProvider` — `FutureProvider<InsightsSummary?>`, `GET /insights/summary`, invalidates when `transactionListProvider` changes
- `insightsMerchantsProvider` — `FutureProvider<List<MerchantStat>>`, `GET /insights/merchants`
- `insightsCategoriesProvider` — `FutureProvider<List<CategoryStat>>`, `GET /insights/categories`
- `merchantDetailProvider` — `FutureProvider.family<MerchantDetail?, String>`, `GET /insights/merchants/{merchant}`
- `categoryDetailProvider` — `FutureProvider.family<CategoryDetail?, String>`, `GET /insights/categories/{category}`

### Models

`app/lib/models/insights_models.dart`

- `InsightsSummary` — `regrettedAmount`, `regrettedCategory`, `avgRegretRate`, `patternCount`
- `MerchantStat` — `merchant`, `visitCount`, `regretCount`, `regretRate`, `lastVisitDate`
- `CategoryStat` — `category`, `totalSpend`, `regrettedSpend`, `regretRate`, `transactionCount`, `projectedAnnual`
- `MerchantDetail` — `MerchantStat` + `List<Transaction> recentTransactions`
- `CategoryDetail` — `CategoryStat` + `List<Transaction> recentTransactions`

All models use `fromJson` factory constructors. No Freezed — keep it simple.

### Routing

5 new routes added to `app_router.dart`:

| Path | Screen |
|---|---|
| `/insights` | `InsightsScreen` |
| `/insights/merchants` | `MerchantListScreen` |
| `/insights/merchants/:merchant` | `MerchantDetailScreen` |
| `/insights/categories` | `CategoryListScreen` |
| `/insights/categories/:category` | `CategoryDetailScreen` |

---

## Error handling

- **No patterns yet** (new user, Lambda hasn't run): all providers return null/empty. `RegretSummaryCard` renders nothing. Insights screen shows "Check back after your first week of tracking." placeholder.
- **Lambda failure**: stale data stays in place — `UpdatedAt` shows users when data was last refreshed. No user-facing error.
- **Merchant/category not found** on detail endpoint: API returns `404`, Flutter shows "No data found" and a back button.

---

## Testing

- Unit tests for `PurchasePatternService` (null/empty cases)
- Unit tests for aggregation logic in `PatternAggregatorLambda` (regret rate calculation, projection formula, SUMMARY derivation)
- Widget tests for `RegretSummaryCard` (null state = renders nothing, data state = correct text)
- Widget tests for `InsightsScreen` (loading, empty, populated states)
- Integration test for all 5 Insights endpoints
