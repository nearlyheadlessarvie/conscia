# App Redesign, Voice Input, Regret Alerts, and Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a shared redesign foundation, apply it across the core app screens, complete voice input, build the full regret-memory alert system, and redesign the `web/` landing page to match.

**Architecture:** Build a shared UI foundation in the Flutter theme and widget layers first, then migrate high-traffic screens onto four canonical templates: dashboard feed, hero input, preference form, and guided wizard. Once those patterns are stable, complete voice input inside the hero-input flow, add a reusable regret-alert system across backend and dashboard surfaces, and finally redesign the Astro landing page using the same visual language and real updated app surfaces.

**Tech Stack:** Flutter, Riverpod, GoRouter, .NET 8, DynamoDB-backed transaction history, Astro, Tailwind, existing Conscia theme/icon systems.

---

## File Structure

- `app/lib/core/theme/app_theme.dart`
  Expand theme tokens, surface treatments, and component defaults for the new redesign language.
- `app/lib/core/theme/app_colors.dart`
  Add any missing semantic color roles for feed cards, alerts, voice states, and landing-page-aligned surfaces.
- `app/lib/widgets/main_shell.dart`
  Redesign shell chrome and navigation rhythm.
- `app/lib/widgets/amount_input_field.dart`
  Finalize shared hero-input treatment for transaction and assistant flows.
- `app/lib/widgets/conscience_mark.dart`
  Tone motion down later and align loader presentation to the new system.
- `app/lib/widgets/`
  New shared primitives such as section containers, screen headers, feed cards, chip groups, and alert shells.
- `app/lib/screens/dashboard/`
  Migrate dashboard to the feed template and integrate real regret alerts.
- `app/lib/screens/transactions/transaction_form_screen.dart`
  Migrate to the hero-input template and wire completed voice input.
- `app/lib/screens/assistant/pre_purchase_screen.dart`
  Migrate to the hero-input template and share voice/suggestion behavior.
- `app/lib/screens/settings/settings_screen.dart`
  Migrate to the preference-form template.
- `app/lib/screens/settings/profile_screen.dart`
  Migrate to the preference-form template.
- `app/lib/screens/onboarding/`
  Apply the guided-wizard template after the shared system is stable.
- `app/lib/screens/transactions/widgets/voice_input_button.dart`
  Complete the unfinished voice input flow.
- `app/lib/providers/` and `app/lib/services/`
  Support voice-input state and new alert consumption where needed.
- `src/Conscia.Application/`
  Add regret-alert generation services/models.
- `src/Conscia.Api/Endpoints/`
  Expose regret-alert data if new endpoints are needed.
- `src/Conscia.Infrastructure/`
  Back any alert data access with repository logic if needed.
- `web/src/components/`
  Redesign hero, features, pricing, and supporting sections.
- `web/src/pages/index.astro`
  Recompose the landing page using the new component language.
- `web/src/styles/global.css`
  Align tokens, spacing, and visual atmosphere with the app refresh.
- `app/test/`
  Widget coverage for redesigned screens and voice-input states.
- `tests/Conscia.Tests.Unit/`
  Coverage for regret-alert generation and any new endpoint/service logic.

---

### Task 1: Capture The New Visual Foundation In Theme And Shared Widgets

**Files:**
- Modify: `app/lib/core/theme/app_theme.dart`
- Modify: `app/lib/core/theme/app_colors.dart`
- Create: `app/lib/widgets/screen_section.dart`
- Create: `app/lib/widgets/feed_card.dart`
- Create: `app/lib/widgets/selection_chip_group.dart`
- Create: `app/lib/widgets/hero_screen_scaffold.dart`
- Test: `app/test/widgets/selection_chip_group_test.dart`

- [ ] **Step 1: Write the failing widget tests for the new shared primitives**

Add a widget test file that expects:
- selection chips render consistent spacing and selected state
- feed card uses the updated rounded surface treatment

