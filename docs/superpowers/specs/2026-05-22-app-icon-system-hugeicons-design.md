# App Icon System Hugeicons Design

## Goal

Replace the app's remaining direct icon usage with a unified Hugeicons-based system while keeping `ConsciaGlyph` as the shared rendering helper. At the same time, reduce the visual heaviness of category icons by lowering their stroke weight at the source.

## Problem

The app currently mixes several icon systems:

- direct `Icons.*` usage across many screens
- `AppIcons` wrappers that still return Material/Cupertino `IconData`
- `CategoryIcons` and `ConsciaGlyph` already partially migrated to Hugeicons

This creates inconsistency in shape language, stroke weight, and overall polish. The issue is especially visible in category badges on transaction-heavy surfaces, where the current category stroke treatment feels too bold.

## Non-Goals

- no mascot changes in `ai_guidance_chat`
- no redesign of layouts, copy, or category text styles
- no broad refactor of unrelated widget structure
- no dark-mode redesign in this pass

## Approach Options

### 1. Centralized Hugeicons System

Keep `ConsciaGlyph` as the rendering shell, expand semantic mappings, and route both product icons and utility icons through shared app-owned helpers.

Pros:

- one visual system
- one place to tune weight and style
- easier future cleanup and consistency

Cons:

- larger initial sweep

### 2. Hybrid Migration

Keep `ConsciaGlyph` for semantic icons, but replace utility icons with inline `HugeIcon` usage.

Pros:

- faster in the short term

Cons:

- two authoring styles remain
- harder to tune globally later

### 3. Mechanical Swap

Replace `Icons.*` usage screen by screen without improving the shared helpers.

Pros:

- fastest to start

Cons:

- inconsistent long term
- weak foundation

## Recommendation

Use approach 1.

This keeps the migration app-owned and consistent. It also gives us a single place to reduce category icon heaviness without hand-tuning every screen.

## Design

### Shared Rendering

`ConsciaGlyph` remains the single helper container for Hugeicons rendering.

It will continue to:

- accept semantic kinds
- map those kinds to Hugeicons
- control size, color, and stroke width

### Utility Icon Catalog

`AppIcons` will stop acting as a Material/Cupertino compatibility table and instead become the shared app catalog for general-purpose icons such as:

- add
- close
- check
- chevrons
- search
- refresh
- delete
- edit
- warning
- error
- visibility
- status and service icons

Where a widget currently expects `IconData`, we should prefer moving that call site to render a widget through shared helpers rather than preserving raw `IconData` as the main abstraction.

### Category Icon Weight

Category heaviness will be fixed at the helper level, not screen by screen.

Changes:

- lower the category `strokeWidth` from the current badge/raw-icon treatment
- keep the existing badge shape, tint, and accent color system
- preserve current category icon sizing unless a specific surface still feels too heavy after the stroke change

This should automatically improve:

- transaction list
- recent transactions
- transaction detail
- category chips and pickers that use the shared category helpers

### Migration Scope

Replace direct `Icons.*` usage across the app, including:

- onboarding
- dashboard
- transactions
- settings
- budgets
- receipts
- family
- insights
- shared widgets

Exceptions:

- platform logos or special brand cases that are not part of the Hugeicons set
- `ai_guidance_chat` mascot/assistant visuals

### Compatibility Strategy

The pass should be surgical:

- preserve existing widget APIs where practical
- update tests that assert specific icon widgets or icon data
- avoid unrelated styling changes

## Testing

Verification should focus on:

- widget tests for shared icon helpers
- targeted screen/widget tests for icon-bearing surfaces changed by the migration
- `flutter analyze`

If a full app-wide widget test pass is practical, run it, but the minimum bar is targeted verification on the changed helpers and key transaction/category surfaces.

## Risks

### Risk: Some widgets still require `IconData`

Mitigation:

- convert those call sites to widget-based icon rendering only where needed
- avoid introducing broad new abstraction layers

### Risk: The sweep becomes too invasive

Mitigation:

- use shared helper expansion first
- make direct replacements only where they clearly map into that system

### Risk: Category icons become too faint

Mitigation:

- reduce stroke weight first without simultaneously weakening color treatment
- verify the key transaction surfaces visually

## Expected Outcome

After this pass:

- the app uses one cohesive Hugeicons-based icon language
- `ConsciaGlyph` remains the shared helper container
- category icons feel lighter and less over-inked
- the transaction surfaces called out by the user look calmer without changing their typography or layout
