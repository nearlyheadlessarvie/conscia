# Weekly Digest Push Design

## Goal

Ship a push-only weekly digest that summarizes the user’s week in spending behavior, deep-links into the existing `Insights` screen, and highlights a `This week` summary there without introducing a permanent main-shell Insights destination.

## Why

The product already has meaningful behavioral and reflection data, but it does not yet close the loop with a scheduled, habit-forming summary. A weekly digest is the lightest recurring mechanism to remind users what happened, reinforce progress, and bring them back into the app with context.

The design should avoid two common mistakes:

- creating a separate dead-end digest screen that duplicates analytics
- adding a permanent `Insights` tab before the user has enough data for it to be useful

## Product Direction

### Digest delivery

- Push notifications only for MVP
- No email
- One scheduled digest per user at the user’s chosen local weekly time
- If the user has insufficient weekly data, send a lighter fallback summary instead of a full silence-first strategy

### Notification tap behavior

- Tapping the weekly digest push should open the existing `Insights` screen
- The `Insights` screen should render a highlighted `This week` summary block at the top when opened from digest context
- If digest preview data fails to load after tap, the screen should still open and degrade gracefully to the normal Insights experience with a non-blocking error state

### Insights navigation

- `Insights` must not be a fixed main-shell destination
- `Insights` should be reachable from `Dashboard/Home`, similar to how users navigate into `Transactions`
- The dashboard entry point should appear only when `InsightsSummary` is non-empty
- Weekly digest pushes should deep-link into that same screen even though it is not part of the permanent shell

## User Experience

### Notification content

The push body should feel useful on its own, not like a generic reminder. It should summarize:

- top category or dominant spending area
- one strongest positive or cautionary signal
- one short momentum line such as a streak or behavior trend when available

Example shape:

```text
Your weekly digest
Dining led your week. Reflection improved, but late-night spending trended up.
```

For low-data users, fallback copy should stay honest and lightweight:

```text
Your weekly digest
You logged a few decisions this week. Open Insights to see the early pattern.
```

### Dashboard entry point

When `InsightsSummary` is non-empty, Dashboard/Home should show an `Insights` entry point. It can be a button, card action, or compact route row, but it should read as a drill-in rather than a core shell destination.

When `InsightsSummary` is empty, the entry point should not render at all.

### Insights screen behavior

When opened normally from Dashboard:
- render the existing Insights experience

When opened from weekly digest push or preview:
- render a pinned `This week` summary at the top
- keep the rest of the screen as the existing analytics stack
- avoid a separate digest route, modal, or temporary surface

## MVP Scope

### In scope

- backend weekly digest generation service
- backend digest preview endpoint
- per-user weekly digest preferences
- per-user push token registration/sync
- push-only weekly digest delivery
- app-side push registration and notification tap handling
- `Insights` deep-link behavior for digest notifications
- dashboard entry point to `Insights` only when `InsightsSummary` is non-empty
- highlighted `This week` summary block inside `Insights`

### Out of scope

- email digests
- dedicated digest history screen
- persistent digest archive table
- a permanent main-shell Insights tab
- advanced multi-variant notification copy experiments
- marketing automation or cross-channel campaigns

## Recommended Technical Approach

## Backend

Add a `WeeklyDigestService` that composes one digest payload from the insight and reflection data we already have or can already derive. The service should own content assembly, not delivery.

Add a separate push transport service for FCM so digest generation can be tested independently from notification sending.

Add a preview endpoint:

- `GET /api/v1/digest/preview`

This endpoint should return the same digest payload shape used for push deep-link rendering in the app.

Add a scheduled job or Lambda path that:

- selects users due for weekly delivery
- skips users without push tokens or with digest disabled
- generates the digest payload
- sends a `weekly_digest` push notification
- logs failures without aborting the entire batch

## Data model

Add user-level fields or an adjacent preference/push settings store for:

- weekly digest enabled flag
- preferred weekday
- preferred local send time
- timezone
- current push token or push token collection

