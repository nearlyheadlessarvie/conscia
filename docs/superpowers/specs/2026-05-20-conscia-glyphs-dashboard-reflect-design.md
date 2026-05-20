# Conscia Glyphs And Dashboard Reflect Facelift Design

## Summary

Conscia will continue the custom glyph system as a modular, app-wide icon language while simultaneously upgrading the dashboard `Reflect` section from a simple prompt row into a richer editorial checkpoint.

This pass is intentionally narrow:

- strengthen the glyph foundation and curated v1 set
- use that stronger visual language in the dashboard where it clearly helps
- redesign `Reflect` into a featured card with one active reflection moment and a subtle sense of queue

The goal is to make the dashboard feel calmer, more intentional, and more ownable without turning this into a full dashboard rewrite.

## Goals

- Continue the Conscia custom glyph system from its current monolithic implementation toward the approved modular architecture.
- Keep `ConsciaGlyph` as the single public widget API.
- Introduce the curated v1 glyph set and semantic Conscia fallback behavior.
- Redesign the dashboard `Reflect` section into a richer editorial card.
- Add a gentle subtitle to the section so the prompt feels guided rather than transactional.
- Present one featured reflection moment while subtly hinting at additional queued moments.
- Land small, high-confidence dashboard wins rather than attempting a full visual overhaul.

## Non-Goals

- Replacing every icon in the app in one pass.
- Rebuilding the budgets section or recent transactions section as part of this work.
- Turning the reflect area into a fully browsable feed or multi-card workflow.
- Reworking the underlying reflection interaction model or the three reflection outcomes.
- Converting the glyph system to an SVG or asset-based pipeline.

## Current State

### Glyphs

The app already has a custom `ConsciaGlyph` system in `app/lib/widgets/conscia_glyph.dart`. It combines:

- glyph enum
- string normalization
- category and quest mapping
- painter dispatch
- all drawing methods

into a single file.

That is workable at the current size, but it will become fragile if we expand it app-wide without splitting responsibilities.

### Reflect Section

The dashboard currently renders reflection prompts using `RegretPromptCard` in:

- `app/lib/screens/dashboard/widgets/regret_prompt_card.dart`

The section behavior today is:

- a section title with no real editorial framing
- up to three prompts in a horizontally scrollable row
- each prompt is presented as a compact card
- swiping left/right shortcuts the worth-it/regret responses
- the three feeling buttons already exist and should stay

This works functionally, but it feels more like triage than guided reflection.

## Recommended Approach

Use a combined two-part approach:

1. continue the glyph system as a modular internal refactor plus curated v1 expansion
2. redesign the dashboard `Reflect` surface into a featured editorial reflection checkpoint that consumes the stronger glyph language where it is ready

This keeps the work coherent:

- the glyph work becomes useful immediately
- the dashboard facelift stays focused
- neither part needs to overreach to justify the other

## Part 1: Glyph Continuation

### Public API

The public API remains stable:

- `ConsciaGlyph(kind: ...)`
- `ConsciaGlyph.category(...)`
- `ConsciaGlyph.quest(...)`
- `ConsciaGlyph.milestone(...)`
- `ConsciaGlyph.level(...)`

No app call site should need to understand painter groups or internal file layout.

### Internal Architecture

The glyph implementation should move toward the modular structure already agreed:

- `app/lib/widgets/glyphs/conscia_glyph_kind.dart`
- `app/lib/widgets/glyphs/conscia_glyph_mapper.dart`
- `app/lib/widgets/glyphs/conscia_glyph.dart`
- `app/lib/widgets/glyphs/painters/glyph_painter_primitives.dart`
- `app/lib/widgets/glyphs/painters/journey_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/money_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/category_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/utility_glyph_painter.dart`

Responsibilities:

- kinds live in the enum file only
- mapping and fallback decisions live in the mapper
- widget sizing and painter dispatch live in the public glyph widget
- drawing code is grouped by domain

### Curated V1 Glyph Set

This pass should support the approved v1 set:

#### Journey

- `trail`
- `reflect`
- `pause`
- `insight`
- `signal`
- `shield`
- `family`
- `recurring`
- `trophy`
- `lock`
- `sprout`
- `compass`
- `crown`
- `monk`

#### Money

- `wallet`
- `card`
- `cash`
- `bank`
- `transfer`
- `refund`
- `fee`
- `debt`
- `savings`
- `income`

#### Utility

- `calendar`
- `alert`
- `check`
- `bills`
- `home`
- `gift`

#### Category Core

- `dining`
- `coffee`
- `groceries`
- `transport`
- `shopping`
- `health`
- `entertainment`
- `education`
- `travel`
- `subscription`

#### Income And Work

- `salary`
- `freelance`
- `business`
- `investment`
- `rentalIncome`
- `bonus`

### Fallback Strategy

Normal product UI should not visibly fall back to platform icons where `ConsciaGlyph` owns the icon.

Unsupported concepts should map to a custom semantic fallback family:

- `more`
- `trail`
- `receipt`
- `signal`
- `wallet`