```dart
testWidgets('selection chip group highlights the active option', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: SelectionChipGroup(
          options: ['One', 'Two'],
          value: 'Two',
        ),
      ),
    ),
  );

  expect(find.text('One'), findsOneWidget);
  expect(find.text('Two'), findsOneWidget);
  expect(find.byKey(const ValueKey('selection-chip-Two-selected')), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused widget tests to verify they fail**

Run: `flutter test test/widgets/selection_chip_group_test.dart`
Expected: FAIL because the new shared widgets do not exist yet.

- [ ] **Step 3: Add the shared widget primitives and theme hooks**

Implement minimal reusable shells first:

```dart
class ScreenSection extends StatelessWidget {
  const ScreenSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Re-run the focused widget tests**

Run: `flutter test test/widgets/selection_chip_group_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/theme/app_theme.dart app/lib/core/theme/app_colors.dart app/lib/widgets/screen_section.dart app/lib/widgets/feed_card.dart app/lib/widgets/selection_chip_group.dart app/lib/widgets/hero_screen_scaffold.dart app/test/widgets/selection_chip_group_test.dart
git commit -m "feat: add redesigned app ui foundation"
```

### Task 2: Redesign Main Shell And Shared Screen Scaffolds

**Files:**
- Modify: `app/lib/widgets/main_shell.dart`
- Test: `app/test/widgets/main_shell_test.dart`

- [ ] **Step 1: Write a failing shell test for the new shared chrome assumptions**

Add a test that verifies the shell still renders the raised scan action and preserves the shared destination structure while using the new scaffold rhythm.

```dart
testWidgets('main shell keeps the raised scan action and nav destinations', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: MainShell(child: SizedBox())));

  expect(find.byKey(const ValueKey('main-shell-scan-button')), findsOneWidget);
  expect(find.text('Home'), findsOneWidget);
  expect(find.text('Assistant'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused shell test to verify it fails for the new expectations**

Run: `flutter test test/widgets/main_shell_test.dart`
Expected: FAIL if the test references new structure not yet present.

- [ ] **Step 3: Update the shell to the new design rhythm**

Keep route behavior intact while improving spacing, bar/background treatment, and wide-layout consistency.

- [ ] **Step 4: Re-run the shell test**

Run: `flutter test test/widgets/main_shell_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/main_shell.dart app/test/widgets/main_shell_test.dart
git commit -m "feat: redesign app shell chrome"
```

### Task 3: Apply The New Feed Template To Dashboard

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/dashboard/widgets/*.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Add a failing dashboard test that still expects the key feed sections to render under the new layout**

```dart
testWidgets('dashboard feed renders budgets, reflect, and recent transactions sections', (tester) async {
  await tester.pumpWidget(await buildDashboardApp(tester));

  expect(find.text('Budgets'), findsOneWidget);
  expect(find.text('Reflect'), findsOneWidget);
  expect(find.text('Recent Transactions'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused dashboard tests to verify the first redesign pass breaks expectations**

Run: `flutter test test/screens/dashboard/dashboard_alerts_test.dart`
Expected: FAIL after you adjust the test for the new section wrappers and before implementation is complete.

- [ ] **Step 3: Migrate dashboard onto the feed template**

Use the new `ScreenSection` and `FeedCard` primitives instead of per-widget ad hoc spacing and wrappers.

- [ ] **Step 4: Re-run dashboard tests**

Run: `flutter test test/screens/dashboard/dashboard_alerts_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart app/lib/screens/dashboard/widgets app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat: redesign dashboard feed"
```

### Task 4: Apply The Hero Input Template To Transaction Entry And Assistant

**Files:**
- Modify: `app/lib/widgets/amount_input_field.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 1: Add failing tests for hero-input structure and shared amount-input usage**

```dart
testWidgets('transaction form renders the shared hero amount input first', (tester) async {
  await tester.pumpWidget(await buildTransactionFormApp(tester));

  expect(find.byType(AmountInputField), findsOneWidget);
  expect(find.text('Category'), findsOneWidget);
});
```

```dart
testWidgets('pre-purchase assistant renders the shared hero amount input', (tester) async {
  await tester.pumpWidget(await buildPrePurchaseApp(tester));

  expect(find.byType(AmountInputField), findsOneWidget);
  expect(find.text('Category'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused hero-input tests to verify the new layout assumptions fail**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart`
Expected: FAIL if the restructured layout is not yet implemented.

- [ ] **Step 3: Redesign both screens around the shared hero-input pattern**

Do not change transaction semantics. Only unify layout, hierarchy, and shared input affordances.

- [ ] **Step 4: Re-run the focused tests**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/amount_input_field.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/assistant/pre_purchase_screen.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: redesign hero input screens"
```

### Task 5: Redesign Settings, Profile, And Onboarding Templates

**Files:**
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/settings/profile_screen.dart`
- Modify: `app/lib/screens/onboarding/*.dart`
- Test: `app/test/screens/settings/profile_screen_test.dart`
- Test: `app/test/screens/onboarding/onboarding_flow_test.dart`

- [ ] **Step 1: Add failing tests for the shared preference/wizard structure**

Use existing behavior tests and add assertions around shared section/component usage where helpful.

- [ ] **Step 2: Run the focused settings/onboarding tests to verify red-state coverage**

Run: `flutter test test/screens/settings/profile_screen_test.dart test/screens/onboarding/onboarding_flow_test.dart`
Expected: FAIL if the new structure-specific assertions are not yet satisfied.

- [ ] **Step 3: Apply the preference-form and guided-wizard templates**

Keep the current logic and routing intact while replacing ad hoc spacing and wrappers with shared building blocks.

- [ ] **Step 4: Re-run the focused tests**

Run: `flutter test test/screens/settings/profile_screen_test.dart test/screens/onboarding/onboarding_flow_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/settings/settings_screen.dart app/lib/screens/settings/profile_screen.dart app/lib/screens/onboarding app/test/screens/settings/profile_screen_test.dart app/test/screens/onboarding/onboarding_flow_test.dart
git commit -m "feat: redesign settings and onboarding surfaces"
```

### Task 6: Complete Voice Input In Transaction And Assistant Flows

**Files:**
- Modify: `app/lib/screens/transactions/widgets/voice_input_button.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: any supporting providers/services required for speech capture or fallback state
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 1: Write failing tests for supported and unsupported voice states**

```dart
testWidgets('voice input shows fallback text when unavailable', (tester) async {
  await tester.pumpWidget(await buildTransactionFormApp(tester, voiceAvailable: false));

  expect(find.textContaining('Voice input unavailable'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused voice tests to verify they fail**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart`
Expected: FAIL because the completed voice states are not implemented yet.

- [ ] **Step 3: Finish the voice-input flow**

Ensure both screens can:
- launch voice capture when available
- present graceful unsupported/permission-denied states
- apply parsed values into the existing form fields without creating a second submission path

- [ ] **Step 4: Re-run the focused voice tests**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/transactions/widgets/voice_input_button.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/assistant/pre_purchase_screen.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: complete voice input flows"
```

### Task 7: Implement The Regret-Memory Alert Domain And Dashboard Surface

**Files:**
- Create or modify: `src/Conscia.Application/` alert generation services/models
- Modify: `src/Conscia.Api/Endpoints/` if new alert endpoints are needed
- Modify: `app/lib/providers/alert_provider.dart`
- Modify: `app/lib/screens/dashboard/widgets/in_app_alert_banner.dart`
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Test: `tests/Conscia.Tests.Unit/` for alert generation
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Write failing backend tests for regret-alert generation**

Add focused tests that cover at least:
- repeated regrets in the same merchant/category generate a single alert
- clustered impulse uncertainty generates a cooling-off style alert
- resolved/duplicate conditions do not emit duplicate alerts

- [ ] **Step 2: Run the focused backend tests to verify they fail**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~Regret|FullyQualifiedName~Alert"`
Expected: FAIL because the new alert generation logic does not exist yet.

- [ ] **Step 3: Implement the alert generation and app consumption**

Keep generation and presentation separate:

```csharp
public record RegretAlert(
    string Type,
    string Title,
    string Message,
    string? Merchant,
    string? Category,
    DateTime ObservedAt);
```

- [ ] **Step 4: Add dashboard rendering and deduped display**

Use the redesigned alert shell rather than one-off banner styling.

- [ ] **Step 5: Re-run backend and Flutter alert tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~Regret|FullyQualifiedName~Alert"`

Run: `flutter test test/screens/dashboard/dashboard_alerts_test.dart`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Application src/Conscia.Api/Endpoints app/lib/providers/alert_provider.dart app/lib/screens/dashboard/widgets/in_app_alert_banner.dart app/lib/screens/dashboard/dashboard_screen.dart tests/Conscia.Tests.Unit app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat: add regret memory alert system"
```

### Task 8: Redesign Remaining Secondary App Surfaces

**Files:**
- Modify: `app/lib/screens/budgets/`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/insights/`
- Modify: `app/lib/screens/receipts/`
- Test: relevant existing widget tests

- [ ] **Step 1: Add failing tests or assertions where secondary surfaces need updated shared primitives**

- [ ] **Step 2: Run the focused tests to verify red-state coverage**

Run: targeted `flutter test` commands for the touched screens
Expected: FAIL if new shared-primitive assertions are not yet satisfied.

- [ ] **Step 3: Migrate secondary surfaces onto the shared templates**

Prefer reusing the new feed card, section, chip, and alert primitives over custom styling.

- [ ] **Step 4: Re-run targeted Flutter tests**

Run: relevant `flutter test` commands
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/budgets app/lib/screens/transactions/transaction_detail_screen.dart app/lib/screens/insights app/lib/screens/receipts app/test
git commit -m "feat: redesign secondary app surfaces"
```

### Task 9: Redesign The Astro Landing Page

**Files:**
- Modify: `web/src/pages/index.astro`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/components/Features.astro`
- Modify: `web/src/components/HowItWorks.astro`
- Modify: `web/src/components/Pricing.astro`
- Modify: `web/src/components/Roadmap.astro`
- Modify: `web/src/layouts/Layout.astro`
- Modify: `web/src/styles/global.css`

- [ ] **Step 1: Write a small landing-page smoke test or build verification step**

If no component tests exist, use build verification as the first red/green check for structural edits.

- [ ] **Step 2: Run the web build before changes**

Run: `npm run build`
Workdir: `web`
Expected: PASS on baseline so later regressions are meaningful.

- [ ] **Step 3: Redesign the landing page using the new app language**

Keep the page product-specific:
- sharper hero
- stronger explanation of the financial-conscience model
- real updated app visuals
- less generic SaaS section styling

- [ ] **Step 4: Re-run the web build**

Run: `npm run build`
Workdir: `web`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/index.astro web/src/components web/src/layouts/Layout.astro web/src/styles/global.css
git commit -m "feat: redesign landing page"
```

### Task 10: Full Verification And Local Review Prep

**Files:**
- Modify: docs as needed for the redesign/voice/regret updates
- Verify: `app/`, `src/`, and `web/`

- [ ] **Step 1: Run the focused Flutter verification set**

Run:
```bash
flutter analyze
flutter test
```
Workdir: `app`

- [ ] **Step 2: Run backend verification**

Run:
```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj
dotnet build src/Conscia.Api/Conscia.Api.csproj
```

- [ ] **Step 3: Run landing-page verification**

Run:
```bash
npm run build
```
Workdir: `web`

- [ ] **Step 4: Update docs if the redesign materially changes product descriptions or usage expectations**

Touch:
- `docs/README.md`
- `docs/implementation-tasks.md`
- any relevant `docs/superpowers/specs/` references

- [ ] **Step 5: Commit the final local review state**

```bash
git add app web src docs
git commit -m "chore: prepare redesigned app branch for local review"
```

- [ ] **Step 6: Stop without pushing**

Do not push the branch.
Do not open a PR.
Leave the branch ready for local review the next day.
