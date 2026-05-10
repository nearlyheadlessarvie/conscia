# Budget Trends Projection Design

Date: 2026-05-10
Branch context: `feature/weekly-digest-push`

## Goal

Add a durable server-side projection for monthly category spending so Conscia can show lightweight budget and spend trends in Insights without recomputing full multi-month transaction history on every read.

This design intentionally separates:

- current budget source of truth
- historical trend projection
- optional caching

The main product outcome is a new Insights experience that shows `last 3 months` of category trends for all spending categories, with stronger budget-aware metrics when a category has a budget.

## Product Behavior

### Trend card

Add a new Insights card for budget and spending trends.

The card should:

- show up to 3 categories
- cover the last 3 months including the current month
- include both budgeted and unbudgeted spending categories
- prioritize categories with the strongest signal

Signal priority:

1. largest recent spend categories
2. categories with meaningful month-over-month movement
3. categories that are over or near budget when a budget exists

### Budgeted categories

For categories that have a budget in a given month:

- primary metric: percent of budget used for each of the last 3 months
- optional secondary metric: currency spend for the current month

Example:

- `Dining: 74% -> 61% -> 58%`

### Unbudgeted categories

For categories without a budget:

- primary metric: raw spend trend for the last 3 months
- show a small nudge that a budget would make the insight more meaningful

Example:

- `Subscriptions: PHP1,200 -> PHP1,150 -> PHP1,100`
- helper text: `Add a budget for sharper insights`

### Insight framing

This feature is not limited to strict “budgeting” users. It should provide useful numeric trend context even when users have not fully configured budgets yet.

## Architectural Decision

### Chosen approach

Use a hybrid design:

- keep current budget status logic as the user-facing source for current-month budget views for now
- introduce an outbox-backed monthly projection for historical category totals
- use that projection to power the new 3-month Insights card

This is intentionally narrower than restoring the old outbox design wholesale.

The outbox pipeline will have one explicit purpose:

- maintain monthly spending aggregates per user and category

It will not be reintroduced as a generic placeholder background processor.

### Why this approach

Benefits:

- cheap reads for Insights
- reusable projection for future weekly digest and AI budget context improvements
- safer than storing mutable `currentSpend` on budget rows
- avoids repeated 3-month transaction scans for every insights request

Tradeoff:

- adds event processing and projection maintenance complexity

This tradeoff is acceptable because multi-month trend reads are a good fit for a projection model.

## Data Model

### Existing budget model

The `Budget` entity remains minimal:

- category
- monthly limit
- currency

We do not reintroduce stored mutable current spend onto the budget row.

### New projection table

Add a new DynamoDB table for monthly category spending aggregates.

Suggested name:

- `MonthlyCategorySpends`

Purpose:

- one row per user, category, month

Suggested shape:

- `PK = USER#{userId}`
- `SK = MONTH#{yyyy-MM}#CAT#{normalizedCategory}`

Suggested attributes:

- `UserId`
- `MonthKey`
- `Category`
- `NormalizedCategory`
- `CurrencyCode`
- `TotalExpenseAmount`
- `TransactionCount`
- `LastUpdatedAt`

Optional future-safe fields:

- `RegretCount`
- `WorthItCount`

Those optional fields are not required for the first implementation, but the key design should not block them.

## Event Model

### Outbox purpose

Restore the transaction outbox path only for projection maintenance.

The outbox should emit events for:

- transaction created
- transaction updated
- transaction deleted

Only expense transactions should affect the monthly category spend projection.

### Payload requirements

Each projection-impacting event must contain enough information to upsert or reverse monthly totals safely.

Required payload fields:

- transaction id
- user id
- type
- category
- amount
- currency code
- transaction date

For updates, the processor must know both old and new values when a projection-relevant field changes.

That means update events should carry:

- previous category
- previous amount
- previous date
- previous type
- new category
- new amount
- new date
- new type

This avoids needing projection logic to reread the full transaction record to compute deltas.

## Processing Rules

### Transaction created

If transaction type is `Expense`:

- increment the matching monthly category aggregate

If not expense:

- do nothing

### Transaction deleted

If deleted transaction type was `Expense`:

- decrement the matching monthly category aggregate

If not expense:

- do nothing

### Transaction updated

Handle updates as a two-step delta:

1. subtract old expense impact if the previous transaction qualified
2. add new expense impact if the new transaction qualifies

This correctly handles:

- category changes
- amount changes
- date/month changes
- expense <-> income flips

### Idempotency

Projection processing must be idempotent.

The processor must avoid double-applying the same event.

The simplest acceptable approach is:

- keep the existing outbox claim/start-processing semantics
- only mark processed after the projection write succeeds

## Read Model for Insights

### Query behavior

Insights should read the last 3 months of category projections for the active user.

The server should:

1. load relevant monthly category spend rows for the last 3 months
2. load current budgets for the user
3. join category trend rows against budgets by normalized category
4. shape the response into:
   - budget-backed percent trend when a budget exists
   - raw spend trend when no budget exists

### Budget-aware trend calculation

For each month/category pair:

- if budget exists, compute percent used as `monthSpend / monthlyLimit`
- if no budget exists, expose spend amount only