Do not create a dedicated persisted weekly digest record for MVP. The digest should be generated on demand for preview and at send time for delivery. If auditing or replay becomes necessary later, that can be added as a follow-up.

## App

Add push notification registration and token sync.

Handle a `weekly_digest` notification type.

On tap:
- route into `Insights`
- pass navigation state indicating digest context
- request the preview payload so `Insights` can render the highlighted `This week` block

Add a weekly digest preference control in Settings for:

- enabled / disabled
- weekday
- time

Add a preview affordance so the feature can be tested without waiting for the scheduled send.

## Digest payload shape

The app and backend should share one clear view model for the digest preview surface. The payload should be concise and map directly onto the highlighted block in `Insights`.

Recommended fields:

- `title`
- `summary`
- `topCategory`
- `topCategoryAmount`
- `signalLabel`
- `signalValue`
- `momentumLabel`
- `momentumValue`
- `isFallback`
- `periodStart`
- `periodEnd`

This shape is intentionally compact. It should not try to serialize the entire Insights screen.

## Navigation and visibility rules

### Insights entry visibility

Dashboard/Home should decide whether to render the `Insights` entry point using the existing `InsightsSummary` contract:

- show entry point when `InsightsSummary` is non-empty
- hide entry point when `InsightsSummary` is empty

This is the only visibility rule for MVP. No extra thresholding or heuristic should be added.

### Deep linking

Notification tap should target the same `Insights` route used by Dashboard/Home.

The route should accept a small navigation flag such as `source=weekly_digest` or equivalent app route state so the screen knows to:

- fetch digest preview
- render the highlighted `This week` module first

If route state is absent, `Insights` behaves like a normal screen open.

## Error handling

### Backend

- No push token: skip user
- Weekly digest disabled: skip user
- Digest generation failure for one user: log and continue batch
- FCM send failure: log and continue batch
- Missing optional data: build fallback digest rather than failing hard

### App

- Notification tap with failed preview fetch: open `Insights` normally and show a small non-blocking error or missing-summary state
- Invalid route state: ignore digest mode and render standard `Insights`
- Push registration failure: do not block app usage; just keep digest delivery unavailable until token registration succeeds later

## Testing Strategy

### Backend tests

- unit tests for digest content generation
- unit tests for fallback digest generation when data is sparse
- endpoint test for `GET /api/v1/digest/preview`
- delivery job tests for user filtering and error isolation

### App tests

- push deep-link routing test into `Insights`
- widget tests for conditional dashboard `Insights` entry visibility based on non-empty `InsightsSummary`
- widget tests for highlighted `This week` summary rendering in digest mode
- widget or service tests for digest preview failure fallback

### Manual verification

- generate preview in-app without waiting for schedule
- trigger a test push and confirm notification tap lands in `Insights`
- confirm `Insights` is not in the permanent main shell
- confirm dashboard hides the `Insights` entry when `InsightsSummary` is empty

## Success Criteria

- Users can enable weekly digest push notifications and choose a weekly send time
- The backend can generate digest content and expose it through a preview endpoint
- The app can register push tokens and receive a `weekly_digest` push
- Tapping the push opens `Insights` with a highlighted `This week` summary
- `Insights` is accessible from Dashboard/Home only when `InsightsSummary` is non-empty
- `Insights` is not added as a permanent main-shell destination

## Risks

### Duplicate analytics logic

If digest generation rebuilds too much of the Insights stack from scratch, it will drift from the product’s main analytics surfaces. The mitigation is to compose from existing insight sources and keep the digest payload intentionally small.

### Empty or weak digest content

Low-data users may receive a digest that feels hollow. The mitigation is explicit fallback copy and a lightweight summary mode instead of pretending there is richer analysis than the data supports.

### Notification dead-end

If the push lands users in a special-purpose surface with nowhere useful to go, the feature will feel thin. The mitigation is deep-linking into the existing `Insights` screen and using only a pinned summary module, not a separate digest page.
