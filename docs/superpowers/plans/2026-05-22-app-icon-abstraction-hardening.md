# App Icon Abstraction Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Flutter app so all icon usage flows through app-owned icon abstractions, with a hard failing test that prevents direct toolkit icon usage outside the approved abstraction files.

**Architecture:** `AppIcons` will own all generic, product, platform, brand, and status icon semantics; `CategoryIcons` will own category icon selection; and `ConsciaGlyph` will remain the only concrete icon renderer. Feature code, presenters, and system state screens will stop returning or directly rendering `IconData`, `Icons.*`, `CupertinoIcons.*`, `HugeIcon(...)`, or `HugeIconsStrokeRounded.*`.

**Tech Stack:** Flutter, Dart, widget tests, grep-based enforcement test, `flutter analyze`

---

## File Structure

- Modify: `app/lib/core/constants/app_icons.dart`
  - Remove old `IconData`/adaptive API, expand semantic keys, keep current icon-pack mapping centralized.
- Modify: `app/lib/core/constants/category_icons.dart`
  - Keep category icon selection self-contained and ensure it remains one of the only approved icon-source files.
- Modify: `app/lib/widgets/glyphs/conscia_glyph.dart`
  - Keep the concrete Hugeicons renderer here only.
- Modify: feature clusters that still use direct toolkit icons:
  - `app/lib/screens/family/**`
  - `app/lib/screens/onboarding/**`
  - `app/lib/screens/receipts/**`
  - `app/lib/screens/settings/service_status_screen.dart`
  - `app/lib/screens/journey/**`
  - `app/lib/screens/dashboard/journey_home_presenter.dart`
  - `app/lib/screens/assistant/widgets/**`
  - `app/lib/app.dart`
  - remaining widget files surfaced by the enforcement scan
- Modify: test files that currently assert raw Material/Cupertino icon presence
- Create: `app/test/architecture/icon_abstraction_boundary_test.dart`
  - Hard failing architecture test for icon leakage

---

### Task 1: Normalize the Core Icon Abstraction

**Files:**
- Modify: `app/lib/core/constants/app_icons.dart`
- Modify: `app/test/widgets/scope_selector_test.dart`
- Modify: any tests still expecting `AppIcons.family` or other legacy `IconData` getters

- [ ] **Step 1: Add a failing architecture-oriented test for legacy `AppIcons` API removal**

Replace the current direct `AppIcons.family` expectation in `app/test/widgets/scope_selector_test.dart` with a widget-level expectation that renders the scope selector and confirms the family option still shows an app-owned icon widget.

Use this test shape:

