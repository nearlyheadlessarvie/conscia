# Home Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the app Home screen so it becomes Conscia’s personal editorial front door: full-bleed hero first, no Home alert cards, sticky translucent identity header on scroll, and grouped content sections beneath the hero.

**Architecture:** Refactor `DashboardScreen` into a single continuous scroll experience with a full-bleed top hero and a scroll-reactive sticky header. Preserve the notifications sheet and real data sources, but remove in-feed dashboard alert banners and reorganize Home content into grouped utility sections below the hero. Keep the floating dock behavior intact while allowing underlying content to remain visible behind it.

**Tech Stack:** Flutter, Riverpod, GoRouter, slivers, Flutter widget tests

---

## File Structure

- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/dashboard/widgets/budget_summary_card.dart`
- Modify: `app/lib/screens/dashboard/widgets/recent_transaction_tile.dart`
- Modify: `app/lib/widgets/main_shell.dart`
- Modify: `app/lib/widgets/floating_dock_nav.dart`
- Modify: `app/lib/core/theme/app_colors.dart`
- Modify: `app/lib/services/user_service.dart`
- Modify: `app/test/screens/dashboard/dashboard_alerts_test.dart`
- Modify: `app/test/widgets/main_shell_test.dart`
- Create if needed: `app/lib/screens/dashboard/widgets/dashboard_identity_header.dart`
- Create if needed: `app/lib/screens/dashboard/widgets/dashboard_hero_quick_link.dart`

## Task 1: Lock The Home Screen Layout Contract In Tests

**Files:**
- Modify: `app/test/screens/dashboard/dashboard_alerts_test.dart`
- Modify: `app/test/widgets/main_shell_test.dart`

- [ ] **Step 1: Add or update failing Home tests for the approved structure**

Add or revise widget tests so they describe the new Home contract:

```dart
testWidgets('dashboard shows editorial hero before utility sections',
    (tester) async {
  await tester.pumpWidget(_buildApp(container));
  await tester.pumpAndSettle();

  final hero = find.byKey(const ValueKey('dashboard-editorial-hero'));
  final budgets = find.text('Budgets');

  expect(hero, findsOneWidget);
  expect(budgets, findsOneWidget);
  expect(tester.getTopLeft(hero).dy, lessThan(tester.getTopLeft(budgets).dy));
});

testWidgets('dashboard does not render in-feed alert banners', (tester) async {
  await tester.pumpWidget(_buildApp(container));
  await tester.pumpAndSettle();

  expect(find.byType(InAppAlertBanner), findsNothing);
  expect(find.byType(BudgetWarningBanner), findsNothing);
});

testWidgets('dashboard uses a sticky translucent identity header on scroll',
    (tester) async {
  await tester.pumpWidget(_buildApp(container));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('dashboard-sticky-identity-header')),
      findsOneWidget);
});
```

- [ ] **Step 2: Run the Home-focused tests to verify they fail for the right reason**

Run:

```bash
flutter test test/screens/dashboard/dashboard_alerts_test.dart test/widgets/main_shell_test.dart -r compact
```

Expected:

- failures should indicate outdated Home structure
- failures should not be caused by missing imports, broken test harnesses, or unrelated screens

- [ ] **Step 3: Adjust the test names and assertions until they clearly express the approved design**

Do not proceed until the tests describe:

- no Home alert cards
- hero first
- personal identity row
- scroll-aware sticky header
- dock transparency behavior where feasible to assert structurally

## Task 2: Rebuild DashboardScreen Around The New Home Hierarchy

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Create if needed: `app/lib/screens/dashboard/widgets/dashboard_identity_header.dart`
- Create if needed: `app/lib/screens/dashboard/widgets/dashboard_hero_quick_link.dart`

- [ ] **Step 1: Replace the current `SliverAppBar`-first layout with a hero-first sliver structure**

Rework the top of `DashboardScreen` so the order becomes:

```dart
return RefreshIndicator(
  onRefresh: _onRefresh,
  child: CustomScrollView(
    key: const PageStorageKey('dashboard-shell-scroll'),
    slivers: [
      SliverPersistentHeader(
        pinned: true,
        delegate: _DashboardStickyIdentityHeaderDelegate(...),
      ),
      SliverToBoxAdapter(
        child: _DashboardEditorialHeroCard(...),
      ),
      // grouped utility sections below
    ],
  ),
);
```

The implementation can use `NestedScrollView`, `LayoutBuilder`, or a custom `SliverPersistentHeaderDelegate` if that yields cleaner scroll behavior, but the final effect must be:

- one continuous scroll view
- hero scrolls away
- identity row persists as translucent chrome

- [ ] **Step 2: Remove in-feed alert cards and budget banners from Home**

Delete or bypass the logic that renders:

```dart
if (overBudgetCount > 0 && !_bannerDismissed) BudgetWarningBanner(...)
if (highlightedAlert != null) InAppAlertBanner(...)
```

Keep:

- `activeAlertsProvider`
- `_showNotificationsSheet()`
- `_handleAlertAction()`

This preserves notifications behavior while removing dashboard clutter.

- [ ] **Step 3: Replace the generic `Conscia` app bar title with a personal header model**

Introduce a shared identity row model that exposes:

- profile image/avatar
- `Welcome back`
- display name fallback logic
- notification bell

Suggested fallback order for the name:

```dart
final profile = ref.watch(userProvider).valueOrNull;
final greetingName =
    profile?.name?.trim().isNotEmpty == true
        ? profile!.name!.trim()
        : profile?.email.split('@').first ?? 'there';
