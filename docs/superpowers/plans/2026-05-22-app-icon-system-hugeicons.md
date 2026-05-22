# App Icon System Hugeicons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace remaining direct app icon usage with the shared Hugeicons system, keep `ConsciaGlyph` as the common rendering helper, and lighten category icon stroke weight across transaction-heavy surfaces.

**Architecture:** The work starts by strengthening shared icon primitives so the rest of the app can migrate through existing seams instead of ad hoc inline icons. After that, migrate feature areas in small batches, updating tests as each batch lands, and finish with a shared verification sweep focused on category-heavy UI.

**Tech Stack:** Flutter, Dart, Hugeicons (`stroke_rounded`), existing `ConsciaGlyph` / `CategoryIcons` / `AppIcons` helpers, Flutter widget tests, `flutter analyze`

---

## File Structure

- Modify: `app/lib/widgets/glyphs/conscia_glyph.dart`
  Purpose: Keep Hugeicons rendering centralized and add any missing semantic glyph support needed by the sweep.
- Modify: `app/lib/core/constants/category_icons.dart`
  Purpose: Reduce category stroke weight at the helper level and keep badge/raw icon behavior consistent.
- Modify: `app/lib/core/constants/app_icons.dart`
  Purpose: Replace Material/Cupertino `IconData` catalog behavior with shared app-owned Hugeicons widgets/helpers.
- Modify: `app/lib/widgets/*.dart`
  Purpose: Migrate shared reusable widgets off direct `Icons.*` usage first so feature screens inherit the new system.
- Modify: `app/lib/screens/**/*.dart`
  Purpose: Replace remaining direct icons in feature areas with `ConsciaGlyph` / `AppIcons` helpers.
- Modify: `app/test/**/*.dart`
  Purpose: Update shared icon tests and targeted screen tests touched by the migration.

### Task 1: Strengthen Shared Icon Primitives

**Files:**
- Modify: `app/lib/widgets/glyphs/conscia_glyph.dart`
- Modify: `app/lib/core/constants/app_icons.dart`
- Modify: `app/lib/core/constants/category_icons.dart`
- Test: `app/test/widgets/conscia_glyph_test.dart`

- [ ] **Step 1: Write the failing helper tests**

```dart
testWidgets('category badge uses a lighter stroke treatment', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: _CategoryBadgeHarness(),
      ),
    ),
  );

  final hugeIcon = tester.widget<HugeIcon>(find.byType(HugeIcon).first);
  expect(hugeIcon.strokeWidth, lessThan(20 * 0.11));
});

testWidgets('app icon helper renders hugeicons instead of material icons', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppIcons.icon(AppIconKey.search, color: Colors.black),
      ),
    ),
  );

  expect(find.byType(HugeIcon), findsOneWidget);
  expect(find.byType(Icon), findsNothing);
});
```

- [ ] **Step 2: Run the focused helper tests to verify failure**

Run: `flutter test test/widgets/conscia_glyph_test.dart`

Expected: FAIL because the current tests do not cover the new helper behavior and `AppIcons.icon(...)` / `AppIconKey` do not exist yet.

- [ ] **Step 3: Implement the shared helper changes**

```dart
enum AppIconKey {
  add,
  close,
  check,
  chevronLeft,
  chevronRight,
  search,
  refresh,
  edit,
  delete,
  warning,
  error,
  eye,
  eyeOff,
  home,
  homeActive,
  transactions,
  transactionsActive,
  scan,
  assistant,
  assistantActive,
  settings,
  settingsActive,
  family,
  person,
}

abstract class AppIcons {
  static Widget icon(
    AppIconKey key, {
    required Color color,
    double size = 20,
    double? strokeWidth,
    Key? keyId,
  }) {
    return ConsciaGlyph(
      key: keyId,
      kind: _kindFor(key),
      color: color,
      size: size,
      strokeWidth: strokeWidth,
    );
  }

  static ConsciaGlyphKind _kindFor(AppIconKey key) => switch (key) {
        AppIconKey.search => ConsciaGlyphKind.search,
        AppIconKey.refresh => ConsciaGlyphKind.recurring,
        AppIconKey.chevronLeft => ConsciaGlyphKind.chevronLeft,
        AppIconKey.chevronRight => ConsciaGlyphKind.chevronRight,
        AppIconKey.warning => ConsciaGlyphKind.alert,
        AppIconKey.error => ConsciaGlyphKind.signal,
        AppIconKey.family => ConsciaGlyphKind.family,
        AppIconKey.person => ConsciaGlyphKind.person,
        // continue mapping every shared utility key
      };
}
```

```dart
return ConsciaGlyph.category(
  visual.iconKey,
  size: size,
  color: visual.accent,
  strokeWidth: size * 0.085,
);
```

- [ ] **Step 4: Run the helper tests to verify they pass**

