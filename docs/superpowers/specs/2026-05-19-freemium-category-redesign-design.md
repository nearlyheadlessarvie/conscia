# Freemium Category Redesign

## Goal

Redesign the free tier so budgeting is open across all categories, while transaction logging and custom category creation are premium-differentiated in a clean, minimal way.

## Product Decisions

- Free users can create and edit budgets in any built-in category.
- Free users are limited to three transaction categories:
  - `Dining`
  - `Grocery`
  - `Salary`
- Free users cannot create custom categories.
- Onboarding keeps full budget allocation freedom and should not show a free-tier budget cap.
- Transaction entry UI should stay clean and minimal:
  - show active free categories directly
  - show a single premium affordance for additional categories instead of many locked chips
- Premium gating must be enforced in both UI and API.

## Backend Design

- Introduce a shared freemium policy helper in the application layer for:
  - free transaction categories
  - free custom category creation restriction
- Remove budget-category count enforcement from free users in `BudgetEndpoints`.
- Enforce free-tier transaction category restrictions in transaction create/update endpoints before persistence.
- Enforce premium-only custom category creation in category create endpoint or service.

## Frontend Design

- Replace the current free-tier category visibility helper with two distinct policies:
  - budget category visibility: all built-in categories
  - transaction category visibility: free users see only the three free categories
- Update category pickers and quick chips to expose only the free transaction set for non-premium users.
- Add a minimal premium entrypoint such as `More categories` / `Premium categories` that opens the upgrade sheet rather than presenting many locked options.
- Keep onboarding suggested budgets and budget forms fully open to all built-in categories.
- Gate category-management creation for free users with the subscription sheet / upgrade dialog.

## Visual Design

- Adjust the thinking cloud to read more clearly as an intentional sphere:
  - preserve the active central cluster
  - add a subtle outer-shell halo of smaller, more numerous, lower-opacity dots near the boundary
  - avoid a uniform ring so it still feels like thought rather than a globe

## Testing

- Add backend tests for:
  - free user can create unrestricted budgets
  - free user cannot create custom categories
  - free user cannot create/update transactions outside the free set
- Add Flutter tests for:
  - non-premium transaction pickers only expose the free set plus premium affordance
  - budget flows still expose all categories to free users
  - category management blocks free custom-category creation
  - thinking cloud particle generation includes a denser boundary halo without losing determinism