```dart
testWidgets('uses the shared app icon helper for family scope', (tester) async {
  String selected = 'personal';

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScopeSelector(
          value: selected,
          familyEnabled: true,
          onChanged: (value) => selected = value,
        ),
      ),
    ),
  );

  expect(find.byType(HugeIcon), findsWidgets);
  expect(find.text('Family'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused test to verify it fails once legacy getters are removed**

Run:

```bash
flutter test test/widgets/scope_selector_test.dart
```

Expected: FAIL after removing the legacy getter-based API and before consumers are updated.

- [ ] **Step 3: Remove the old `IconData` helper surface from `app_icons.dart` and replace it with semantic keys only**

In `app/lib/core/constants/app_icons.dart`:
- delete `adaptive(...)`
- delete `IconData get ...` members such as `home`, `transactions`, `assistant`, `settings`, `family`, `sharedHome`, and the old profile-material getters
- expand `AppIconKey` to cover all remaining semantic cases, including brand/platform/service states such as:

```dart
appleBrand,
passkey,
serviceApi,
serviceDatabase,
serviceStorage,
serviceAi,
serviceHealth,
sessionExpired,
offlineDevice,
offlineCloud,
familyInvite,
household,
ownerAccess,
privacyBoundary,
merchantSuggestion,
info,
verified,
code,
photoLibrary,
receiptScan,
walletOutline,
sparkleGuidance,
timer,
tune,
lockClock,
```

Keep `AppIcons.icon(...)` as the single public rendering entry point.

- [ ] **Step 4: Update app-owned helper consumers that relied on removed `IconData` getters**

Replace helper calls such as:

```dart
icon: AppIcons.family,
```

with:

```dart
icon: AppIcons.icon(
  AppIconKey.family,
  color: colors.deepNavy,
  size: 18,
),
```

or convert the containing API to take `AppIconKey` instead of `IconData`.

- [ ] **Step 5: Run focused verification**

Run:

```bash
flutter test test/widgets/scope_selector_test.dart
flutter analyze lib/core/constants/app_icons.dart lib/widgets/glyphs/conscia_glyph.dart
```

Expected: PASS / no issues found.

- [ ] **Step 6: Commit**

```bash
git add app/lib/core/constants/app_icons.dart app/test/widgets/scope_selector_test.dart
git commit -m "refactor(app): simplify core icon abstraction"
```

---

### Task 2: Migrate Family and App-Shell Icon Leakage

**Files:**
- Modify: `app/lib/screens/family/family_space_settings_screen.dart`
- Modify: `app/lib/screens/family/family_members_screen.dart`
- Modify: `app/lib/screens/family/family_setup_screen.dart`
- Modify: `app/lib/app.dart`
- Test: corresponding family and app-shell tests

- [ ] **Step 1: Write or adjust focused tests to stop relying on raw Material icons**

Update existing tests in:
- `app/test/screens/family/family_space_settings_screen_test.dart`
- `app/test/screens/family/family_members_screen_test.dart` (create if missing)

to assert text, actions, and app-owned icon behavior rather than `find.byIcon(Icons.*)`.

Use expectations like:

```dart
expect(find.text('Invite family'), findsWidgets);
expect(find.byType(HugeIcon), findsWidgets);
```

- [ ] **Step 2: Run focused family tests to capture current failures**

Run:

```bash
flutter test test/screens/family/family_space_settings_screen_test.dart
```

Expected: existing tests should pass now, but new/updated icon-boundary expectations should fail until migration is complete.

- [ ] **Step 3: Replace direct icon usage in family screens with semantic app-owned keys**

In `family_space_settings_screen.dart` and `family_members_screen.dart`, replace direct usages such as:

```dart
icon: Icons.person_add_alt_1_outlined,
icon: Icons.home_outlined,
icon: Icons.verified_user_outlined,
icon: Icons.lock_outline_rounded,
Icons.chevron_right_rounded,
Icons.more_vert_rounded,
```

with semantic `AppIconKey` values such as:

```dart
AppIconKey.familyInvite
AppIconKey.household
AppIconKey.ownerAccess
AppIconKey.privacyBoundary
AppIconKey.chevronRight
AppIconKey.more
```

and render them through `AppIcons.icon(...)`.

- [ ] **Step 4: Migrate app-shell blocker icons in `app/lib/app.dart`**

Change `_BlockerContent.icon` from `IconData` to `AppIconKey`:

```dart
final AppIconKey icon;
```

Map states semantically:

```dart
AvailabilityIssue.deviceOffline => AppIconKey.offlineDevice,
AvailabilityIssue.apiUnavailable => AppIconKey.offlineCloud,
AvailabilityIssue.updateRequired => AppIconKey.serviceHealth,
AvailabilityIssue.none => AppIconKey.verified,
```

Render via:

```dart
AppIcons.icon(
  blocker.icon,
  color: theme.colorScheme.onSurfaceVariant,
  size: 64,
)
```

Do the same for the retry/update button icon.

- [ ] **Step 5: Run focused verification**

Run:

```bash
flutter test test/screens/family/family_space_settings_screen_test.dart
flutter analyze lib/screens/family/family_space_settings_screen.dart lib/screens/family/family_members_screen.dart lib/screens/family/family_setup_screen.dart lib/app.dart
```

Expected: PASS / no issues found.

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/family app/lib/app.dart app/test/screens/family
git commit -m "refactor(app): migrate family and shell icons"
```

---

### Task 3: Migrate Onboarding and Auth Flows

