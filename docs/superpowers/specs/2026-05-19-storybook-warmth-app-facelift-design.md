# Storybook Warmth App Facelift Design

**Date:** 2026-05-19
**Status:** Approved for planning
**Feature:** App-wide visual facelift based on the Journey mockup direction

## Goal

Turn the approved Journey mockup language into a cohesive app-wide facelift for Conscia.

The facelift should make the entire app feel warmer, more intentional, and more companion-led without changing the product model or navigation structure. It should preserve Conscia's existing utility while giving screens the emotional tone now established by the Journey-led Home direction.

The approved direction is **Storybook Warmth**:

- expressive editorial headings
- friendly readable product text
- cream paper surfaces
- deep navy structure
- coral action accents
- warm amber/sand atmospheric surfaces
- rounded, tactile cards and bottom sheets
- light and dark themes designed together

The facelift should not:

- introduce a sixth nav destination
- redesign feature flows while doing visual foundation work
- add new product capabilities
- make the app feel childish or arcade-like
- rely on one-off screen styling that bypasses shared theme tokens

## Typography

The font direction is locked.

Conscia should use a two-family type system:

- **Cormorant Garamond** for expressive headings and editorial moments
- **Nunito Sans** for body text, labels, controls, navigation, amounts, and dense UI

Cormorant Garamond gives the app the Storybook Warmth signal: reflective, human, literary, and emotionally distinct from a generic finance dashboard. It should be used selectively so it feels special rather than noisy.

Nunito Sans should replace the current Poppins/Inter mix as the core product font. It keeps the interface friendly and readable while pairing better with Cormorant Garamond than the current sharper body stack.

Recommended type roles:

- `displayLarge`, `displayMedium`, `headlineLarge`, `headlineMedium`, and `titleLarge`: Cormorant Garamond
- `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`, and button text: Nunito Sans
- transaction amounts and numeric UI: Nunito Sans with strong weights and tabular figures where available

Screen-level exceptions should be rare. If a screen needs custom type, it should pull from named app typography helpers rather than directly calling `GoogleFonts` inline.

## Color Direction

The approved color principle is:

- light mode feels like **warm morning paper**
- dark mode feels like **candlelit navy**

Dark mode should not be a simple inversion of light mode. It should carry the same identity with deeper, warmer atmosphere.

Core light tokens:

- paper: warm cream, used for scaffold and calm surfaces
- deep navy: primary ink, major actions, selected nav state
- coral: primary action accent, CTA arrows, important progress highlights
- amber/sand: hero warmth, soft cards, positive momentum
- muted lavender-gray: secondary copy and inactive UI
- soft sage/green: improvement and income signals
- soft red/coral: regret, expense, and warning signals

Core dark tokens:

- midnight paper: deep navy-black scaffold
- candle ink: warm cream text
- deep navy surfaces: raised cards and sheets
- ember coral: primary action accent
- burnt amber/sand: warmth and hero atmosphere
- desaturated lavender-gray: secondary copy and inactive UI
- softened green/red: financial signal colors with accessible contrast

Existing semantic colors must remain semantically clear:

- income should stay green
- expenses and regret signals should stay red/coral
- caution should stay amber
- destructive actions should remain distinct from the friendly coral action color

## Component Language

The facelift should be implemented through shared theme and component primitives first.

Primary surfaces should feel tactile and calm:

- cards: larger radius, low/no elevation, warm borders, optional soft gradients for editorial modules
- bottom sheets: rounded, paper-like, with warm handle and layered surfaces
- buttons: pill-shaped by default, deep navy filled actions, coral reserved for contained action moments or icon CTAs
- chips: soft paper/sand fills, stronger selected state, friendly rounded geometry
- inputs: warm filled surfaces with clear navy focus state
- nav: preserve the existing 5-destination structure, but tune colors, active state, and translucency to match the new palette

The Journey-led Home hero is the reference surface for emotional moments, but not every screen should become cinematic. Utility-heavy screens should use the same typography and colors in a calmer density.

## App-Wide Scope

The first implementation pass should be **Foundation First**.

This means:

- update `AppTheme` light and dark typography
- update `AppColors` light and dark tokens
- align Material theme defaults for cards, buttons, chips, inputs, app bars, bottom sheets, dividers, and navigation bars
- replace inline `GoogleFonts.poppins` and `GoogleFonts.inter` calls with theme-driven typography or the approved Cormorant Garamond/Nunito Sans stack
- tune the Journey-led Home implementation so it uses shared tokens rather than becoming a special-case island
- apply light-touch fixes to obvious screens where old font/color assumptions clash with the new system

This first pass should not attempt a full screen-by-screen redesign of every feature. After the foundation lands, follow-up passes can polish hero screens:

- Transactions
- Purchase Assistant
- Scan Receipt and Receipt Review
- Settings and subscription surfaces
- Insights and notifications
- Onboarding

## Architecture

The theme layer remains the source of truth:

- `app/lib/core/theme/app_theme.dart` owns Material theme configuration and global `TextTheme`
- `app/lib/core/theme/app_colors.dart` owns Conscia-specific semantic and atmospheric tokens
- screen widgets consume `Theme.of(context)` and `theme.appColors`

New design primitives may be introduced only if they reduce repeated styling, for example:

- shared editorial section title helper
- shared warm card container
- shared action icon button
- shared status/signal chip

These primitives should be small and reusable. They should not create a parallel design system outside Flutter's theme layer.

## Accessibility

The facelift must preserve or improve usability:

- text contrast must remain accessible in light and dark mode
- coral-on-cream and coral-on-navy combinations need explicit contrast checks
- dense transaction and amount screens must prioritize readability over decoration
- dark mode should avoid low-contrast warm grays
- typography changes should not reduce visible content enough to harm task completion
- touch targets should remain at least the current size

## Testing And Verification

The implementation plan should include:

- theme unit/widget coverage where practical for critical token expectations
- golden or snapshot-style coverage only if the repo already supports it reliably
- existing screen tests updated for text or key changes caused by typography/component changes
- focused widget tests for high-risk visual surfaces such as Home, bottom navigation, transaction tiles, forms, and bottom sheets
- `flutter analyze`
- targeted `flutter test` suites for screens touched by the first pass

Visual verification should include manual light and dark review of:

- Home/Journey
- Transactions list and detail
- transaction form
- Purchase Assistant
- receipt review
- Settings
- notification sheet

## Success Criteria

The facelift is successful when:

- the app visibly shares the Journey mockup's Storybook Warmth identity
- light and dark mode feel like two versions of the same brand
- Cormorant Garamond and Nunito Sans are the dominant app-wide font system
- old Poppins/Inter one-offs are removed or intentionally justified
- financial utility screens remain clear and trustworthy
- Journey feels like the natural center of the app rather than a visually isolated experiment
- the existing navigation and feature flows continue to work unchanged
