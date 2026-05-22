# Level-Up Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Conscience Journey level-up screen into a light-first ceremonial milestone experience with mascot PNG illustrations, no top-left back affordance, and direct debug/web preview routes for each level.

**Architecture:** Keep one shared `LevelUpScreen` composition and move level-specific presentation into a small config layer that supplies copy and illustration asset paths per level. Add a debug preview route that builds mock `ConscienceJourneySummary` values from the same config, so every level can be inspected directly in web without affecting normal navigation.

**Tech Stack:** Flutter, GoRouter, existing Conscia theme system, PNG assets under `app/assets/images/`, Flutter widget tests.

---

## File Structure

### Existing files to modify

- `app/lib/screens/journey/level_up_screen.dart`
  Purpose: replace the current utility-page layout with the new shared ceremonial composition.
- `app/lib/core/routing/app_router.dart`
  Purpose: add debug preview routes for level inspection in web and local development.
- `app/pubspec.yaml`
  Purpose: ensure any new level illustration asset folder is included explicitly if needed.
- `app/test/screens/journey/level_up_screen_test.dart`
  Purpose: update coverage for the new shared structure and missing back affordance.

### New files to create

- `app/lib/screens/journey/level_up_content.dart`
  Purpose: central config for per-level copy and PNG asset paths, plus preview-summary helpers.
- `app/test/core/routing/level_up_preview_route_test.dart`
  Purpose: verify each debug route resolves and renders the expected level content.
- `app/assets/images/journey/levels/awakening.png`
  Purpose: mascot illustration for Awakening.
- `app/assets/images/journey/levels/impulse_spotter.png`
  Purpose: mascot illustration for Impulse Spotter.
- `app/assets/images/journey/levels/budget_guardian.png`
  Purpose: mascot illustration for Budget Guardian.
- `app/assets/images/journey/levels/conscience_captain.png`
  Purpose: mascot illustration for Conscience Captain.
- `app/assets/images/journey/levels/money_monk.png`
  Purpose: mascot illustration for Money Monk.

### Notes

- Keep the screen redesign localized to journey files; do not spread new reward-screen patterns into unrelated screens.
- Reuse the existing Conscia theme and typography system rather than introducing a separate design framework.
- If final PNG assets are not ready during implementation, wire the asset paths and use temporary transparent placeholders only long enough to keep the screen and tests working.

---

### Task 1: Create level-up presentation config

**Files:**
- Create: `app/lib/screens/journey/level_up_content.dart`
- Test: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Write the failing test for config-backed level copy**

Add a new test case to `app/test/screens/journey/level_up_screen_test.dart` that expects level-specific copy to render from config rather than from the old inline `_levelMeaning()` switch.

```dart
testWidgets('level up screen renders configured level messaging', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LevelUpScreen(summary: _summary(levelKey: 'impulse_spotter', title: 'Impulse Spotter')),
    ),
  );

  expect(find.text('Level up'), findsOneWidget);
  expect(find.text('Impulse Spotter'), findsOneWidget);
  expect(find.text('You are catching impulses earlier and giving yourself more room to choose.'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: FAIL because the current screen does not render `Level up` and still relies on inline level-copy logic.

- [ ] **Step 3: Create the minimal config file**

Create `app/lib/screens/journey/level_up_content.dart`:

```dart
import '../../models/conscience_journey.dart';

class LevelUpContent {
  const LevelUpContent({
    required this.levelKey,
    required this.eyebrow,
    required this.title,
    required this.payoffLine,
    required this.body,
    required this.illustrationAsset,
  });

  final String levelKey;
  final String eyebrow;
  final String title;
  final String payoffLine;
  final String body;
  final String illustrationAsset;
}