Run: `flutter test test/widgets/conscia_glyph_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/glyphs/conscia_glyph.dart app/lib/core/constants/app_icons.dart app/lib/core/constants/category_icons.dart app/test/widgets/conscia_glyph_test.dart
git commit -m "refactor(app): centralize hugeicons helpers"
```

### Task 2: Migrate Shared Reusable Widgets

**Files:**
- Modify: `app/lib/widgets/amount_hero_field.dart`
- Modify: `app/lib/widgets/editorial_sticky_header.dart`
- Modify: `app/lib/widgets/currency_picker_sheet.dart`
- Modify: `app/lib/widgets/feeling_choice_button.dart`
- Modify: `app/lib/widgets/hero_shortcut_card.dart`
- Modify: `app/lib/widgets/premium_upgrade_dialog.dart`
- Modify: `app/lib/widgets/selection_card_group.dart`
- Modify: `app/lib/widgets/single_select_list.dart`
- Modify: `app/lib/widgets/speed_dial_fab.dart`
- Modify: `app/lib/widgets/recurring_schedule_section.dart`
- Modify: `app/lib/widgets/scope_selector.dart`
- Test: `app/test/widgets/selection_card_group_test.dart`

- [ ] **Step 1: Write a focused widget test around one shared widget that currently uses `Icon`**

```dart
testWidgets('selection card group uses shared hugeicon checkmark', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionCardGroup<String>(
          options: const ['A'],
          value: 'A',
          onChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.byType(HugeIcon), findsWidgets);
});
```

- [ ] **Step 2: Run the shared widget test to verify failure**

Run: `flutter test test/widgets/selection_card_group_test.dart`

Expected: FAIL because the widget still renders a Material `Icon`.

- [ ] **Step 3: Replace direct `Icons.*` usage in shared widgets with `AppIcons.icon(...)` or semantic `ConsciaGlyph(...)`**

```dart
trailing: selected
    ? AppIcons.icon(
        AppIconKey.check,
        color: Colors.white,
        size: 14,
      )
    : null,
```

```dart
prefixIcon: Padding(
  padding: const EdgeInsets.all(12),
  child: AppIcons.icon(
    AppIconKey.search,
    color: colors.onSurfaceVariant,
    size: 18,
  ),
),
```

- [ ] **Step 4: Run the shared widget test to verify pass**

Run: `flutter test test/widgets/selection_card_group_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/amount_hero_field.dart app/lib/widgets/editorial_sticky_header.dart app/lib/widgets/currency_picker_sheet.dart app/lib/widgets/feeling_choice_button.dart app/lib/widgets/hero_shortcut_card.dart app/lib/widgets/premium_upgrade_dialog.dart app/lib/widgets/selection_card_group.dart app/lib/widgets/single_select_list.dart app/lib/widgets/speed_dial_fab.dart app/lib/widgets/recurring_schedule_section.dart app/lib/widgets/scope_selector.dart app/test/widgets/selection_card_group_test.dart
git commit -m "refactor(app): migrate shared widgets to hugeicons"
```

### Task 3: Migrate Transactions and Category-Heavy Surfaces

**Files:**
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/transactions/widgets/editorial_transaction_row.dart`
- Modify: `app/lib/screens/transactions/widgets/transaction_tile.dart`
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Modify: `app/lib/screens/transactions/widgets/quick_preset_chips.dart`
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/insights/widgets/insight_transaction_card.dart`
- Modify: `app/lib/screens/insights/widgets/category_trend_card.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_card.dart`
- Test: `app/test/screens/transactions/transaction_list_screen_test.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Write the failing transaction-focused tests**

```dart
testWidgets('transaction list filter chips render hugeicons', (tester) async {
  await tester.pumpWidget(buildTransactionListScreen());

  expect(find.byType(HugeIcon), findsWidgets);
  expect(find.byIcon(Icons.shopping_cart_rounded), findsNothing);
});

