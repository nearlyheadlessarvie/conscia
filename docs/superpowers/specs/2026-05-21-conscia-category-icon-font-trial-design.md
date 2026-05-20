# Conscia Category Icon Font Trial Design

## Goal

Create a tight first batch of custom category SVG icons for Conscia, designed specifically for export into an icon font via FlutterIcon, and trial them in both category icon picker surfaces before expanding the set.

## Why This Direction

The current category icon experience is in an awkward middle state:

- the app now has a stronger custom glyph language
- the category icon picker still exposes a broad catalog
- several choices collapse into visually similar shapes
- the chip sizes and icon proportions make the repetition more obvious

The `CustomPainter` glyph system is useful as a visual reference, but it is not the ideal long-term substrate for an app-wide icon system. For a reusable category picker library, a custom font pipeline is a better fit:

- easier to render consistently in chips, sheets, rows, and badges
- easier to size and recolor like normal icons
- better long-term maintainability once the visual language is stable

This trial is intentionally narrow. The goal is not to replace the full icon system yet. The goal is to prove that a curated SVG-to-font workflow produces a more distinct, more polished category picker.

## Trial Scope

The trial only targets the category icon selection experience:

- the compact inline icon rail on the category form
- the full `Choose icon` bottom sheet

It does not yet replace:

- the broader app icon system
- dashboard glyphs
- utility icons in settings, alerts, or navigation

## First Trial Set

The first batch should stay tight and highly distinct. The initial set will contain 20 icons:

- groceries
- dining
- transport
- shopping
- health
- bills
- education
- travel
- coffee
- subscription
- salary
- freelance
- business
- investment
- gift
- home
- utilities
- phone
- pets
- other

This set is intentionally biased toward:

- common categories
- strong, recognizable silhouettes
- minimal visual overlap

Categories outside this set are not in scope for the first SVG/font pass.

## Visual Rules For The SVG Batch

The SVGs should be prepared as clean single-color icon shapes for icon-font export.

Rules:

- monochrome only
- one icon per SVG file
- fixed artboard/grid for the whole set
- rounded, calm Conscia stroke language
- no tiny interior details that disappear below 20px
- no multi-part decorative compositions
- prioritize silhouette clarity over literal realism

The icons should feel:

- warmer and softer than generic platform icons
- simpler and more stable than the current experimental painter set
- distinct enough to scan quickly in a dense icon picker

## Source Of Truth

The editable design source should be the SVG files, not the generated font.

Proposed source folder:

- `app/assets/icons/conscia-font-src/`

Each icon should use a stable semantic filename, for example:

- `groceries.svg`
- `dining.svg`
- `transport.svg`
- `subscription.svg`

After the SVG batch is reviewed, the user will import those SVGs into FlutterIcon and generate the font package manually. Once the font package exists, the generated font files and generated Dart mapping can be committed separately.

## Trial Integration Plan

This trial runs in two phases:

### Phase 1: SVG batch and preview

- create the SVG source files in-repo
- add a lightweight preview surface so the icons can be inspected before font export
- use that preview to judge distinctiveness, sizing, and category fit

### Phase 2: Font hookup after manual packaging

After the user packages the SVGs with FlutterIcon:

- wire the generated icon font into the compact inline rail
- wire the generated icon font into the full picker sheet
- keep the scope limited to the category selection experience

## App Integration Expectations

For the first pass, the category picker should feel curated rather than exhaustive.

That means:

- the icon option list should be reduced to the first curated set
- the inline icon rail should show only those trial icons
- the full sheet should use the same curated set, not a larger unstable catalog

This is important because a font trial should be judged on quality, not on how many edge-case symbols it can temporarily carry.

## Preview Surface

Before the font is generated, there should be a simple preview surface in the app or in a lightweight dev-only view that shows:

- each icon in a compact picker chip
- the same icons in a larger preview size
- label + filename mapping for quick review

This preview is not a permanent user-facing feature. It exists to validate the first SVG batch before the font becomes part of the app UI.

## Success Criteria

This trial succeeds if:

- the first icon batch feels visually cohesive
- each icon is clearly distinguishable in a dense picker layout
- the compact icon rail reads better than the current repeated set
- the SVG-to-font workflow feels repeatable for future expansion

This trial does not need to prove:

- full app-wide icon replacement
- complete category coverage
- retirement of the painter glyph system everywhere

## Risks And Constraints

### Risk: the set is too broad too early

Mitigation:

- keep the first batch tight
- optimize for distinction, not completeness

### Risk: exported font reveals SVG inconsistencies

Mitigation:

- use a fixed grid
- keep the SVG batch monochrome and simple
- review in a preview surface before font generation

### Risk: the picker still feels cramped after better icons

Mitigation:

- this trial should leave room for a later sizing/layout pass
- the first priority is icon quality, not final picker spacing

## Recommendation

Proceed with a small source-first SVG batch for the category picker only, preview it in-repo, let the user package it via FlutterIcon, then wire the generated font into both picker surfaces.
