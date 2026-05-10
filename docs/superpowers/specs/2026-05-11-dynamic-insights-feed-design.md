# Dynamic Insights Feed Design

## Goal

Turn the current static dashboard insight stack into a curated, dismissible insight feed, and evolve the Insights screen from a regret-pattern-only view into a broader financial insight surface.

The first implementation should stay app-composed from existing backend data. It should not introduce a new persisted insight-card table yet.

## Current State

- Dashboard renders a fixed stack from `/insights/behavioral`: mood, worth-it count, budget trends, impulse trends, and regret summary.
- Dashboard cards do not have dismissal or freshness behavior.
- The Insights screen is currently titled around regret patterns and uses `/insights/summary`, `/insights/categories`, and `/insights/merchants`.
- Story-demo now seeds current-week and previous-week `WeeklyInsights`, budget trends, regret patterns, alerts, budgets, and transactions.
- Mascot sprites are already available through `MascotSpriteFrame` and the existing angel/devil/money sprite-sheet atlas definitions.

## Product Shape

Dashboard should show only the most useful few insights. It should feel like Conscia is surfacing the top things worth noticing today, not dumping every metric card permanently.

Insights should become the durable detail surface. It should preserve the strong regret-pattern work while also showing weekly behavior, budget trends, and recent signals.

## Data Sources

The first pass composes cards in Flutter from existing providers:

- `behavioralInsightsProvider`
  - weekly financial mood
  - worth-it percentage and count
  - previous-week worth-it count
  - impulse trends
  - budget trends
- `insightsSummaryProvider`
  - regretted amount
  - regretted category
  - average regret rate
  - pattern count
  - updated timestamp
- `insightsCategoriesProvider`
  - regret-heavy category trends
- `insightsMerchantsProvider`
  - merchant spotlight signals
- `userPreferencesProvider`
  - currency and locale formatting

No backend endpoint changes are required for the first implementation unless tests reveal an existing payload mismatch.

## Insight Feed Model

Add an app-side `InsightFeedItem` model with enough structure for dashboard curation and Insights-screen rendering.

Fields:

- `id`: stable dismissal key, such as `weekly-mood:2026-05-11`, `budget-trend:subscriptions:2026-05`, or `regret-summary:shopping`.
- `kind`: mood, worth-it, budget-trend, impulse-trend, regret-summary, merchant-pattern, category-pattern.
- `priority`: integer used for dashboard ordering.
- `title`: short card headline.
- `body`: one to two lines of explanation.
- `metric`: optional highlighted value.
- `caption`: optional small supporting line.
- `route`: optional route to open on tap.
- `section`: target Insights section to highlight when routing.
- `mascot`: none, angel, devil, or both.
- `tone`: positive, warning, reflective, or neutral.
- `expiresKey`: stable time key used for dismissals.
- `dismissible`: true for dashboard cards.

The feed provider should be deterministic. The same source data should produce the same IDs and ordering.

## Dashboard Behavior

Dashboard `Your Insights` should render a compact feed:

- Show at most three active insight cards.
- Hide cards whose `id` is locally dismissed.
- Dismissal should persist locally until the card identity changes.
- Store dismissed card IDs in `SharedPreferences`, using the existing app preference pattern.
- If all insight cards are dismissed, hide the dashboard `Your Insights` section.
- Pull-to-refresh should recompute the feed but should not revive dismissed cards with the same IDs.

Dashboard priority:

1. Budget trend warning or unbudgeted high-spend nudge.
2. Regret summary or regret-heavy category pattern.
3. Impulse trend that is worsening.
4. Weekly mood summary.
5. Worth-it improvement.
6. Merchant pattern.

## Insights Screen Behavior

Rename the page from regret-only framing to a broader Insights surface.

Sections:

- `This week`: mood, worth-it percentage/count, previous-week comparison, and a mascot-backed readout.
- `Budget trends`: last-three-month spend or budget usage rows, including unbudgeted categories with a light nudge.
- `Regret patterns`: keep the current summary, merchant spotlight, and category/category-detail links.
- `Recent signals`: feed-style list of all generated insight cards, including cards hidden from dashboard by the max-three limit.

The screen should remain useful if only some providers return data. Missing sections should collapse independently rather than failing the entire page.

## Mascot Rules

Mascots should act as commentary, not wallpaper.

- Angel appears on protective or encouraging cards: budget staying safe, worth-it improvement, balanced/confident mood.
- Devil appears on temptation or risk cards: worsening impulse trend, regret pattern, unbudgeted category creep.
- Both appear on contested cards: budget usage rising, mixed weekly mood, tension between spending and saving.
- Use compact cameos on dashboard cards.
- Use larger but still restrained story placements on the Insights screen.
- Use existing sprite-sheet frames:
  - Angel: `1_neutral.png`, `4_win.png`, `8_shield.png`, `11_focuspray.png`, `15_numberone.png`.
  - Devil: `1_neutral.png`, `8_whisper.png`, `9_coin.png`, `14_frustrated.png`.

## Routing

Dashboard cards should navigate to `/insights`.

Do not add section scrolling or route extras in this pass. The expanded Insights screen should make the destination obvious enough without deep-link state.

## Story Demo Expectations

The `story-demo` profile should show:

- Dashboard: two or three insight cards, not the old full static stack.
- Dashboard: at least one mascot-backed card.
- Dashboard: at least one dismissible card.
- Insights screen: populated `This week`, `Budget trends`, `Regret patterns`, and `Recent signals` sections.
- Weekly data: current-week and previous-week comparison should be visible.
- Budget data: Subscriptions remains unbudgeted and should produce a nudge-flavored trend.

## Testing

Add or update Flutter tests for:

- Feed provider creates stable IDs from story-shaped data.
- Dashboard shows at most three active insight cards.
- Dashboard dismissal hides a card without removing source data.
- Dashboard keeps dismissed cards hidden after provider refresh when IDs do not change.
- Insights screen renders weekly, budget, regret, and recent-signal sections when data is present.
- Mascot card chooses angel/devil/both for at least the major insight tones.

Keep backend tests limited to existing story-demo seed invariants unless backend payload changes become necessary.

## Non-Goals

- Do not add a backend `InsightCard` persistence model in this pass.
- Do not add push/email weekly digest delivery in this pass.
- Do not add a permanent Insights tab to the main shell.
- Do not rebuild the entire dashboard layout outside the `Your Insights` section.
- Do not make mascot art mandatory for every card.

## Open Implementation Notes

- Prefer a focused provider that composes source providers into feed items.
- Keep existing regret-pattern widgets reusable inside the expanded Insights screen.
- Use `SharedPreferences` for dismissal persistence through the existing app preference provider pattern.
- Generated Freezed files should only be regenerated if the model changes require it.
