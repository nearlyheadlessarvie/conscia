# Transaction Design Language Test Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the approved transaction-screen design language with the canonical redesign docs, update obsolete transaction-related tests to match the shipped UI, and commit the branch’s untracked redesign files.

**Architecture:** Keep production UI changes minimal in this pass. Treat the current transaction list/add-edit UI as the approved baseline, fold its rules into the broader iOS-forward design documentation, and update stale tests to assert the real design contract instead of outdated widget structure.

**Tech Stack:** Flutter, Riverpod, GoRouter, Flutter widget tests, markdown docs, git

---

## File Structure

- Modify: `docs/superpowers/specs/2026-05-12-ios-forward-app-redesign-design.md`
- Modify: `app/test/core/routing/app_router_test.dart`
- Modify: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_detail_screen_test.dart`
- Review for no-op or inclusion in commit: `app/lib/widgets/amount_hero_field.dart`
- Review for no-op or inclusion in commit: `app/lib/widgets/form_label.dart`
- Review for no-op or inclusion in commit: `app/lib/widgets/segmented_switch.dart`
- Review for inclusion in commit: `docs/superpowers/plans/2026-05-12-ios-forward-app-redesign.md`
- Review for inclusion in commit: `docs/superpowers/specs/2026-05-13-transaction-screens-se-design.md`

### Task 1: Update The Canonical Design Language Doc

**Files:**
- Modify: `docs/superpowers/specs/2026-05-12-ios-forward-app-redesign-design.md`
- Reference: `docs/superpowers/specs/2026-05-13-transaction-screens-se-design.md`

- [ ] **Step 1: Add a failing documentation regression test in the form of a manual checklist**

Checklist to verify against the doc after editing:

- transaction list remains chip-only on SE
- add/edit transaction use floating-label fields for merchant/source and date
- `SCOPE` stays explicitly labeled
- add/edit transaction remain utility-tier, not editorial-tier

- [ ] **Step 2: Update the redesign spec to encode the approved transaction-screen rules**

Add a short `Transaction Screen Rules` subsection that makes these decisions canonical for the broader redesign:

```md
### Transaction Screen Rules

- Transactions list stays in the paper-native utility tier.
- On iPhone SE, the list uses a single horizontal chip rail and does not add a separate `Personal / Family` segmented control.
- Add and edit transaction share the same structure.
- `Merchant` / `Source` and `Date` use the v2 floating-label filled-field treatment.
- `SCOPE` remains an explicit section label rather than relying on implied context.
- Category selection stays a single-row horizontal rail on SE.
```

- [ ] **Step 3: Review the edited doc against the checklist**

Run a manual read-through and confirm all four checklist items are explicitly covered.

### Task 2: Update Transaction Form And Router Tests

**Files:**
- Modify: `app/test/core/routing/app_router_test.dart`
- Modify: `app/test/screens/transactions/transaction_form_screen_test.dart`

- [ ] **Step 1: Update the failing tests to target the current approved UI contract**

Revise stale expectations:

- replace the `InputChip` descendant assertion for the selected category with a higher-level visible-category assertion
- avoid `find.text('Today')` exact-one assertions when the current UI intentionally renders the value in more than one place
- assert `RECURRING` instead of `Recurring`
- assert the current end-date label/value that the form actually exposes
- assert `SCOPE` only if the shipped form renders it; if missing, convert the test to describe the current approved structure or stop and fix production code in a separate red-green step

- [ ] **Step 2: Run the focused transaction form and router tests to verify red or green status**

Run:

```bash
flutter test test/screens/transactions/transaction_form_screen_test.dart test/core/routing/app_router_test.dart -r compact
```

Expected:

- first run should expose only the stale expectation failures being fixed
- after edits, the suite should pass

- [ ] **Step 3: If any assertion reveals a real design regression rather than a stale test, stop and fix it with a new failing test first**

Do not silently rewrite a test around a regression that contradicts the approved design.

### Task 3: Update Transaction Detail Tests

**Files:**
- Modify: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Update failing detail tests to match the current approved detail screen behavior**

Revise stale assumptions:

- replace obsolete hero-card key checks with stable visible-content assertions
- update delete-flow harness if the screen now requires a router-aware wrapper
- adjust loader assertions to target the actual shared loader widget or visible loading copy

- [ ] **Step 2: Run the focused transaction list/detail tests**

Run:

```bash
flutter test test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart -r compact
```

Expected:

- list tests remain green
- detail tests pass after the stale expectations are corrected

### Task 4: Verify Untracked Files And Commit The Redesign Work

**Files:**
- Review and stage: `app/lib/widgets/amount_hero_field.dart`
- Review and stage: `app/lib/widgets/form_label.dart`
- Review and stage: `app/lib/widgets/segmented_switch.dart`
- Review and stage: `docs/superpowers/plans/2026-05-12-ios-forward-app-redesign.md`
- Review and stage: `docs/superpowers/specs/2026-05-13-transaction-screens-se-design.md`
- Stage related modified files already on branch

- [ ] **Step 1: Inspect the untracked files to confirm they belong to the redesign branch**

Run:

```bash
git diff --no-index -- /dev/null app/lib/widgets/amount_hero_field.dart
git diff --no-index -- /dev/null app/lib/widgets/form_label.dart
git diff --no-index -- /dev/null app/lib/widgets/segmented_switch.dart
git diff --no-index -- /dev/null docs/superpowers/specs/2026-05-13-transaction-screens-se-design.md
```

Expected:

- each file clearly belongs to the redesign/test-alignment work

- [ ] **Step 2: Run focused verification before committing**

Run:

```bash
flutter analyze test/core/routing/app_router_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart test/screens/transactions/transaction_list_screen_test.dart
flutter test test/screens/transactions/transaction_form_screen_test.dart test/core/routing/app_router_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart -r compact
```

Expected:

- analyze exits `0`
- tests pass with `0` failures

- [ ] **Step 3: Commit the updated and untracked redesign files**

Run:

```bash
git add docs/superpowers/specs/2026-05-12-ios-forward-app-redesign-design.md docs/superpowers/specs/2026-05-13-transaction-screens-se-design.md docs/superpowers/plans/2026-05-12-ios-forward-app-redesign.md docs/superpowers/plans/2026-05-13-transaction-design-language-test-alignment.md app/lib/widgets/amount_hero_field.dart app/lib/widgets/form_label.dart app/lib/widgets/segmented_switch.dart app/test/core/routing/app_router_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git add -u
git commit -m "test: align transaction redesign coverage"
```

Expected:

- commit succeeds on `feature/ios-forward-app-redesign`

## Self-Review

- Spec coverage: this plan covers canonical design-doc alignment, the stale transaction/router/detail tests, and staging the untracked redesign files requested by the user.
- Placeholder scan: all steps contain exact files and commands.
- Type consistency: all test targets and doc paths match the current repo structure.
