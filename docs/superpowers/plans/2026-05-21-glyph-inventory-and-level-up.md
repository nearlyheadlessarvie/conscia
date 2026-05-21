# Glyph Inventory And Level Up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable Conscia glyph prompt pack, clean up stale Journey alert copy, and introduce a full-screen quiet ceremonial `Level Up` page that opens from Journey level-up alerts.

**Architecture:** Keep the custom glyph system intentionally bounded to categories, quests, milestones, and levels by documenting the prompt pack as a design asset rather than expanding code-side rendering first. Introduce a dedicated `Level Up` route and screen that consumes the existing Journey summary model, then update alert generation and alert handling so `journey_level_up` opens that screen while other Journey alerts use dashboard-aware wording.

**Tech Stack:** Flutter, Riverpod, GoRouter, existing Conscia glyph components, markdown design assets, widget tests

---

## File Structure

- `docs/superpowers/assets/glyph-prompts/`  
  Source-of-truth GPT prompt pack files for Conscia’s identity-layer glyphs.
- `app/lib/core/routing/app_router.dart`  
  Register the new full-screen level-up route.
- `app/lib/providers/alert_provider.dart`  
  Update Journey alert labels/routes and preserve enough context for level-up navigation.
- `app/lib/screens/dashboard/dashboard_screen.dart`  
  Route alert taps for `journey_level_up` into the new level-up destination.
- `app/lib/screens/journey/level_up_screen.dart`  
  New full-screen quiet ceremonial level-up page.
- `app/test/providers/conscience_journey_provider_test.dart`  
  Verify Journey alert labels/routes were updated.
- `app/test/screens/dashboard/dashboard_alerts_test.dart`  
  Verify tapping a level-up alert opens the new level-up screen.
- `app/test/screens/journey/level_up_screen_test.dart`  
  Verify the new page content and CTA behavior.

---

### Task 1: Add The Glyph Prompt Pack Assets

**Files:**
- Create: `docs/superpowers/assets/glyph-prompts/conscia-master-system-prompt.md`
- Create: `docs/superpowers/assets/glyph-prompts/categories.md`
- Create: `docs/superpowers/assets/glyph-prompts/quests.md`
- Create: `docs/superpowers/assets/glyph-prompts/milestones.md`
- Create: `docs/superpowers/assets/glyph-prompts/levels.md`

- [ ] **Step 1: Create the master system prompt asset**

Create `docs/superpowers/assets/glyph-prompts/conscia-master-system-prompt.md` with:

```md
# Conscia Master Glyph System Prompt

Design a monochrome mobile app glyph for Conscia, a warm and calmer money app focused on reflection, gentle progress, and emotional clarity.

## Style Rules

- single-color icon
- rounded strokes
- soft geometry
- calm, warm, editorial feeling
- readable at small mobile sizes
- centered on a consistent square artboard
- minimal detail
- strong silhouette first
- slightly symbolic, but never confusing
- avoid corporate fintech sharpness
- avoid gaming/fantasy energy
- avoid tiny decorative marks
- avoid multi-color, gradients, shadows, texture, or realism
- avoid complex perspective

## Emotional Tone

The icon should feel:

- thoughtful
- grounded
- reassuring
- human
- modern but not cold

## Output Target

- clean SVG-ready vector look
- transparent background
- balanced spacing
- no text
```

- [ ] **Step 2: Create the category glyph prompt file**

Create `docs/superpowers/assets/glyph-prompts/categories.md` with:

```md
# Category Glyph Prompts

- groceries — A soft grocery bag or basket. Stable, practical, friendly.
- dining — A fork and spoon with generous spacing. Calm, welcoming meal symbol.
- coffee — A cozy cup with a single gentle steam line. Warm and small ritual energy.
- transport — A compact, simplified transport symbol. Clear and dependable.
- shopping — A shopping bag that feels a little lighter and more playful than groceries.
- health — A softened heart or medical symbol that feels caring, not clinical.
- bills — A tidy bill or receipt document. Structured, clear, and calm.
- education — An open book with soft balance and simple lines.
- travel — A suitcase or passport symbol. Avoid abstract airplane shapes.
- subscription — A restrained loop or recurring band symbol.
- salary — A payslip, envelope, or income card. Dependable and steady.
- freelance — A briefcase or independent work symbol. Clean and self-directed.
- business — A storefront or ledger-like business symbol. Grounded and clear.
- investment — A calm upward growth symbol, bars or line with gentle optimism.
- gift — A rounded wrapped gift. Warm, generous, and simple.
- home — A soft house silhouette with stable base.
- utilities — A practical utilities symbol, like a plug or simple energy/flow mark.
- phone — A minimal phone or handset symbol with softened edges.
- pets — A simple, friendly paw symbol.
- other — A soft ellipsis or catch-all symbol that still feels deliberate.
```

- [ ] **Step 3: Create the quest glyph prompt file**

Create `docs/superpowers/assets/glyph-prompts/quests.md` with:

```md
# Quest Glyph Prompts

- reflect-three-purchases — A receipt with a small reflective accent.
- check-before-purchase — A gentle pause symbol inside a calm boundary.
- review-regret-pattern — A looping path or recurring trail that suggests noticing a pattern.
- read-two-insights — A signal or spark paired with a simple insight motif.
- create-budget-guardrail — A shield or boundary marker. Protective, not aggressive.
- send-family-invite — A two-person or family invitation symbol.
- add-family-expense — A receipt with a family accent.
- review-subscriptions — A recurring loop symbol with quiet focus.
- set-bill-reminder — A calendar with a subtle cue or reminder mark.
- move-money-to-savings — A wallet or money transfer into a safe container.
- pay-down-debt — A debt symbol with a feeling of release or lowering weight.
```

- [ ] **Step 4: Create the milestone glyph prompt file**

Create `docs/superpowers/assets/glyph-prompts/milestones.md` with:

```md
# Milestone Glyph Prompts

- first-reflection — A first-page or opened receipt moment. Gentle beginning.
- pause-before-purchase — A calm pause emblem. Reflective restraint.
- budget-rescuer — A shield or guardrail symbol. Supportive protection.
- regret-pattern-spotted — A signal or constellation-like pattern reveal.
- worth-it-week — A warm, understated trophy or laurel symbol.
- family-founder — A family crest or two-person emblem with belonging.
- insight-reader — A signal plus reading/understanding motif.
- subscription-sleuth — A recurring loop with a subtle discovery accent.
- fee-detective — A fee/cost symbol with a reveal or uncovering gesture.
- savings-streak — A growing savings vessel or stacked calm progress symbol.
- debt-slasher — A debt symbol with release and relief, not violence.
- bill-boss — A bill or receipt symbol with calm control and confidence.
```

- [ ] **Step 5: Create the level glyph prompt file**

Create `docs/superpowers/assets/glyph-prompts/levels.md` with:

```md
# Level Glyph Prompts

- awakening — A sprout. Fresh awareness and beginning.
- impulse-spotter — A signal or wave symbol. Noticing patterns.
- budget-guardian — A shield. Protective steadiness.
- conscience-captain — A compass. Guided direction and judgment.
- money-monk — A calm figure or contemplative emblem. Peace with money rhythm.
- fallback-advanced-level-crest — A crown or haloed crest, but understated and serene.
```

- [ ] **Step 6: Verify the prompt pack files exist and are readable**

Run:

```powershell
Get-ChildItem docs/superpowers/assets/glyph-prompts
```

Expected: five markdown files listed for the master prompt and four concept groups.

- [ ] **Step 7: Commit the prompt pack assets**

```bash
git add docs/superpowers/assets/glyph-prompts
git commit -m "docs: add conscia glyph prompt pack"
```

### Task 2: Update Journey Alert Copy And Routing

**Files:**
- Modify: `app/lib/providers/alert_provider.dart`
- Test: `app/test/providers/conscience_journey_provider_test.dart`

- [ ] **Step 1: Write the failing alert-label test**

Update `app/test/providers/conscience_journey_provider_test.dart` by replacing the stale copy expectation with explicit label checks:

```dart
    final levelAlert =
        journeyAlerts.singleWhere((alert) => alert.type == 'journey_level_up');
    final badgeAlert =
        journeyAlerts.singleWhere((alert) => alert.type == 'journey_badge');
    final questAlert =
        journeyAlerts.singleWhere((alert) => alert.type == 'journey_quest');

    expect(levelAlert.actionLabel, 'View level');
    expect(levelAlert.actionRoute, '/journey/level-up');
    expect(badgeAlert.actionLabel, 'See progress');
    expect(badgeAlert.actionRoute, '/');
    expect(questAlert.actionLabel, 'Continue journey');
    expect(questAlert.actionRoute, '/');
```

- [ ] **Step 2: Run the provider test to verify it fails**

Run:

```powershell
flutter test test/providers/conscience_journey_provider_test.dart
```

Expected: failure because the provider still emits `Open Journey Home` and `/` for level-up.

- [ ] **Step 3: Update Journey alert creation**

Modify `app/lib/providers/alert_provider.dart` so the three Journey alert types read:

```dart
          actionLabel: 'View level',
          actionRoute: '/journey/level-up',
```

for `journey_level_up`,

```dart
          actionLabel: 'See progress',
          actionRoute: '/',
```

for `journey_badge`, and

```dart
          actionLabel: 'Continue journey',
          actionRoute: '/',
```

for `journey_quest`.

- [ ] **Step 4: Re-run the provider test**

Run:

