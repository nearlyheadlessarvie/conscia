# Freemium Category Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shift free-tier limits from budgets to transaction categories and custom category creation, while keeping onboarding budget allocation fully open and refining the thinking cloud visual.

**Architecture:** Add one shared freemium policy helper on the backend and one shared category-visibility helper on the Flutter side. Remove old budget-count gating, add explicit API enforcement for transactions and category creation, then update the UI to expose a minimal premium affordance and tune the thinking-cloud boundary particles.

**Tech Stack:** ASP.NET Core minimal APIs, C# unit tests with xUnit/Moq, Flutter with Riverpod and widget tests

---

### Task 1: Backend Freemium Policy

**Files:**
- Create: `src/Conscia.Application/Constants/FreemiumCategoryPolicy.cs`
- Modify: `src/Conscia.Api/Endpoints/BudgetEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
- Modify: `src/Conscia.Api/Endpoints/CategoryEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/BudgetEndpointTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/CategoryEndpointTests.cs`

- [ ] Write failing endpoint tests for free-tier behavior.
- [ ] Run targeted API tests and confirm the new cases fail for the expected reason.
- [ ] Add the shared freemium policy helper and wire endpoint enforcement.
- [ ] Re-run targeted API tests and confirm they pass.

### Task 2: Flutter Category Gating

**Files:**
- Modify: `app/lib/core/constants/category_visibility.dart`
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Modify: `app/lib/screens/transactions/widgets/transaction_style_category_selector.dart`
- Modify: `app/lib/screens/budgets/budgets_screen.dart`
- Modify: `app/lib/screens/settings/category_management_screen.dart`
- Modify: `app/lib/screens/settings/widgets/subscription_sheet.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/settings/category_management_screen_test.dart`
- Test: `app/test/screens/budgets/widgets/budget_form_sheet_test.dart`

- [ ] Write failing Flutter widget tests for free transaction visibility, premium affordance, and free-user category-management gating.
- [ ] Run the targeted Flutter tests and confirm the failures.
- [ ] Implement minimal UI changes to satisfy the new policy and keep budget flows unrestricted.
- [ ] Re-run the targeted Flutter tests and confirm they pass.

### Task 3: Canonical Category Set Alignment

**Files:**
- Modify: `src/Conscia.Domain/Constants/TransactionCategories.cs`
- Modify: `app/lib/core/constants/generated/app_constants.g.dart` via generator
- Modify: any directly-coupled tests or fixtures that depend on the renamed free category
- Test: `tests/Conscia.Tests.Unit/Domain/TransactionCategoriesTests.cs`

- [ ] Decide and apply the canonical built-in category label for the free grocery category.
- [ ] Update the source constant and regenerate frontend constants if needed.
- [ ] Fix tightly-coupled tests and fixtures.
- [ ] Re-run the targeted category-constant tests.

### Task 4: Thinking Cloud Halo Refinement

**Files:**
- Modify: `app/lib/widgets/thinking_cloud.dart`
- Test: `app/test/widgets/thinking_cloud_test.dart` or nearest existing visual determinism test file

- [ ] Write a failing test around deterministic particle composition or boundary weighting if test coverage exists nearby.
- [ ] Adjust particle generation to add a denser, lower-opacity boundary halo.
- [ ] Re-run the targeted thinking-cloud tests.

### Task 5: Final Verification

**Files:**
- Verify only

- [ ] Run the targeted backend tests for budget, transaction, and category APIs.
- [ ] Run the targeted Flutter widget tests for transactions, budgets, category management, and thinking cloud.
- [ ] Run any needed generator or formatting command and confirm the worktree is clean except for intentional changes.