Assumption:

- current budget configuration is used as the comparison anchor for the card unless monthly historical budget snapshots are later introduced

This means:

- historical percent trends are based on the current category budget limit, not a stored historical monthly budget limit

That is acceptable for the first version because:

- it keeps implementation smaller
- it still gives users useful numeric trend direction

If historical monthly budget snapshots become important later, that can be added as a follow-up.

## Caching Strategy

### Recommendation

Do not introduce Redis in the first version.

Reasons:

- projection rows already reduce the most expensive repeated computation
- Redis adds infra cost and operational surface area
- current scale does not justify a distributed cache before validating the projection read path

### If caching is needed

If profiling later shows hot repeated reads for the same user insights payload:

- add short-lived server-side in-process cache first
- likely TTL: 30 to 120 seconds

Only consider Redis when:

- multiple API instances produce enough cache duplication pain
- insights/budget reads are demonstrably hot enough to justify shared cache infra

### Device-local caching

Do not use device-local cache as the primary backend cost solution.

It may still be useful for app UI smoothness, but it does not solve:

- backend alert evaluation
- server-side AI budget context
- cross-device correctness
- multi-client consistency

## API Shape

### Existing insights payload

Extend the insights response with a budget trends section rather than creating a completely separate endpoint.

Suggested response addition:

- `budgetTrends`

Suggested item shape:

- `category`
- `hasBudget`
- `currencyCode`
- `months`
  - ordered oldest -> newest across 3 months
- `currentMonthSpend`
- `currentMonthPercentUsed` when budgeted
- `insightLabel`
- `nudge`

Example item:

- category: `Dining`
- hasBudget: `true`
- months: `[58, 61, 74]`
- insightLabel: `Budget usage trending up`

For unbudgeted categories:

- months should carry spend amounts rather than percentages
- nudge text should indicate a budget would improve the insight

## Ranking Logic

To keep the card readable, rank categories as follows:

1. categories over budget or above 80 percent usage
2. categories with largest month-over-month increase
3. highest spend unbudgeted categories

Cap the card at 3 categories.

This avoids a noisy “show everything” card while still including unbudgeted behavior.

## Failure Handling

### Projection lag

If outbox processing lags:

- budget trend insights may be slightly stale
- current app behavior should fail soft, not hard

Fallback:

- if projection rows are missing, omit the trend card rather than erroring the full insights response

### Negative aggregates

If a delete/update reversal would cause a negative spend total:

- clamp to zero
- log a warning with user, category, month, and event id

This prevents corrupted display values while preserving observability.

## Drift Prevention And Reconciliation

Projection drift should be treated as an expected operational risk, not as an impossible state.

The design must support:

- preventing drift where practical
- detecting drift when it happens
- repairing drift from source transactions

### Prevention

The projection pipeline should reduce drift risk with:

- idempotent event handling
- delta-based update processing for transaction edits
- deterministic month and category normalization
- marking outbox events processed only after projection writes succeed

For transaction updates specifically:

- subtract the old expense impact first
- add the new expense impact second

This keeps category changes, amount changes, and month moves balanced.

### Detection

Add explicit drift detection through periodic reconciliation.

Recommended reconciliation scope:

- rolling last 3 months for all active users
- or rolling last 6 months if operationally acceptable

The reconciliation job should:

1. recompute monthly category totals from source transactions
2. compare them against `MonthlyCategorySpends`
3. log mismatches with user, category, month, and expected vs actual values
4. emit a metric for projection drift count

### Repair

The projection must be rebuildable from raw transactions.

If reconciliation finds a mismatch:

- overwrite the projection row with the recomputed source-of-truth value
- log that an automatic repair occurred

If an entire month or user slice is missing:

- regenerate the missing rows from transactions rather than failing the Insights experience

### Operational posture

Drift handling should follow this priority order:

1. source transactions are truth
2. projection is disposable and repairable
3. Insights should fail soft if projection data is temporarily inconsistent

This keeps the projection useful without making it a fragile hidden source of truth.

## Testing

### Unit tests

Add tests for:

- transaction created updates monthly category spend projection
- transaction deleted reverses projection
- transaction updated moves spend across category/month correctly
- income transactions do not affect projection
- insights join budgeted and unbudgeted categories correctly
- unbudgeted categories include the budget nudge text

### Integration tests

Add integration coverage for:

- insights response includes 3-month trend rows
- missing projection data does not fail the endpoint

### Regression coverage

Protect against:

- double-processing the same outbox event
- month boundary misclassification
- category normalization mismatches between budget rows and transaction rows
- reconciliation false positives from inconsistent normalization
- repair logic failing to restore the correct aggregate after mismatch

## Non-Goals

Not part of this feature:

- historical monthly budget limit snapshots
- Redis or ElastiCache introduction
- device-local cache strategy
- making budget aggregates the sole source for all current-month budget UI immediately

Those can be added later if profiling or product needs justify them.

## Success Criteria

This design is successful when:

- insights can show last-3-month category trends for all spending categories
- budgeted categories show percent-used trends
- unbudgeted categories still appear with a budget nudge
- reads do not require recomputing 3 full months of transactions per request
- outbox processing is purposeful and limited to projection maintenance