```powershell
flutter test test/providers/conscience_journey_provider_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit the alert copy cleanup**

```bash
git add app/lib/providers/alert_provider.dart app/test/providers/conscience_journey_provider_test.dart
git commit -m "fix(app): refresh journey alert copy"
```

### Task 3: Add The Full-Screen Level Up Route And Screen

**Files:**
- Create: `app/lib/screens/journey/level_up_screen.dart`
- Modify: `app/lib/core/routing/app_router.dart`
- Test: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Write the failing screen test**

Create `app/test/screens/journey/level_up_screen_test.dart` with:

```dart
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/screens/journey/level_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('level up screen renders quiet ceremonial progress',
      (tester) async {
    const summary = ConscienceJourneySummary(
      xpTotal: 120,
      xpIntoLevel: 20,
      xpToNextLevel: 80,
      momentumDays: 4,
      bestMomentumDays: 7,
      currentLevel: ConscienceLevel(
        key: 'budget-guardian',
        title: 'Budget Guardian',
        description: 'You are building steadier money boundaries.',
        unlockedAt: null,
      ),
      nextLevel: null,
      weeklyQuests: [],
      badges: [],
      recentlyUnlockedBadges: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpScreen(summary: summary),
      ),
    );

    expect(find.text('You reached Budget Guardian'), findsOneWidget);
    expect(find.text('Your money rhythm is getting steadier.'), findsOneWidget);
    expect(find.text('Continue your journey'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the screen test to verify it fails**

Run:

```powershell
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: failure because `LevelUpScreen` does not exist yet.

- [ ] **Step 3: Create the level-up screen**

Create `app/lib/screens/journey/level_up_screen.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../models/conscience_journey.dart';
import '../../widgets/glyphs/conscia_glyph.dart';

class LevelUpScreen extends StatelessWidget {
  const LevelUpScreen({
    super.key,
    required this.summary,
  });

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors.primaryContainer.withValues(alpha: 0.95),
                            const Color(0xFFFFFDF8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: ConsciaGlyph.level(
                          summary.currentLevel.key,
                          color: colors.primary,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'You reached ${summary.currentLevel.title}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your money rhythm is getting steadier.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      summary.currentLevel.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${summary.xpTotal} XP · ${summary.momentumDays} day rhythm',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
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

- [ ] **Step 4: Register the level-up route**

Modify `app/lib/core/routing/app_router.dart`:

1. Add a route constant:

```dart
  static const levelUp = '/journey/level-up';
```

2. Import the screen:

```dart
import '../../screens/journey/level_up_screen.dart';
```

3. Add a route that reads Journey summary from `conscienceJourneyProvider`:

```dart
      GoRoute(
        path: '/journey/level-up',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final summary = ref.watch(conscienceJourneyProvider).valueOrNull;
              if (summary == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return LevelUpScreen(summary: summary);
            },
          );
        },
      ),
```

- [ ] **Step 5: Re-run the screen test**

Run:

```powershell
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit the new page and route**

```bash
git add app/lib/screens/journey/level_up_screen.dart app/lib/core/routing/app_router.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "feat(app): add level up celebration screen"
```

### Task 4: Open The Level Up Page From Dashboard Alerts

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Write the failing dashboard alert navigation test**

Add this test to `app/test/screens/dashboard/dashboard_alerts_test.dart`:

```dart
  testWidgets('journey level-up alert opens the level up screen', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        conscienceJourneyProvider.overrideWith(
          () => _StaticConscienceJourneyNotifier(_testJourneySummary),
        ),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'journey-level-budget-guardian',
                type: 'journey_level_up',
                title: 'Level up',
                message: 'Your conscience journey reached a new level.',
                actionLabel: 'View level',
                actionRoute: '/journey/level-up',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View level'));
    await tester.pumpAndSettle();

    expect(find.text('Continue your journey'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the dashboard alert test to verify it fails**

Run:

```powershell
flutter test test/screens/dashboard/dashboard_alerts_test.dart --plain-name "journey level-up alert opens the level up screen"
```

Expected: failure because the route does not yet open a recognizable level-up destination from the alert flow.

- [ ] **Step 3: Preserve dashboard alert handling with the new route**

Modify `app/lib/screens/dashboard/dashboard_screen.dart` only as needed so `_handleAlertAction` continues to use:

```dart
    context.push(alert.actionRoute ?? AppRoutes.budgets);
```

and the new `/journey/level-up` route is exercised without any special-case divergence.

If needed, add a brief inline comment:

```dart
    // Journey alerts can now target dedicated destinations like the level-up page.
```

- [ ] **Step 4: Re-run the focused dashboard alert test**

Run:

```powershell
flutter test test/screens/dashboard/dashboard_alerts_test.dart --plain-name "journey level-up alert opens the level up screen"
```

Expected: PASS.

- [ ] **Step 5: Commit the dashboard alert navigation coverage**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "test(app): cover level up alert navigation"
```

### Task 5: Run Final Verification

**Files:**
- Modify: none
- Test: `app/test/providers/conscience_journey_provider_test.dart`
- Test: `app/test/screens/journey/level_up_screen_test.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Run the focused verification suite**

Run:

```powershell
flutter test test/providers/conscience_journey_provider_test.dart test/screens/journey/level_up_screen_test.dart test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run the full Flutter test suite**

Run:

```powershell
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 4: Commit any final cleanups**

```bash
git add app docs
git commit -m "feat(app): add quiet ceremonial level up flow"
```