const _levelUpContentByKey = <String, LevelUpContent>{
  'awakening': LevelUpContent(
    levelKey: 'awakening',
    eyebrow: 'Level up',
    title: 'Awakening',
    payoffLine: 'You are noticing the money moments that shape your days.',
    body: 'You are beginning to notice the small money moments that shape your days.',
    illustrationAsset: 'assets/images/journey/levels/awakening.png',
  ),
  'impulse_spotter': LevelUpContent(
    levelKey: 'impulse_spotter',
    eyebrow: 'Level up',
    title: 'Impulse Spotter',
    payoffLine: 'Your money rhythm is getting steadier.',
    body: 'You are catching impulses earlier and giving yourself more room to choose.',
    illustrationAsset: 'assets/images/journey/levels/impulse_spotter.png',
  ),
  'budget_guardian': LevelUpContent(
    levelKey: 'budget_guardian',
    eyebrow: 'Level up',
    title: 'Budget Guardian',
    payoffLine: 'You are protecting your priorities with more confidence.',
    body: 'You are building steadier money boundaries without turning every choice into pressure.',
    illustrationAsset: 'assets/images/journey/levels/budget_guardian.png',
  ),
  'conscience_captain': LevelUpContent(
    levelKey: 'conscience_captain',
    eyebrow: 'Level up',
    title: 'Conscience Captain',
    payoffLine: 'You are steering with more clarity now.',
    body: 'You are steering with more clarity, using signals from your own habits instead of noise.',
    illustrationAsset: 'assets/images/journey/levels/conscience_captain.png',
  ),
  'money_monk': LevelUpContent(
    levelKey: 'money_monk',
    eyebrow: 'Level up',
    title: 'Money Monk',
    payoffLine: 'Calm is becoming part of your money rhythm.',
    body: 'You are finding a calmer rhythm with money, one considered moment at a time.',
    illustrationAsset: 'assets/images/journey/levels/money_monk.png',
  ),
};

LevelUpContent resolveLevelUpContent(ConscienceJourneySummary summary) {
  final normalized = summary.currentLevel.key.replaceAll('-', '_');
  return _levelUpContentByKey[normalized] ??
      LevelUpContent(
        levelKey: normalized,
        eyebrow: 'Level up',
        title: summary.currentLevel.title,
        payoffLine: 'A quieter kind of progress is taking shape.',
        body: 'This level marks a quieter kind of progress: more awareness, more steadiness, and more trust in your rhythm.',
        illustrationAsset: '',
      );
}

ConscienceJourneySummary buildPreviewJourneySummary({
  required String levelKey,
  required String title,
  required int requiredXp,
  required int xpTotal,
  required int xpIntoLevel,
  required int xpToNextLevel,
  required int momentumDays,
}) {
  return ConscienceJourneySummary(
    xpTotal: xpTotal,
    currentLevel: ConscienceLevel(
      key: levelKey,
      title: title,
      requiredXp: requiredXp,
    ),
    nextLevel: null,
    xpIntoLevel: xpIntoLevel,
    xpToNextLevel: xpToNextLevel,
    momentumDays: momentumDays,
    bestMomentumDays: momentumDays,
    weeklyQuests: const [],
    badges: const [],
  );
}
```

- [ ] **Step 4: Run test to verify the config compiles but the UI test still fails for layout**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: FAIL because `LevelUpScreen` is not using `resolveLevelUpContent()` yet.

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/journey/level_up_content.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "feat(app): add level-up presentation config"
```

---

### Task 2: Redesign the shared level-up screen layout

**Files:**
- Modify: `app/lib/screens/journey/level_up_screen.dart`
- Test: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Extend the widget test to lock the new structure**

Update `app/test/screens/journey/level_up_screen_test.dart`:

```dart
testWidgets('level up screen renders ceremonial milestone layout', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LevelUpScreen(summary: _summary(levelKey: 'budget_guardian', title: 'Budget Guardian')),
    ),
  );

  expect(find.text('Level up'), findsOneWidget);
  expect(find.text('Budget Guardian'), findsOneWidget);
  expect(find.text('Continue your journey'), findsOneWidget);
  expect(find.byTooltip('Back'), findsNothing);
  expect(find.byType(AppBar), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: FAIL because the current screen still renders an `AppBar` with the top-left back arrow.

- [ ] **Step 3: Replace the old screen with the new shared composition**

Update `app/lib/screens/journey/level_up_screen.dart` to:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/conscience_journey.dart';
import 'level_up_content.dart';

class LevelUpScreen extends StatelessWidget {
  const LevelUpScreen({
    super.key,
    required this.summary,
  });

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final content = resolveLevelUpContent(summary);

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LevelUpAtmospherePainter(colors),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LevelIllustration(content: content),
                            const SizedBox(height: 28),
                            Text(
                              content.eyebrow,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.deepNavy,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              content.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              content.payoffLine,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.mutedInk,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              content.body,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.mutedInk,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _LevelProgressLine(summary: summary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Continue your journey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add the PNG-first illustration slot with glyph fallback**

In the same file, add:

```dart
class _LevelIllustration extends StatelessWidget {
  const _LevelIllustration({required this.content});

