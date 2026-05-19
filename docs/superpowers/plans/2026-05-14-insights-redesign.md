# Insights Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Insights screen to match the approved bleed-edge editorial hero, transparent-to-translucent sticky header, uppercase muted section labels, and grouped insight flow.

**Architecture:** Keep the current providers and information architecture intact. Update the shared `ScreenSection` heading treatment, then refactor `InsightsScreen` into a `CustomScrollView` with a full-bleed hero, sticky overlay header, summary pulse, and grouped sections using existing insight feed data.

**Tech Stack:** Flutter, Riverpod, GoRouter, widget tests, Conscia design tokens

---

## File Structure

- Modify: `app/lib/widgets/screen_section.dart`
- Modify: `app/lib/screens/insights/insights_screen.dart`
- Modify: `app/test/screens/insights/insights_screen_test.dart`
- Add if useful: `app/test/widgets/screen_section_test.dart`

## Task 1: Shared Section Label Styling

**Files:**
- Test: `app/test/widgets/screen_section_test.dart`
- Modify: `app/lib/widgets/screen_section.dart`

- [ ] **Step 1: Write a failing widget test for section-title v2**

Assert `ScreenSection(title: 'Regret patterns', ...)` renders an uppercase `REGRET PATTERNS` label with muted, letter-spaced, bold styling and still renders the subtitle below it.

- [ ] **Step 2: Run the new test and confirm it fails**

Run:

```bash
flutter test test/widgets/screen_section_test.dart
```

Expected: fails because `ScreenSection` currently renders title case text.

- [ ] **Step 3: Update `ScreenSection`**

Render `title.toUpperCase()` with 12sp-ish label styling, `mutedInk`, 800 weight, and 0.8-1.0 letter spacing. Keep subtitle treatment readable and muted.

- [ ] **Step 4: Run the section test and focused impacted screen tests**

Run:

```bash
flutter test test/widgets/screen_section_test.dart test/screens/insights/insights_screen_test.dart
```

Expected: section test passes; Insights may still fail until Task 2 updates the screen/test contract.

## Task 2: Insights Hero And Sticky Header

**Files:**
- Modify: `app/test/screens/insights/insights_screen_test.dart`
- Modify: `app/lib/screens/insights/insights_screen.dart`

- [ ] **Step 1: Add failing tests for the approved Insights contract**

Cover:

- full-bleed hero key exists before the pulse summary
- no Angel/Devil emoji text appears in the hero
- transparent sticky header key exists
- section labels render uppercase muted copy such as `REGRET PATTERNS`

- [ ] **Step 2: Run focused Insights tests and confirm failures**

Run:

```bash
flutter test test/screens/insights/insights_screen_test.dart
```

Expected: fails on missing hero/header keys, emoji text, or uppercase labels.

- [ ] **Step 3: Implement the Insights layout**

Replace the current `HeroScreenScaffold` body with a `Stack` containing:

- `RefreshIndicator` / `CustomScrollView`
- `SliverToBoxAdapter` full-bleed hero
- summary pulse directly below the hero
- feed sections in the approved order
- overlay sticky header that changes from transparent to translucent after scroll

- [ ] **Step 4: Keep insight content grounded**

Reuse existing `InsightsSummary`, feed sections, merchant/category providers, `InsightFeedCard`, `MerchantSpotlightCard`, and `CategoryTrendCard`. Do not invent additional metrics.

- [ ] **Step 5: Run focused Insights tests**

Run:

```bash
flutter test test/screens/insights/insights_screen_test.dart
```

Expected: all Insights tests pass.

## Task 3: Verification

**Files:**
- All modified files

- [ ] **Step 1: Run focused widget and Insights tests**

Run:

```bash
flutter test test/widgets/screen_section_test.dart test/screens/insights/insights_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run broad touched-suite tests**

Run:

```bash
flutter test test/widgets/feed_card_test.dart test/widgets/locale_picker_sheet_test.dart test/widgets/screen_section_test.dart test/core/theme/app_theme_test.dart test/screens/insights/insights_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/budgets/widgets/budget_form_sheet_test.dart test/screens/budgets/budgets_screen_test.dart test/screens/family test/screens/settings
```

Expected: all tests pass.

- [ ] **Step 3: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues found.
