# Story Demo Seed Design

Date: 2026-05-10
Branch context: `feature/weekly-digest-push`

## Goal

Add a dedicated local seed profile that creates one coherent, visually rich demo account for emulator walkthroughs.

This seed is meant for:

- checking implemented features visually in the Flutter app
- validating cross-screen flows with realistic linked data
- giving a stable local “known good” state after Docker resets

It is not meant to replace the default lightweight local seed.

## Chosen Approach

Use a named `story-demo` profile inside the existing `tools/Seeder` project.

Example invocation:

```bash
dotnet run --project tools/Seeder -- story-demo
```

Why this approach:

- keeps one seeding entrypoint
- avoids adding a second tool to maintain
- makes the rich visual seed opt-in
- preserves the default seeding path for ordinary local development

## Scope

### In scope

The `story-demo` profile should seed one curated user story with enough connected data to light up the most visible shipped features:

- dashboard
- budgets
- recent transactions
- reflection prompts
- in-app alerts
- behavioral insights
- budget trends insights
- purchase patterns
- assistant/pre-purchase context
- recurring schedules

### Out of scope

Not part of the first version:

- onboarding-first empty account demo
- multiple demo personas
- in-app debug seed trigger
- screenshot/export tooling
- production-safe seed behavior

## Seed Strategy

### Dedicated demo identity

The seed should create one dedicated demo account rather than mixing story data into generic seeded users.

Suggested identity:

- email: `story-demo@example.com`
- password: `password123`
- tier: premium
- locale: `en_PH`
- currency: `PHP`

This makes the visual walkthrough deterministic and easy to log into.

### Safe reruns

The `story-demo` profile should be rerunnable.

Preferred behavior:

- locate the dedicated demo user
- clear and replace that user’s related seeded data
- leave other seeded users untouched

This keeps the workflow safe when you reseed during UI checks.

## Product Story

The demo user should feel like a real person with an active but slightly messy spending life.

Suggested narrative:

- has a few healthy budget habits already
- uses subscriptions and dining frequently
- sometimes reflects on purchases
- has enough repeated merchants/categories to generate insights
- has one meaningful “missing budget” category so the dashboard nudge flow appears

The story should feel believable rather than “seeded for coverage.”

## Required Visual States

### Dashboard

The dashboard should show:

- visible budgets with mixed pacing
- at least one active `budget_nudge` alert
- at least one reflection prompt card
- a populated recent transactions section
- behavioral insights
- budget trends card with both:
  - one budgeted category
  - one unbudgeted category with the budget nudge copy

### Budgets

The budgets screen should show:

- 2 to 4 active budgets
- clearly different utilization states
  - one low usage
  - one medium usage
  - one near-limit or over-warning range
- at least one common spending category not yet budgeted so the dashboard CTA has a reason to exist

### Transactions

The transaction list and detail screens should include:

- varied categories
- recognizable counterparties
- enough recent history for grouping and list depth
- a mix of regret states:
  - worth it
  - regret
  - not sure
  - unset for pending reflection

### Insights

Insights should be non-empty and visually meaningful.

The seed should produce:

- behavioral mood data
- impulse trends
- merchant/category pattern data
- budget trends over the last 3 months

### Assistant / Reflection

The seeded data should support:

- realistic category suggestions and context when testing the pre-purchase screen
- at least one existing transaction suitable for reflection follow-up

### Recurring

Include at least one recurring schedule so the seeded account reflects the recurring feature’s existence.

Suggested examples:

- subscription
- monthly utility or bill

## Data Shape

### Time range

Seed approximately 3 months of transaction history for the demo user.

This is enough to support:

- budget trends
- purchase patterns
- merchant/category summaries
- visible recent activity

### Transaction mix

Use mostly expense transactions, with a small number of income items.

Suggested categories:

- Dining
- Subscriptions
- Bills
- Shopping
- Transportation
- Gift or Other

Suggested counterparties:

- Netflix
- Spotify
- Grab
- Starbucks
- OpenAI
- Meralco
- Globe
- Local groceries or cafes

### Budgets

Seed budgets for a subset of the spending categories only.

Recommended:

- Dining
- Bills
- Shopping

Do not seed a budget for `Subscriptions`, so the budget nudge flow has a stable reason to appear.

### Insights support rows

Because the app already depends on persisted insights/pattern data in places, the seed should create any required supporting rows directly instead of assuming background jobs will generate them.

That includes:

- weekly insights rows
- purchase pattern rows if needed by the current insights screens
- monthly category spend projection rows for budget trends

The seed should not rely on waiting for background processors to make the demo usable.

## Operational Rules

### Explicit mode selection

`story-demo` should run only when explicitly requested.

Default `tools/Seeder` execution should remain lightweight and unchanged unless a separate cleanup decision is made later.

### Clear console output

The seeder should print:

- which profile is running
- which demo user was created or refreshed
- which major datasets were seeded

This helps quickly confirm whether the emulator should be showing the expected story state.

## Success Criteria

This design is successful when:

- running `tools/Seeder -- story-demo` creates a dedicated demo account
- the account can be opened in the emulator and immediately shows meaningful cross-screen data
- dashboard, budgets, transactions, and insights all look intentionally populated
- the budget nudge flow is visibly testable
- the seed can be rerun without corrupting or duplicating the demo story