testWidgets('transaction tile category badge uses lighter hugeicon stroke', (
  tester,
) async {
  await tester.pumpWidget(buildTransactionTileHarness());

  final hugeIcon = tester.widget<HugeIcon>(find.byType(HugeIcon).first);
  expect(hugeIcon.strokeWidth, lessThan(2.2));
});
```

- [ ] **Step 2: Run the transaction-focused tests to verify failure**

Run: `flutter test test/screens/transactions/transaction_list_screen_test.dart`

Expected: FAIL because the screen still contains direct Material icons and the category stroke expectation has not been asserted yet.

- [ ] **Step 3: Migrate transaction and adjacent category-heavy surfaces**

```dart
icon: AppIcons.icon(
  AppIconKey.add,
  color: colors.deepNavy,
  size: 18,
),
```

```dart
child: AppIcons.icon(
  AppIconKey.refresh,
  color: colors.onSurfaceVariant,
  size: 18,
),
```

```dart
trailing: AppIcons.icon(
  AppIconKey.chevronRight,
  color: colors.softInk,
  size: 18,
),
```

- [ ] **Step 4: Run the transaction-focused tests to verify pass**

Run: `flutter test test/screens/transactions/transaction_list_screen_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/transactions/transaction_list_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/transactions/widgets/editorial_transaction_row.dart app/lib/screens/transactions/widgets/transaction_tile.dart app/lib/screens/transactions/widgets/category_picker.dart app/lib/screens/transactions/widgets/quick_preset_chips.dart app/lib/screens/dashboard/dashboard_screen.dart app/lib/screens/insights/widgets/insight_transaction_card.dart app/lib/screens/insights/widgets/category_trend_card.dart app/lib/screens/budgets/widgets/budget_card.dart app/test/screens/transactions/transaction_list_screen_test.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "refactor(app): migrate transaction surfaces to hugeicons"
```

### Task 4: Migrate Onboarding, Settings, Family, Receipts, and Journey Screens

**Files:**
- Modify: `app/lib/screens/onboarding/**/*.dart`
- Modify: `app/lib/screens/settings/**/*.dart`
- Modify: `app/lib/screens/family/**/*.dart`
- Modify: `app/lib/screens/receipts/**/*.dart`
- Modify: `app/lib/screens/journey/conscience_journey_screen.dart`
- Modify: `app/lib/screens/dashboard/widgets/*.dart`
- Modify: `app/lib/screens/insights/widgets/*.dart`
- Test: `app/test/screens/settings/settings_screen_location_test.dart`
- Test: `app/test/screens/family/family_invites_screen_test.dart`
- Test: `app/test/screens/journey/conscience_journey_screen_test.dart`

- [ ] **Step 1: Write a representative failing test for one migrated feature screen**

```dart
testWidgets('settings screen renders shared hugeicons for settings rows', (
  tester,
) async {
  await tester.pumpWidget(buildSettingsScreen());

  expect(find.byType(HugeIcon), findsWidgets);
  expect(find.byIcon(Icons.star_rounded), findsNothing);
});
```

- [ ] **Step 2: Run the representative screen tests to verify failure**

Run: `flutter test test/screens/settings/settings_screen_location_test.dart`

Expected: FAIL because the screen still uses raw Material icons in settings rows.

- [ ] **Step 3: Replace remaining direct icons in feature screens with shared helpers**

```dart
_SettingsRow(
  icon: AppIcons.icon(
    AppIconKey.download,
    color: colors.deepNavy,
    size: 18,
  ),
  title: 'Download my data',
  subtitle: 'Export your Conscia history as JSON',
)
```

```dart
leading: AppIcons.icon(
  AppIconKey.error,
  color: colors.expense,
  size: 16,
)
```

```dart
child: AppIcons.icon(
  AppIconKey.chevronLeft,
  color: colors.deepNavy,
  size: 20,
)
```

- [ ] **Step 4: Run the representative screen tests to verify pass**

Run: `flutter test test/screens/settings/settings_screen_location_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/onboarding app/lib/screens/settings app/lib/screens/family app/lib/screens/receipts app/lib/screens/journey/conscience_journey_screen.dart app/lib/screens/dashboard/widgets app/lib/screens/insights/widgets app/test/screens/settings/settings_screen_location_test.dart app/test/screens/family/family_invites_screen_test.dart app/test/screens/journey/conscience_journey_screen_test.dart
git commit -m "refactor(app): migrate feature screens to hugeicons"
```

### Task 5: Final Verification and Cleanup

**Files:**
- Modify: `app/test/**` as needed for final expectation updates only

- [ ] **Step 1: Run targeted verification for the shared helpers and key surfaces**

Run: `flutter test test/widgets/conscia_glyph_test.dart test/screens/transactions/transaction_list_screen_test.dart test/screens/settings/settings_screen_location_test.dart test/screens/family/family_invites_screen_test.dart test/screens/journey/conscience_journey_screen_test.dart`

Expected: PASS

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze lib test`

Expected: PASS

- [ ] **Step 3: Run a web smoke build**

Run: `flutter build web --debug`

Expected: PASS, with only any already-known non-blocking warnings.

- [ ] **Step 4: Review the worktree for unrelated changes before the final commit**

Run: `git status -sb`

Expected: only the intended app icon migration files are staged or modified; do not stage `app/lib/providers/admin_entitlement_provider.dart`, the generated Windows Flutter files, or `docs/superpowers/plans/2026-05-21-lifetime-premium-entitlements.md`.

- [ ] **Step 5: Commit the final cleanup if needed**

```bash
git add app/test
git commit -m "test(app): finalize hugeicons migration coverage"
```
