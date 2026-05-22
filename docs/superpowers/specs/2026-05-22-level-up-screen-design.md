# Level-Up Screen Redesign

## Goal

Redesign the Conscience Journey level-up screen so it feels like a meaningful milestone moment instead of a plain utility page.

This redesign should:

- remove the current generic app-page feeling
- replace the abstract glyph-first presentation with mascot/illustration-led art
- keep one shared composition across all levels
- support direct web/debug preview routes for each level
- stay light-mode-first for now

Dark mode is explicitly deferred to `1.1.0`.

## Problems With The Current Screen

The current screen has a few issues:

- the top-left back arrow makes it feel like a normal settings/detail page instead of a reward moment
- the central glyph reads as too abstract and, in at least one case, visually awkward
- the layout lacks ceremony, hierarchy, and visual payoff
- level identity is too dependent on text because the iconography is not expressive enough
- there is no easy route-level preview flow for reviewing each level in web

## Recommended Approach

Use a shared ceremonial screen composition with per-level mascot PNG illustration swaps.

This gives the app:

- one polished reusable layout
- richer and more characterful level identity
- easier art direction than trying to force all levels through the current glyph system
- low implementation risk compared with making a bespoke layout per level

## Screen Structure

The redesigned screen should use one shared composition for all levels in this order:

1. ambient backdrop
2. mascot illustration
3. small eyebrow label
4. large level title
5. short payoff line
6. explanatory body copy
7. compact progress summary
8. single primary CTA at the bottom

### Layout Notes

- remove the top-left back affordance entirely
- use the bottom CTA as the single intentional exit path
- center the content more deliberately so the screen feels ceremonial
- give the illustration more space and priority than the current glyph bubble
- keep the bottom CTA anchored and visually confident

## Art Direction

Level-up art should move to PNG illustrations.

### Asset Model

- one PNG illustration per level
- transparent background assets
- shared composition and placement rules across levels
- fallback to the existing glyph system only if a PNG asset is missing

### Tone

The visual tone should be:

- mascot-led
- warm
- premium
- calm rather than loud
- celebratory without becoming gamey

This should not look like a badge wall or arcade reward screen. It should feel like a quiet but meaningful money-growth milestone.

## Content Model

Each level should provide:

- `level key`
- `title`
- `eyebrow`
- `payoff line`
- `meaning/body copy`
- `illustration asset path`

The shared layout consumes this content and does not need bespoke logic per level beyond asset and copy selection.

## Navigation Behavior

The screen should no longer expose a top-left back arrow.

Expected behavior:

- the primary CTA dismisses the screen
- system back behavior can still work if the platform provides it
- visual UI should not invite a secondary back path from the top bar

This keeps the screen feeling intentional rather than accidental.

## Dark Mode

Dark mode is not part of this change.

For this redesign:

- optimize the screen for light mode only
- keep layout and asset plumbing compatible with a future dark variant
- do not introduce a partial or low-confidence dark theme branch

Dark mode can be designed as part of `1.1.0`.

## Debug / Web Preview Routes

Add dev-friendly preview routes for direct inspection of each level screen.

### Shape

Use one preview screen route that accepts a level key and builds a mock `ConscienceJourneySummary`.

Examples:

- `/debug/journey/level-up/awakening`
- `/debug/journey/level-up/impulse-spotter`
- `/debug/journey/level-up/budget-guardian`
- `/debug/journey/level-up/conscience-captain`
- `/debug/journey/level-up/money-monk`

### Expectations

- preview routes are for local/dev/debug use
- they should not affect normal app navigation
- they should make it easy to inspect layout, copy, and art swaps in web

## Non-Goals

This redesign does not include:

- dark mode
- a broader journey-system rewrite
- new progression rules
- bespoke layout variations per level
- replacing all glyph usage across the app

## Testing

Testing should cover:

- the level-up screen renders the new shared structure
- the top-left back affordance is gone
- the CTA still dismisses correctly
- each preview route resolves and renders the intended level content
- the screen falls back safely if a PNG illustration is missing

## Implementation Notes

Follow existing app patterns where possible, but this screen should be allowed to feel more editorial and intentional than a normal utility page.

Prefer a small shared data/config layer for level presentation instead of scattering copy and asset lookups through the widget tree.
