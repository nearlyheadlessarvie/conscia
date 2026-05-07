# Counterparty Rename and Pre-Purchase Category Alignment

Date: 2026-05-07

## Summary

This change does two related things:

1. Replaces the transaction field currently modeled as `merchant` with a neutral `counterparty` name across app, API, domain, persistence, and tests.
2. Makes the UI label context-specific:
   - expense transactions show `Merchant`
   - income transactions show `Source`

It also improves `Pre-Purchase Assistant` so category selection follows the same interaction model as the transaction form instead of using a plain dropdown.

## Goals

- Keep transaction entry fast for both expense and income.
- Make the field wording feel natural in the UI.
- Remove semantic mismatch in the data model and database.
- Make pre-purchase category selection feel consistent with transaction entry.
- Hide the shared add-transaction FAB on Assistant and Settings across layouts.

## Non-Goals

- Changing the conceptual meaning of existing transaction data beyond the rename.
- Reworking the full pre-purchase layout beyond category interaction and related fit-and-finish needed for consistency.
- Making merchant/source mandatory.

## Design

### 1. Data Model Rename

The stored transaction field becomes `Counterparty`.

Affected layers:

- Flutter models and DTOs
- API request/response contracts
- application DTOs and validators
- domain `Transaction` entity
- domain `Location` model
- persistence mapping and repository serialization
- database column name
- tests and fixtures

The rename is semantic, not behavioral. Existing transaction values continue to mean “the other party involved in the transaction,” but the name now fits both expenses and income.

### 1a. Location Model Alignment

The location model should be cleaned up at the same time:

- `Location.MerchantName` becomes `Location.PlaceName`

This is intentionally different from `Counterparty`.

- `Counterparty` answers: who was the transaction with?
- `PlaceName` answers: where did it happen?

`PlaceName` is venue/place-oriented even when it differs from the counterparty.

Examples:

- expense at Starbucks:
  - `Counterparty = Starbucks`
  - `PlaceName = Starbucks BGC`
- salary received at home:
  - `Counterparty = ACME Corp`
  - `PlaceName = Home`
- freelance payment while at a coworking space:
  - `Counterparty = Client ABC`
  - `PlaceName = WeWork Makati`

This distinction keeps the model useful for location suggestions, recall, and future insights.

### 2. UI Wording

The transaction form becomes type-aware in copy only:

- expense: `Merchant`
- income: `Source`

The same input control is reused. Only the label, placeholder, and any nearby helper copy change.

If there are transaction-detail or editing surfaces that expose the label explicitly, they should use the same wording rule where practical. Generic list/history displays can simply show the saved value without adding a label.

### 3. Database Rename

The backing persistence column is renamed, not just aliased in code.

This includes:

- EF Core model update
- migration that renames the transaction table column from `Merchant` to `Counterparty`
- repository mapping updates so old and new data paths stay coherent during development

Because this is still local/dev-focused work, the migration can prioritize correctness and clarity over elaborate backward compatibility.

### 4. Pre-Purchase Category UX

`Pre-Purchase Assistant` should stop using the basic category dropdown and instead align with the transaction form’s category experience.

New interaction:

- show quick visible expense categories with icons
- keep a `More categories` entrypoint
- use the same expense category source as transaction entry
- allow location-based likely-category suggestions to prefill or override the current selection

This should make the assistant feel like a guided expense-intent flow instead of a disconnected form.

### 5. Field Mapping Rules

To reduce ambiguity:

- app-side `description` usage that currently mirrors `merchant` should be updated to reflect `counterparty`
- API payload keys should move to `counterparty`
- location payload keys and mappings should move from `merchantName` to `placeName`
- UI copy should remain contextual (`Merchant` / `Source`) and should not expose the raw `Counterparty` term to end users

### 6. Error Handling and Migration Safety

Expected risks:

- missed serialization paths still reading/writing `merchant`
- stale tests assuming `merchant`
- detail/history widgets still using expense-specific wording in income paths
- transaction deletion leaving stale budget usage in app state
- free-tier users seeing category choices they cannot actually use

Implementation should include focused regression coverage for:

- create/update transaction payloads
- transaction read mapping
- income form showing `Source`
- expense form showing `Merchant`
- pre-purchase category selection using the shared category interaction
- transaction create/update/delete immediately reconciling budget usage in dashboard and budgets/settings surfaces
- free-tier category UI only surfacing allowed categories unless the user is eligible for more

### 7. Budget Reconciliation on Transaction Mutation

Creating, updating, and deleting a transaction should update budget usage consistently in app surfaces that show budgets, including:

- dashboard budget summary
- budgets screen
- settings-linked budget management flows

This should be treated as part of the same implementation track because the `counterparty` rename will already touch transaction data plumbing.

Expected behavior:

- creating a budgeted expense adds its contribution to local budget state immediately, then reconciles with server truth afterward
- updating a transaction adjusts budget usage correctly for amount, category, and type changes
- deleting a budgeted expense removes its contribution from local budget state immediately, then reconciles with server truth afterward

### 8. Freemium Category Visibility

The free-tier category cap should be enforced in the UI, not only at submit time.

For free users:

- category selectors should only surface the allowed number of budget categories by default
- upgrade-only categories should be hidden or otherwise not presented as normal selectable options

This applies at minimum to category flows where the user would otherwise choose a category that the free tier cannot actually support. The UI should avoid teasing unavailable options when the restriction is known ahead of time.

### 9. Shell FAB Visibility

The shared add-transaction FAB should not appear on:

- Assistant
- Settings

This rule should apply consistently across:

- mobile layout (`floatingActionButton`)
- wide layout (`NavigationRail` leading action)

The visibility rule should live in `MainShell` and be route-based, so the shell remains the single source of truth for whether the add FAB is shown.

## Testing Strategy

- Flutter widget tests for transaction form label switching
- Flutter widget tests for pre-purchase category interaction
- Flutter service/model tests for `counterparty` payload mapping
- Flutter/provider tests for optimistic budget adjustment after transaction create, update, and delete
- Flutter widget/provider tests for free-tier category visibility rules
- Flutter widget tests for shell FAB visibility by route/layout
- backend unit/integration tests for transaction DTO/entity/repository mapping
- migration/build verification for renamed transaction column

## Recommended Implementation Split

1. UI-first wording fix:
   - transaction form label switches by type
   - pre-purchase category control aligns with transaction form

2. Full data-model rename:
   - app/API/domain/repository rename to `counterparty`
   - DB migration renames backing column

This keeps the user-facing improvement small and reviewable while still delivering the full semantic cleanup.