  final LevelUpContent content;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final hasAsset = content.illustrationAsset.isNotEmpty;

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.familySoft.withValues(alpha: 0.95),
            colors.paper,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.deepNavy.withValues(alpha: 0.10),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: hasAsset
            ? Image.asset(
                content.illustrationAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
```

- [ ] **Step 5: Keep the ambient painter and progress line, but restyle for the new composition**

Update `_LevelProgressLine` to:

```dart
class _LevelProgressLine extends StatelessWidget {
  const _LevelProgressLine({required this.summary});

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final rhythmLabel = summary.momentumDays == 1
        ? '1 day rhythm'
        : '${summary.momentumDays} day rhythm';

    return Text(
      '${summary.xpTotal} XP | $rhythmLabel',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge?.copyWith(
        color: appColors.deepNavy.withValues(alpha: 0.72),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/lib/screens/journey/level_up_screen.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "feat(app): redesign level-up screen layout"
```

---

### Task 3: Add debug preview routes for each level

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/journey/level_up_content.dart`
- Create: `app/test/core/routing/level_up_preview_route_test.dart`

- [ ] **Step 1: Write the failing route test**

Create `app/test/core/routing/level_up_preview_route_test.dart`:

```dart
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debug level-up preview route renders the requested level', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    router.go('/debug/journey/level-up/impulse-spotter');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impulse Spotter'), findsOneWidget);
    expect(find.text('Level up'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/routing/level_up_preview_route_test.dart`
Expected: FAIL because the debug route does not exist yet.

- [ ] **Step 3: Add preview helpers for known levels**

Append to `app/lib/screens/journey/level_up_content.dart`:

```dart
class LevelUpPreviewSpec {
  const LevelUpPreviewSpec({
    required this.routeKey,
    required this.levelKey,
    required this.title,
    required this.requiredXp,
    required this.xpTotal,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.momentumDays,
  });

  final String routeKey;
  final String levelKey;
  final String title;
  final int requiredXp;
  final int xpTotal;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final int momentumDays;
}

const levelUpPreviewSpecs = <LevelUpPreviewSpec>[
  LevelUpPreviewSpec(routeKey: 'awakening', levelKey: 'awakening', title: 'Awakening', requiredXp: 0, xpTotal: 65, xpIntoLevel: 65, xpToNextLevel: 135, momentumDays: 1),
  LevelUpPreviewSpec(routeKey: 'impulse-spotter', levelKey: 'impulse_spotter', title: 'Impulse Spotter', requiredXp: 200, xpTotal: 175, xpIntoLevel: 175, xpToNextLevel: 225, momentumDays: 2),
  LevelUpPreviewSpec(routeKey: 'budget-guardian', levelKey: 'budget_guardian', title: 'Budget Guardian', requiredXp: 400, xpTotal: 485, xpIntoLevel: 85, xpToNextLevel: 515, momentumDays: 6),
  LevelUpPreviewSpec(routeKey: 'conscience-captain', levelKey: 'conscience_captain', title: 'Conscience Captain', requiredXp: 1000, xpTotal: 1120, xpIntoLevel: 120, xpToNextLevel: 880, momentumDays: 10),
  LevelUpPreviewSpec(routeKey: 'money-monk', levelKey: 'money_monk', title: 'Money Monk', requiredXp: 2000, xpTotal: 2350, xpIntoLevel: 350, xpToNextLevel: 0, momentumDays: 18),
];

LevelUpPreviewSpec? findLevelUpPreviewSpec(String routeKey) {
  return levelUpPreviewSpecs.firstWhere(
    (spec) => spec.routeKey == routeKey,
    orElse: () => const LevelUpPreviewSpec(
      routeKey: '',
      levelKey: '',
      title: '',
      requiredXp: 0,
      xpTotal: 0,
      xpIntoLevel: 0,
      xpToNextLevel: 0,
      momentumDays: 0,
    ),
  ).routeKey.isEmpty
      ? null
      : levelUpPreviewSpecs.firstWhere((spec) => spec.routeKey == routeKey);
}
```

- [ ] **Step 4: Add the debug route**

Update `app/lib/core/routing/app_router.dart`:

```dart
import '../../screens/journey/level_up_content.dart';
```

Add route:

```dart
      GoRoute(
        path: '/debug/journey/level-up/:levelKey',
        builder: (context, state) {
          final routeKey = state.pathParameters['levelKey']!;
          final spec = findLevelUpPreviewSpec(routeKey);
          if (spec == null) {
            return const Scaffold(
              body: Center(child: Text('Unknown level preview')),
            );
          }

          return LevelUpScreen(
            summary: buildPreviewJourneySummary(
              levelKey: spec.levelKey,
              title: spec.title,
              requiredXp: spec.requiredXp,
              xpTotal: spec.xpTotal,
              xpIntoLevel: spec.xpIntoLevel,
              xpToNextLevel: spec.xpToNextLevel,
              momentumDays: spec.momentumDays,
            ),
          );
        },
      ),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/routing/level_up_preview_route_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/core/routing/app_router.dart app/lib/screens/journey/level_up_content.dart app/test/core/routing/level_up_preview_route_test.dart
git commit -m "feat(app): add level-up preview routes"
```

---

### Task 4: Wire mascot PNG assets and fallback behavior

**Files:**
- Create: `app/assets/images/journey/levels/awakening.png`
- Create: `app/assets/images/journey/levels/impulse_spotter.png`
- Create: `app/assets/images/journey/levels/budget_guardian.png`
- Create: `app/assets/images/journey/levels/conscience_captain.png`
- Create: `app/assets/images/journey/levels/money_monk.png`
- Modify: `app/pubspec.yaml`
- Test: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Write a failing test for missing-asset fallback**

Add to `app/test/screens/journey/level_up_screen_test.dart`:

```dart
testWidgets('level up screen still renders content when the illustration asset is missing', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LevelUpScreen(
        summary: _summary(levelKey: 'unknown_level', title: 'Unknown Level'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Unknown Level'), findsOneWidget);
  expect(find.text('Continue your journey'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: PASS or stable render; if the asset slot throws, fix the widget before proceeding.

- [ ] **Step 3: Add the level asset files**

Create these files in `app/assets/images/journey/levels/`:

```text
awakening.png
impulse_spotter.png
budget_guardian.png
conscience_captain.png
money_monk.png
```

Implementation note:

- if final generated mascot PNGs are ready, add them directly
- if art generation is still pending, add temporary placeholder PNGs with the exact final filenames so routing and layout can be completed now

- [ ] **Step 4: Ensure asset discovery is explicit**

Update `app/pubspec.yaml` assets section:

```yaml
  assets:
    - assets/
    - assets/images/
    - assets/images/journey/
    - assets/images/journey/levels/
    - assets/images/sprites/angel/
    - assets/images/sprites/devil/
    - assets/images/sprites/money/
```

- [ ] **Step 5: Run the screen test again**

Run: `flutter test test/screens/journey/level_up_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/assets/images/journey/levels app/pubspec.yaml app/test/screens/journey/level_up_screen_test.dart
git commit -m "feat(app): add level-up illustration assets"
```

---

### Task 5: Final regression verification

**Files:**
- Modify: none
- Test: `app/test/screens/journey/level_up_screen_test.dart`
- Test: `app/test/core/routing/level_up_preview_route_test.dart`
- Test: `app/test/core/routing/app_router_test.dart`

- [ ] **Step 1: Run focused journey UI tests**

Run: `flutter test test/screens/journey/level_up_screen_test.dart test/core/routing/level_up_preview_route_test.dart`
Expected: PASS

- [ ] **Step 2: Run router regression coverage**

Run: `flutter test test/core/routing/app_router_test.dart`
Expected: PASS

- [ ] **Step 3: Smoke-check all preview routes in web**

Run:

```bash
flutter run -d chrome --web-port=3333
```

Open and verify:

- `http://localhost:3333/#/debug/journey/level-up/awakening`
- `http://localhost:3333/#/debug/journey/level-up/impulse-spotter`
- `http://localhost:3333/#/debug/journey/level-up/budget-guardian`
- `http://localhost:3333/#/debug/journey/level-up/conscience-captain`
- `http://localhost:3333/#/debug/journey/level-up/money-monk`

Expected:

- each route loads directly
- no top-left back arrow is shown
- level title/copy changes correctly
- the bottom CTA remains visible and intentional

- [ ] **Step 4: Commit if any final route/test-only fixes were needed**

```bash
git add app/lib/core/routing/app_router.dart app/test/core/routing/app_router_test.dart app/test/core/routing/level_up_preview_route_test.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "test(app): cover level-up preview routes"
```

---

## Self-Review

### Spec coverage

- shared ceremonial layout: covered in Task 2
- mascot PNG illustration approach: covered in Tasks 1 and 4
- no top-left back affordance: covered in Task 2 test and implementation
- debug/web preview routes for each level: covered in Task 3 and Task 5
- light-mode-first only: reflected in architecture and no dark-mode tasks
- fallback if PNG is missing: covered in Task 4

### Placeholder scan

- no `TODO`/`TBD` markers remain
- route names, filenames, and test commands are explicit
- asset filenames are explicit

### Type consistency

- `LevelUpContent`, `LevelUpPreviewSpec`, `resolveLevelUpContent()`, and `buildPreviewJourneySummary()` are defined before later tasks rely on them
- route key normalization is handled in the content layer rather than duplicated in the router
