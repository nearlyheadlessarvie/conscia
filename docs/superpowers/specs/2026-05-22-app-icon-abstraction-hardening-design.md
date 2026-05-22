# App Icon Abstraction Hardening Design

Date: 2026-05-22

## Goal

Make the app icon system fully app-owned so future icon-set swaps happen centrally instead of screen-by-screen. Success means feature code no longer directly uses `Icons.*`, `CupertinoIcons.*`, `HugeIcon(...)`, or `HugeIconsStrokeRounded.*`, and a hard test enforces that boundary.

## Scope

This change applies to the Flutter app only.

Included:
- migrate all app icon usage behind app-owned helpers
- normalize semantic icon naming for generic, product, brand, and platform cases
- remove old `IconData`-based helper patterns from the app icon abstraction
- convert presenter/model-style icon outputs from raw toolkit types to semantic app keys where needed
- add a hard failing enforcement test

Not included:
- visual redesign beyond what is required by the migration
- changes to API, web, or infra projects
- changing the current selected icon pack

## Recommended Approach

Use one app-owned abstraction stack with strict enforcement:

- `AppIcons` for generic, product, brand, and system icons
- `CategoryIcons` for category/domain-specific icon selection
- `ConsciaGlyph` as the single rendering shell for the concrete icon pack

Only three files may directly reference concrete toolkit icon APIs:
- `app/lib/core/constants/app_icons.dart`
- `app/lib/core/constants/category_icons.dart`
- `app/lib/widgets/glyphs/conscia_glyph.dart`

Everything else in `app/lib` must consume semantic app-owned helpers.

## Architecture

### 1. `AppIcons` owns semantics

`AppIcons` becomes the sole public entry point for non-category icon rendering in app code.

Responsibilities:
- define `AppIconKey`
- map semantic keys to the current icon pack
- expose widget-level rendering through `AppIcons.icon(...)`

This layer should describe *meaning*, not toolkit names. Keys should communicate product intent, for example:
- `appleBrand`
- `passkey`
- `serviceApi`
- `serviceDatabase`
- `merchant`
- `sessionExpired`
- `familyInvite`

### 2. `CategoryIcons` owns category selection

`CategoryIcons` continues to choose category visuals and colors, but must also remain free of any icon leakage outside its own file.

### 3. `ConsciaGlyph` owns the concrete icon renderer

`ConsciaGlyph` remains the only place that directly renders the icon pack widgets. This keeps raw `HugeIcon` and concrete icon pack references out of feature code.

### 4. No `IconData` leakage in feature architecture

Any presenter, model, or feature layer currently returning `IconData` should return semantic app keys instead. Rendering belongs in the UI layer through `AppIcons.icon(...)`.

This is important for true future-proofing. If presenters still emit raw toolkit types, the app is only partially centralized.

## Migration Rules

After this change, feature code must not directly use:
- `Icons.`
- `CupertinoIcons.`
- `HugeIcon(`
- `HugeIconsStrokeRounded.`

Allowed direct usage only in:
- `app/lib/core/constants/app_icons.dart`
- `app/lib/core/constants/category_icons.dart`
- `app/lib/widgets/glyphs/conscia_glyph.dart`

## Enforcement

Add a hard failing test that scans `app/lib` and rejects direct icon usage outside the approved files.

The test should fail if it finds any of:
- `Icons.`
- `CupertinoIcons.`
- `HugeIcon(`
- `HugeIconsStrokeRounded.`

This test should be simple and explicit rather than clever. The goal is architectural discipline, not parser sophistication.

## Migration Areas

Based on current code patterns, the remaining work likely includes:
- family screens
- onboarding screens
- receipts screens
- service status screen
- journey screens and presenters
- app shell/system state screens
- assistant UI leftovers
- direct Hugeicon usage in some dashboard/insight widgets
- tests that currently assert against Material icon instances

## Brand and Platform Exceptions

Brand/platform icons are still required to go through the abstraction.

Examples:
- Apple sign-in icon should map from an app-owned semantic key like `appleBrand`
- passkey affordance should map from `passkey`
- service and environment health symbols should use semantic keys, not toolkit symbols in-place

This keeps exceptions explicit while still preserving the single-place swap goal.

## Implementation Principles

- keep changes surgical and semantic
- do not redesign screens unless the migration forces a tiny rendering adjustment
- prefer returning `AppIconKey` over raw icon toolkit data
- keep all direct icon-pack ownership in the allowed files only

## Testing

Required verification:
- focused widget tests for any screens touched by the migration
- updated tests that no longer search for Material/Cupertino icons directly when the UI now renders app-owned glyphs
- hard icon-boundary enforcement test
- Flutter analyze for the touched app files

## Risks

- some files may still use `IconData` as data, not just rendering detail
- some tests may be tightly coupled to old Material icon queries
- a few areas may need additional semantic keys before migration is complete

## Mitigation

- migrate data-level icon outputs to semantic keys as part of this pass
- update tests to assert app-owned icon behavior instead of toolkit internals where reasonable
- keep the enforcement test narrow and explicit so regressions are caught immediately