**Files:**
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_up_screen.dart`
- Modify: `app/lib/screens/onboarding/verify_email_screen.dart`
- Modify: `app/lib/screens/onboarding/about_you_screen.dart`
- Modify: `app/lib/screens/onboarding/setup_screen.dart`
- Modify: `app/lib/screens/onboarding/spending_profile_screen.dart`
- Modify: `app/lib/screens/onboarding/suggested_budgets_screen.dart`
- Modify: `app/lib/screens/onboarding/session_expired_screen.dart`
- Modify: `app/lib/screens/onboarding/apple_button.dart`
- Modify: `app/lib/core/assets/onboarding_illustrations.dart`
- Test: onboarding widget tests already in `app/test/screens/onboarding/**`

- [ ] **Step 1: Update onboarding tests to avoid raw icon assertions**

Where tests currently use `find.byIcon(Icons.*)`, replace those with:
- text assertions
- `HugeIcon` presence
- semantic structure expectations

Examples to update:
- `app/test/screens/onboarding/onboarding_flow_test.dart`
- `app/test/screens/budgets/widgets/budget_form_sheet_test.dart`
- `app/test/widgets/locale_picker_sheet_test.dart`

- [ ] **Step 2: Run focused onboarding tests to surface remaining icon leaks**

Run:

```bash
flutter test test/screens/onboarding
```

Expected: failures in screens still using direct toolkit icons.

- [ ] **Step 3: Replace all onboarding/auth direct icons with semantic keys**

Introduce keys like:

```dart
appleBrand,
passkey,
email,
lock,
visibility,
visibilityOff,
code,
verified,
timer,
tune,
sessionExpired,
sparkleGuidance,
walletOutline,
language,
```

Then replace usages such as:

```dart
const Icon(Icons.apple, size: 24)
const Icon(Icons.email_outlined)
const Icon(Icons.lock_outline_rounded)
Icons.visibility_outlined
Icons.visibility_off_outlined
Icons.mark_email_read_outlined
Icons.code
Icons.monetization_on_outlined
Icons.language
Icons.lock_clock_outlined
```

with `AppIcons.icon(...)`.

- [ ] **Step 4: Convert onboarding illustration descriptors from `IconData` to `AppIconKey` where needed**

If `onboarding_illustrations.dart` stores raw `IconData`, change the model so illustration descriptors store:

```dart
final AppIconKey iconKey;
```

and render through `AppIcons.icon(...)`.

- [ ] **Step 5: Run focused verification**

Run:

```bash
flutter test test/screens/onboarding
flutter analyze lib/screens/onboarding lib/core/assets/onboarding_illustrations.dart
```

Expected: PASS / no issues found.

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/onboarding app/lib/core/assets/onboarding_illustrations.dart app/test/screens/onboarding
git commit -m "refactor(app): migrate onboarding icons"
```

---

### Task 4: Migrate Receipts, Journey, Assistant, and Remaining Widgets

**Files:**
- Modify: `app/lib/screens/receipts/**`
- Modify: `app/lib/screens/journey/**`
- Modify: `app/lib/screens/dashboard/journey_home_presenter.dart`
- Modify: `app/lib/screens/assistant/widgets/ai_message_bubble.dart`
- Modify: `app/lib/screens/dashboard/widgets/**` files still using direct icons
- Modify: `app/lib/screens/settings/service_status_screen.dart`
- Modify: `app/lib/core/assets/app_icons.dart` if direct Hugeicons remain there
- Test: focused dashboard/journey/receipts/settings tests

- [ ] **Step 1: Write or update focused tests around the remaining icon-heavy surfaces**

Target at least:
- `app/test/screens/settings/service_status_screen_test.dart`
- `app/test/screens/dashboard/journey_led_home_sections_test.dart`
- `app/test/screens/insights/insights_screen_test.dart`

Adjust expectations away from raw icon classes and toward app-owned behavior.

- [ ] **Step 2: Run focused tests to expose remaining leaks**

Run:

```bash
flutter test test/screens/settings/service_status_screen_test.dart test/screens/dashboard/journey_led_home_sections_test.dart test/screens/insights/insights_screen_test.dart
```

Expected: failures only where direct icon usage remains.

- [ ] **Step 3: Convert journey presenter outputs from `IconData` to semantic `AppIconKey`**

In `app/lib/screens/dashboard/journey_home_presenter.dart`:
- change `JourneyHomeAction.icon` and `JourneyHomePatternSignal.icon` from `IconData` to `AppIconKey`
- map quest/pattern keys semantically:

```dart
'reflect_three_purchases' => AppIconKey.receipt,
'check_before_purchase' => AppIconKey.ai,
'review_regret_pattern' => AppIconKey.recurring,
'read_two_insights' => AppIconKey.pieChart,
'create_budget_guardrail' => AppIconKey.wallet,
'send_family_invite' => AppIconKey.familyInvite,
'add_family_expense' => AppIconKey.receipt,
```

Update all consumers to render via `AppIcons.icon(...)`.

- [ ] **Step 4: Replace remaining direct icon usage in receipts, service status, assistant bubbles, and dashboard widgets**

Migrate representative leaks such as:

```dart
Icons.document_scanner_rounded
Icons.camera_alt_rounded
Icons.photo_library_rounded
Icons.error_outline_rounded
Icons.calendar_today_rounded
Icons.auto_awesome_rounded
Icons.warning_amber_rounded
Icons.cloud_off
Icons.storage
Icons.dns
Icons.table_chart
Icons.auto_awesome
```

to semantic keys like:

```dart
receiptScan,
camera,
photoLibrary,
error,
calendar,
sparkleGuidance,
warning,
offlineCloud,
serviceStorage,
serviceApi,
serviceDatabase,
serviceAi,
```

- [ ] **Step 5: Replace direct `HugeIcon(...)` usage in feature widgets**

Any feature widget still doing:

```dart
HugeIcon(
  icon: HugeIconsStrokeRounded...
```

must instead use:

```dart
AppIcons.icon(...)
```

or `ConsciaGlyph` where category/domain semantics are more appropriate.

- [ ] **Step 6: Run focused verification**

Run:

```bash
flutter test test/screens/settings/service_status_screen_test.dart test/screens/dashboard/journey_led_home_sections_test.dart test/screens/insights/insights_screen_test.dart test/screens/dashboard/dashboard_alerts_test.dart
flutter analyze lib/screens/receipts lib/screens/journey lib/screens/dashboard lib/screens/assistant/widgets lib/screens/settings/service_status_screen.dart
```

Expected: PASS / no issues found.

- [ ] **Step 7: Commit**

```bash
git add app/lib/screens/receipts app/lib/screens/journey app/lib/screens/dashboard app/lib/screens/assistant/widgets app/lib/screens/settings/service_status_screen.dart app/test/screens/settings/service_status_screen_test.dart app/test/screens/dashboard app/test/screens/insights/insights_screen_test.dart
git commit -m "refactor(app): migrate remaining feature icons"
```

---

### Task 5: Add and Enforce the Architecture Boundary Test

**Files:**
- Create: `app/test/architecture/icon_abstraction_boundary_test.dart`

- [ ] **Step 1: Write the failing boundary test**

Create `app/test/architecture/icon_abstraction_boundary_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app lib does not bypass the icon abstraction boundary', () {
    final libDir = Directory('lib');
    final allowed = {
      'core/constants/app_icons.dart',
      'core/constants/category_icons.dart',
      'widgets/glyphs/conscia_glyph.dart',
    };
    final forbiddenPatterns = [
      'Icons.',
      'CupertinoIcons.',
      'HugeIcon(',
      'HugeIconsStrokeRounded.',
    ];

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      final relative = normalized.split('/lib/').last;
      if (allowed.contains(relative)) continue;

      final source = entity.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (source.contains(pattern)) {
          violations.add('$relative -> $pattern');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails before the migration is complete**

Run:

```bash
flutter test test/architecture/icon_abstraction_boundary_test.dart
```

Expected: FAIL listing remaining files that still violate the boundary.

- [ ] **Step 3: Re-run the boundary test after completing Tasks 1–4**

Run:

```bash
flutter test test/architecture/icon_abstraction_boundary_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add app/test/architecture/icon_abstraction_boundary_test.dart
git commit -m "test(app): enforce icon abstraction boundary"
```

---

### Task 6: Final Verification

**Files:**
- Verify only

- [ ] **Step 1: Run the final architecture and regression checks**

Run:

```bash
flutter test test/architecture/icon_abstraction_boundary_test.dart
flutter test
flutter analyze
```

Expected:
- icon-boundary test passes
- full app test suite passes
- analyzer passes

- [ ] **Step 2: Confirm no direct icon leakage remains in `app/lib`**

Run:

```bash
rg -n "Icons\\.|CupertinoIcons\\.|HugeIcon\\(|HugeIconsStrokeRounded\\." app/lib
```

Expected: no matches outside the allowed abstraction files.

- [ ] **Step 3: Commit only if final cleanup was required**

```bash
git add app/lib app/test
git commit -m "refactor(app): finalize icon abstraction cleanup"
```

Only do this step if the final verification phase required additional code changes.
