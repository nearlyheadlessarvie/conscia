# Recurring Transactions Design

## Goal

Add recurring expense and income support that automatically creates real transactions on a weekly, monthly, or yearly cadence, with optional end dates, full backfill for missed runs, and lightweight in-app reminders after each generated occurrence.

## Scope

This v1 covers:

- separate recurring schedule entities for expenses and income
- weekly, monthly, and yearly cadences
- optional end date, otherwise open-ended
- automatic transaction generation on due dates
- full backfill if processing was missed for a period
- monthly schedules on the 29th, 30th, or 31st running on the last day of shorter months
- occurrence-level transaction editing without mutating the schedule
- separate explicit schedule editing flow deferred to later work
- in-app reminders after recurring occurrences are created

This v1 does not cover:

- custom intervals
- pause / resume UI beyond a simple active flag if needed internally
- “edit all future occurrences” from a generated transaction
- biometric or auth changes
- predictive recurring detection from transaction history

## Recommended Architecture

Use a dedicated recurring schedule entity and a backend generation workflow that creates normal transactions from due schedules. Transactions remain the source of truth for budgets, insights, and history. Recurring logic stays in schedule processing, not embedded in transaction reads.

This is a better fit than marking a normal transaction as recurring because:

- occurrences can diverge safely
- schedules can evolve later without corrupting history
- backfill logic stays explicit
- budgets and dashboard updates require no special-case read model

## Domain Model

Add a new recurring schedule entity, separate from `Transaction`.

Suggested fields:

- `Id`
- `UserId`
- `Type`
- `Amount`
- `CurrencyCode`
- `Category`
- `Counterparty`
- `StartDate`
- `Cadence`
- `NextRunAt`
- `EndDate` nullable
- `IsActive`
- `CreatedAt`
- `UpdatedAt`
- `LastGeneratedAt` nullable

Suggested enums:

- `RecurringCadence`
  - `Weekly`
  - `Monthly`
  - `Yearly`

Transaction linkage should be explicit. Generated transactions should store recurring provenance so the app can show a `Recurring` hint and future schedule-management flows can find the origin.

Suggested transaction metadata:

- `RecurringScheduleId` nullable
- `IsRecurringOccurrence` derived from the above, or explicit if preferred

## Scheduling Rules

### Weekly

Generate once per week using the original weekday anchored by `StartDate`.

### Monthly

Generate once per month using the original day-of-month from `StartDate`.

If the original day does not exist in a shorter month, use the last day of that month.

Examples:

- Jan 31 -> Feb 28/29 -> Mar 31
- Aug 30 -> Sep 30 -> Feb 28/29

### Yearly

Generate once per year using the original month/day from `StartDate`.

For leap-day-like edge cases, use the same “last valid day” principle.

### End Date

If `EndDate` is present, do not generate occurrences after that date.

### Backfill

If the generator was delayed or offline, create every missed occurrence in chronological order up to “now”. Do not skip to the latest only.

This preserves history and budget correctness.

## Generation Flow

Recurring schedules should be processed by a backend background workflow, not by the client.

Recommended flow:

1. load due active schedules
2. for each schedule, generate one or more missed occurrences up to current processing time
3. create a normal transaction for each due occurrence
4. mark recurring provenance on each created transaction
5. advance `NextRunAt` to the next future due point
6. record lightweight reminder/alert metadata for the user

The generation logic must be idempotent enough to avoid duplicate occurrences if the worker retries. The safest design is to persist enough schedule-run metadata or use deterministic duplicate checks around `RecurringScheduleId + occurrence date`.

## Editing Behavior

Editing a generated occurrence in v1 changes only that transaction.

It does not:

- rewrite past generated occurrences
- rewrite future generated occurrences
- mutate the schedule itself

Schedule editing is a separate future flow. That should later allow explicit actions like:

- change this schedule going forward
- stop this schedule
- update amount/category/counterparty for future runs

## Deletion Behavior

Deleting a generated occurrence in v1 deletes only that transaction occurrence.

It does not cancel the recurring schedule unless the user later uses a dedicated schedule management flow.

## API Surface

Add dedicated recurring schedule endpoints instead of overloading transaction endpoints.

Suggested endpoints:

- `POST /api/v1/recurring`
- `GET /api/v1/recurring`
- `GET /api/v1/recurring/{id}`
- `PUT /api/v1/recurring/{id}`
- `DELETE /api/v1/recurring/{id}`

Transaction endpoints should include recurring metadata in transaction detail/list responses so the app can label occurrences correctly.

Suggested transaction response additions:

- `recurringScheduleId`
- `isRecurring`

## UI Design

### Add Transaction

Add an optional recurring section to transaction creation:

- one toggle or affordance like `Make this recurring`
- cadence selector: weekly / monthly / yearly
- optional end date

This should live in the transaction form, not hidden behind a totally separate flow, because the schedule is usually created from a real transaction the user is entering.

### Transactions List / Detail

Generated occurrences should display a subtle recurring badge or note:

- `Recurring`
- or an icon + label

Transaction detail can also show:

- `Generated from recurring schedule`

without exposing full schedule editing in v1.

### Alerts / Reminders

After auto-creation, show an in-app alert/reminder like:

- `Recurring transaction added: Netflix`
- `Recurring income added: Salary`

This is informational. It does not block or require confirmation.

## Budget and Insight Behavior

Because recurring occurrences are stored as real transactions:

- computed budget usage automatically includes them
- transaction history stays accurate
- dashboard and insights work without separate recurring math

This is one of the main reasons to auto-create real transactions instead of just reminders.

## Error Handling

If a schedule fails to generate:

- keep the schedule active unless the failure proves it is invalid
- log the error with schedule context
- retry in the next processing cycle

If one occurrence generation fails, it should not block unrelated schedules from being processed.

If schedule data becomes invalid, the system should prefer marking it inactive and surfacing that in future admin/debug flows rather than generating corrupted transactions.

## Testing Strategy

### Backend

Add unit tests for:

- weekly cadence calculation
- monthly cadence calculation including short months
- yearly cadence calculation
- backfill of multiple missed occurrences
- end-date cutoff behavior
- occurrence editing not mutating schedule behavior
- duplicate prevention / idempotency behavior

Add endpoint tests for:

- create recurring schedule
- list/get/update/delete recurring schedule
- recurring metadata appearing on generated transaction responses

### App

Add widget/provider tests for:

- recurring toggle and cadence controls on Add Transaction
- optional end date flow
- recurring badge on transactions
- reminder alert surfacing after a generated occurrence appears

## Rollout Notes

This feature depends on stable background processing and clear transaction provenance. It should be delivered as a focused backend + app slice before broader future work like:

- editing schedules going forward
- pausing schedules
- detecting recurring items automatically
- upcoming recurring summaries on dashboard

## Recommendation

Build recurring transactions as a first-class schedule system that auto-posts real transactions and backfills missed occurrences. Keep v1 tight: fixed cadence options, optional end date, occurrence-only editing, and in-app reminders after generation.