Fallback selection should stay semantic:

- finance -> `wallet`
- record/item -> `receipt`
- progress/journey -> `trail`
- alert/attention -> `signal`
- generic catch-all -> `more`

### Dashboard-Relevant Glyph Priority

For this dashboard pass, the most important glyphs to stabilize are:

- `reflect`
- `trail`
- `receipt`
- `signal`
- `wallet`
- category glyphs used in the reflection prompt badge context

That lets the dashboard facelift benefit from the improved glyph language without waiting for total app-wide adoption.

## Part 2: Reflect Facelift

### UX Intent

`Reflect` should feel like a calm editorial checkpoint, not a utility strip.

The section should communicate:

- this is a meaningful pause
- there is one main moment to consider now
- there are more moments waiting, but they are not demanding attention all at once

### Structure

The updated section should contain:

- section title: `Reflect`
- a gentle subtitle
- one featured reflection card
- a subtle stacked preview behind it
- a soft queue hint such as `2 more moments waiting`

### Subtitle Tone

The subtitle should use gentle coaching rather than practical task framing.

Target tone:

- reflective
- warm
- non-judgmental
- calm

Example direction:

- `A small pause can show whether this moment fit your rhythm.`

Exact copy can be finalized during implementation, but it should stay in that emotional register.

### Featured Card Behavior

The card should remain centered on a single transaction at a time.

The existing interaction model stays:

- featured transaction context
- prompt
- `Worth It`
- `Not Sure`
- `Regret`

Swipe affordances may remain if they still feel good in the richer design, but the visual emphasis should shift toward the editorial card rather than the dismissible utility behavior.

### Queue Hint

The section should suggest more pending reflection moments without turning into a second feed.

Recommended expression:

- stacked preview treatment behind the primary card
- one small line of copy communicating remaining count

This should feel like a quiet shelf of moments rather than a carousel or inbox.

### Card Content

The featured card should show:

- merchant/counterparty
- compact context such as category and time
- amount
- one short prompt
- the three reflection choices

The content hierarchy should make the emotional prompt more prominent than it is today.

### Visual Direction

The reflect card should feel:

- warmer
- more spacious
- more editorial
- less like a generic dashboard tile

Design cues:

- stronger card silhouette
- more breathing room around the prompt
- clearer internal hierarchy
- gentle surface layering for the stacked queue treatment
- glyph accents where they add identity, not noise

## Component Boundaries

### RegretPromptCard

`RegretPromptCard` is the right primary seam for this work.

It should evolve from a compact utility card into the featured editorial reflection card while keeping the core interaction contract stable.

Likely responsibilities after the facelift:

- render the richer featured reflection layout
- render the gentle prompt framing
- render the choice buttons
- optionally accept metadata for queue count / stacked treatment if that is cleaner than handling all of it in `DashboardScreen`

### DashboardScreen

`DashboardScreen` should continue to:

- select reflection candidates
- choose the featured item
- compute how many additional items are waiting
- render the section heading/subtitle
- pass the featured transaction and callbacks into the card

This keeps queue logic in the screen and reflection presentation in the card.

## Rollout Strategy

### Phase 1

Continue the glyph refactor and curated v1 glyph expansion with minimal disruption to current call sites.

### Phase 2

Apply the improved glyph language to the reflection surface where it gives immediate visual value.

### Phase 3

Redesign the dashboard `Reflect` section and `RegretPromptCard` into the featured editorial card plus stacked queue hint.

### Phase 4

Optionally tighten one or two nearby dashboard icon moments only if they become obvious wins during implementation.

This work should not turn into a broad dashboard redesign pass.

## Testing Strategy

### Glyph Tests

Add or expand:

- mapping tests
- constructor/widget tests
- representative golden tests for at least one glyph from each domain

The initial goldens should focus on drift detection, not exhaustive per-glyph snapshots.

### Reflect Tests

Update or add widget tests for:

- the section subtitle rendering
- featured-card rendering
- queue hint rendering
- existing reflection action behavior
- swipe behavior if retained

Existing `RegretPromptCard` tests should evolve with the new structure rather than be discarded.

### Verification

Minimum verification:

- `flutter analyze`
- `flutter test`

If goldens are added, they should be included in the test run or in a focused command that is executed before completion.

## Risks

### Risk: Glyph Refactor Gets Too Large

Mitigation:

- stay inside the approved curated v1 set
- prioritize dashboard-relevant glyph value rather than long-tail expansion

### Risk: Reflect Card Becomes Too Busy

Mitigation:

- keep one featured moment only
- use a subtle stacked preview rather than a full queue rail
- keep the prompt and response choices visually dominant

### Risk: Dashboard Scope Creep

Mitigation:

- do not redesign budgets or recent transactions in this pass
- treat nearby icon polish as optional, not required

## Decision

Proceed with a focused combined pass that:

- continues the Conscia glyph system into a modular curated v1 implementation
- uses that stronger icon language selectively
- redesigns the dashboard `Reflect` area into a featured editorial reflection card with a gentle subtitle and small stacked queue preview
