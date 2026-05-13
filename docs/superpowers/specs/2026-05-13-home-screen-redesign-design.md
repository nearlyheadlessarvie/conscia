# Home Screen Redesign Design

**Date:** 2026-05-13
**Status:** Approved for planning
**Feature:** Conscia Home screen redesign

## Goal

Redesign the Home screen so it feels more personal, more editorial, and more immediately useful while staying faithful to the Conscia iOS-forward v2 design language.

The new Home should:

- feel like the emotional front door of the app
- greet the user personally
- put the editorial hero first, always
- remove noisy dashboard alert cards
- preserve real, believable product information rather than inventing fintech features the app does not have

## Product Decisions

### 1. Remove Home Alert Cards

Dashboard alert cards should be removed from the Home screen.

Alerts remain available through notifications, but Home should no longer spend valuable top-of-screen attention on them. This keeps the screen calmer and avoids competing with the editorial hero.

### 2. Hero Is Always First

The top-most element on Home is always the editorial hero.

It should:

- stretch full width
- visually reach into the top safe area
- feel like a contained premium surface rather than a generic card dropped into a feed

This is one of the screens that belongs in the richer editorial tier of the redesign.

### 3. Personal Header

The hero header should make the app feel more personal.

Approved structure:

- leading circular profile photo
- two-line greeting:
  - small line: `Welcome back`
  - strong line: user `name` when available, otherwise username/email-derived fallback
- trailing circular notification button

This implies Home should be ready to display a profile photo and a real display name when that data exists.

### 4. Hero Content

The hero should contain useful summary information grounded in actual Conscia capabilities.

Good content for the hero:

- a strong balance/spending summary for the current month
- budget pace or spend-so-far framing
- a mindful streak / journey tie-in
- compact shortcut actions such as:
  - Journey
  - Insights
  - Add transaction

Avoid fictional banking actions like:

- send
- request
- withdraw
- bill pay

Those do not fit the real product.

### 5. Full-Bleed Hero Treatment

The hero should span edge-to-edge across the device and visually blend into the top of the screen.

Rules:

- use the approved Conscia tokens, not arbitrary gradients
- atmosphere can combine `paper`, `amberSoft`, `navySoft`, and subtle supporting tints
- it should feel warm and premium, not loud
- internal content still respects safe padding and touch comfort

### 6. Transparent Area Behind The Floating Dock

The area behind and under the floating dock should remain visually transparent enough that underlying Home content can still be seen.

This is especially important near the lower scroll area, where category icons or row content should remain partially visible behind the dock instead of being fully masked by an opaque footer treatment.

The dock itself stays a white bordered surface, but the screen behind it should not flatten into a blocked-off band.

## Information Architecture

Approved Home order:

1. full-bleed editorial hero
2. first grouped content section
3. second grouped content section
4. lower content continuing behind the floating dock area

The hero is not preceded by alerts, promo cards, or utility clutter.

## Scrolling Behavior

Home should use a single continuous scroll view.

Rules:

- the editorial hero scrolls with the rest of the screen
- the hero is not permanently pinned
- once the user scrolls past the hero's top identity content, the identity row condenses into a sticky translucent header

The sticky header contains:

- profile photo
- `Welcome back`
- display name
- notification button

The sticky header should:

- use a soft frosted/translucent `paper` treatment
- keep the content readable without feeling opaque or heavy
- gain a subtle bottom border when acting as chrome over scrolling content

The primary hero summary itself does not stay pinned. Only the top identity row becomes persistent while scrolling.

## Recommended Home Content Structure

### Hero

Contains:

- profile/greeting row
- primary monthly summary
- one concise secondary context line
- compact quick links

### Middle Section

Use grouped-card data presentation rather than many isolated cards.

Preferred candidates:

- budget/category progress
- recent transactions

These should use white grouped surfaces with separators where appropriate.

### Lower Section

Continue with meaningful data rather than filler. The lower portion of the screen should be allowed to scroll beneath the floating dock visually.

## Visual Rules

- Background remains `paper`
- Hero is the richest visual surface on the screen
- Standard content cards remain white with `border`
- No drop shadows in light mode
- Use Poppins for stronger hero/title moments and Inter for body/data text
- Keep the Home screen warmer and more editorial than Transactions, but still restrained

## Constraints

- Do not invent new product modules
- Do not reintroduce Home alert cards
- Do not replace the existing floating dock pattern
- Do not turn Home into a generic banking dashboard
- Keep the design mobile-first; this spec is for the app, not the web marketing site

## Backend / Data Notes

The personalized header assumes support for:

- profile photo display
- display name / name fallback

If profile photo or display name are absent, the UI should degrade gracefully using current account data, but the redesign should be implemented in a way that is ready for those fields.

## Acceptance Criteria

The Home redesign is complete when:

- the hero is always the first and dominant surface
- the header feels personal with photo + welcome message + name
- dashboard alert cards are gone
- hero content is useful and grounded in real Conscia features
- the hero spans full width into the top safe area
- grouped content below feels organized rather than fragmented
- the area behind the floating dock still reveals underlying content
- the screen feels distinctly more premium and personal without drifting away from the Conscia tokens