```

If the user model does not yet expose `name` or `photoUrl`, wire the UI through optional fields or local fallback helpers rather than blocking the redesign.

- [ ] **Step 4: Redesign the hero to be full-bleed and utility-grounded**

Refactor `_DashboardEditorialHeroCard` so it becomes:

- full-width
- reaches into top safe area
- uses `paper`, `amberSoft`, `navySoft`, and supporting token tints
- includes:
  - identity row
  - primary monthly summary
  - one concise support line
  - quick links grounded in real Conscia routes like Journey, Insights, Add transaction

Avoid adding fictional banking actions or synthetic account modules.

- [ ] **Step 5: Make the sticky identity header translucent and scroll-reactive**

Implement a pinned header that changes opacity/elevation based on scroll progress.

Target behavior:

```dart
Container(
  key: const ValueKey('dashboard-sticky-identity-header'),
  decoration: BoxDecoration(
    color: colors.paper.withValues(alpha: progress),
    border: progress > 0.85
        ? Border(bottom: BorderSide(color: colors.border))
        : null,
  ),
)
```

Only the identity row persists. The summary metrics and quick links do not.

## Task 3: Reorganize Home Utility Content Beneath The Hero

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/dashboard/widgets/budget_summary_card.dart`
- Modify: `app/lib/screens/dashboard/widgets/recent_transaction_tile.dart`

- [ ] **Step 1: Convert the budgets presentation away from the old horizontally scrolling dashboard strip if needed**

The new Home should feel more organized and less card-fragmented.

Refactor the budgets area toward one of these approved grouped treatments:

- a grouped white card with internal rows and separators
- a tighter vertically stacked budget summary list

Do not keep the old “carousel of mini cards” if it fights the calmer Home hierarchy.

- [ ] **Step 2: Keep recent transactions as grouped utility content**

Preserve the grouped list card pattern for recent transactions and ensure it sits visually below the hero with clean section spacing:

```dart
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  sliver: SliverToBoxAdapter(
    child: GroupedListCard(
      children: [...],
    ),
  ),
)
```

- [ ] **Step 3: Ensure lower content can remain visible behind the floating dock**

Adjust bottom spacing and shell integration so the lower Home content remains visually present behind the dock rather than disappearing behind an opaque blocked-off footer.

This may require reducing opaque footer layers or adjusting `MainShell` content padding rather than changing Home alone.

## Task 4: Update Dock/Shell Integration For Transparent Underlay Behavior

**Files:**
- Modify: `app/lib/widgets/main_shell.dart`
- Modify: `app/lib/widgets/floating_dock_nav.dart`
- Modify: `app/test/widgets/main_shell_test.dart`

- [ ] **Step 1: Write or update a failing shell test for transparent underlay expectations**

Add a structural test that verifies the shell does not inject an opaque footer band behind the dock on mobile Home layouts.

Example assertion:

```dart
testWidgets('MainShell overlays the floating dock without an opaque bottom bar',
    (tester) async {
  await _pumpShell(tester);

  expect(find.byType(BottomAppBar), findsNothing);
  expect(find.byType(NavigationBar), findsNothing);
});
```

- [ ] **Step 2: Refine shell padding so content extends behind the dock**

Adjust the shell/body composition so:

- the dock overlays content
- the content keeps enough bottom padding for usability
- the region behind the dock is not painted as a separate opaque slab

- [ ] **Step 3: Re-run shell tests after integration changes**

Run:

```bash
flutter test test/widgets/main_shell_test.dart -r compact
```

Expected:

- shell tests pass
- floating dock behavior remains intact

## Task 5: Verify Home Redesign And Commit

**Files:**
- Modify and stage all files touched above

- [ ] **Step 1: Run focused analysis**

Run:

```bash
flutter analyze lib/screens/dashboard/dashboard_screen.dart lib/widgets/main_shell.dart lib/widgets/floating_dock_nav.dart test/screens/dashboard/dashboard_alerts_test.dart test/widgets/main_shell_test.dart
```

Expected:

- analyze exits `0`

- [ ] **Step 2: Run focused Home verification**

Run:

```bash
flutter test test/screens/dashboard/dashboard_alerts_test.dart test/widgets/main_shell_test.dart -r compact
```

Expected:

- all Home/shell tests pass

- [ ] **Step 3: Run one regression check that Home still routes and renders inside the app shell**

Run:

```bash
flutter test test/core/routing/app_router_test.dart -r compact
```

Expected:

- routing suite still passes for the shell after the Home/header refactor

- [ ] **Step 4: Commit the Home redesign**

Run:

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart app/lib/widgets/main_shell.dart app/lib/widgets/floating_dock_nav.dart app/test/screens/dashboard/dashboard_alerts_test.dart app/test/widgets/main_shell_test.dart docs/superpowers/specs/2026-05-13-home-screen-redesign-design.md docs/superpowers/plans/2026-05-13-home-screen-redesign.md
git add -u
git commit -m "feat: redesign home screen editorial hierarchy"
```

Expected:

- commit succeeds on the current feature branch

## Self-Review

- Spec coverage: the plan covers hero-first Home, no alert cards, personal header, full-bleed editorial treatment, sticky translucent identity header, and transparent underlay behind the dock.
- Placeholder scan: every task contains concrete files and commands.
- Type consistency: all file paths and screen names match the current repo structure and existing dashboard naming.
