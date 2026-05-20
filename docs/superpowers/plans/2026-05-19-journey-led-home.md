# Journey-Led Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Home content hierarchy with a Journey-led Home experience while preserving the existing five-icon floating dock.

**Architecture:** Keep `DashboardScreen` as the Home route owner, but move Journey-specific presentation logic and widgets into focused dashboard files. The Dashboard continues to fetch the same Riverpod state it already owns, then passes derived Journey presentation data into new Home sections before the existing budget and transaction context.

**Tech Stack:** Flutter, Riverpod, GoRouter, existing Conscia design tokens, Flutter widget tests.

---

## File Structure

- Create: `app/lib/screens/dashboard/journey_home_presenter.dart`
  - Owns pure presentation decisions for Journey-led Home: next action copy, pattern signal copy, quest completion counts, and milestone filtering.
- Create: `app/test/screens/dashboard/journey_home_presenter_test.dart`
  - Unit tests for the pure presentation decisions so visual widgets do not carry behavioral branching.
- Create: `app/lib/screens/dashboard/widgets/journey_led_home_sections.dart`
  - Owns Home-specific Journey widgets: hero, Today with Conscia, weekly arc, patterns preview, and milestones strip.
- Create: `app/test/screens/dashboard/journey_led_home_sections_test.dart`
  - Widget tests for the new focused sections using existing Conscia theme.
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
  - Wires presenter and sections into the Home scroll order. Keeps budget and transaction sections as supporting context.
- Modify: `app/lib/providers/alert_provider.dart`
  - Routes Journey alerts to Home because Home is now the first-class Journey surface.
- Modify: `app/test/providers/conscience_journey_provider_test.dart`
  - Updates route expectations for Journey-generated alerts.
- Modify: `app/test/screens/dashboard/dashboard_alerts_test.dart`
  - Updates Dashboard expectations from the old shortcut-led hero to the Journey-led Home sections.

---

### Task 1: Add Journey Home Presentation Model

**Files:**
- Create: `app/lib/screens/dashboard/journey_home_presenter.dart`
- Create: `app/test/screens/dashboard/journey_home_presenter_test.dart`

- [ ] **Step 1: Write the failing presenter tests**

Create `app/test/screens/dashboard/journey_home_presenter_test.dart` with:

```dart
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildJourneyHomePresentation chooses an incomplete quest as today action',
      () {
    final presentation = buildJourneyHomePresentation(_summary(
      quests: const [
        ConscienceQuest(
          key: 'reflect_three_purchases',
          title: 'Reflect on three purchases',
          description: 'Check how recent spending felt after the moment passed.',
          progress: 1,
          target: 3,
          xpReward: 40,
          isCompleted: false,
        ),
      ],
    ));

    expect(presentation.todayAction.title, 'Reflect on three purchases');
    expect(presentation.todayAction.description,
        'Check how recent spending felt after the moment passed.');
    expect(presentation.todayAction.ctaLabel, 'Continue journey');
    expect(presentation.completedQuestCount, 0);
    expect(presentation.totalQuestCount, 1);
  });

  test('buildJourneyHomePresentation falls back to a reflection action', () {
    final presentation = buildJourneyHomePresentation(_summary());

    expect(presentation.todayAction.title, 'Check in with a recent purchase');
    expect(presentation.todayAction.description,
        'Pick one transaction and mark whether it still feels worth it.');
    expect(presentation.patterns.first.title, 'Momentum is forming');
    expect(presentation.milestones, isEmpty);
  });

  test('buildJourneyHomePresentation exposes unlocked milestones first', () {
    final presentation = buildJourneyHomePresentation(_summary(
      badges: const [
        ConscienceBadge(
          key: 'locked',
          title: 'Locked',
          description: 'Not yet.',
          progress: 0,
          target: 1,
          isUnlocked: false,
        ),
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'You checked in once.',
          progress: 1,
          target: 1,
          isUnlocked: true,
        ),
      ],
    ));

    expect(presentation.milestones.single.title, 'First Reflection');
  });
}

ConscienceJourneySummary _summary({
  List<ConscienceQuest> quests = const [],
  List<ConscienceBadge> badges = const [],
}) =>
    ConscienceJourneySummary(
      xpTotal: 125,
      currentLevel: const ConscienceLevel(
        key: 'awakening',
        title: 'Awakening',
        requiredXp: 0,
      ),
      nextLevel: const ConscienceLevel(
        key: 'impulse_spotter',
        title: 'Impulse Spotter',
        requiredXp: 250,
      ),
      xpIntoLevel: 125,
      xpToNextLevel: 125,
      momentumDays: 6,
      bestMomentumDays: 8,
      weeklyQuests: quests,
      badges: badges,
    );
```

- [ ] **Step 2: Run the presenter tests to verify they fail**

Run:

```powershell
flutter test app/test/screens/dashboard/journey_home_presenter_test.dart
```

Expected: fail because `journey_home_presenter.dart` does not exist.

- [ ] **Step 3: Add the presenter implementation**

Create `app/lib/screens/dashboard/journey_home_presenter.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/conscience_journey.dart';

class JourneyHomePresentation {
  const JourneyHomePresentation({
    required this.todayAction,
    required this.patterns,
    required this.milestones,
    required this.completedQuestCount,
    required this.totalQuestCount,
    required this.levelProgress,
  });

  final JourneyHomeAction todayAction;
  final List<JourneyHomePatternSignal> patterns;
  final List<ConscienceBadge> milestones;
  final int completedQuestCount;
  final int totalQuestCount;
  final double levelProgress;
}

class JourneyHomeAction {
  const JourneyHomeAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
}

class JourneyHomePatternSignal {
  const JourneyHomePatternSignal({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final JourneyHomePatternTone tone;
}

enum JourneyHomePatternTone { positive, watch }

JourneyHomePresentation buildJourneyHomePresentation(
  ConscienceJourneySummary? summary,
) {
  final completedQuestCount = summary == null
      ? 0
      : summary.weeklyQuests.where((quest) => quest.isCompleted).length;
  final totalQuestCount = summary?.weeklyQuests.length ?? 0;

  return JourneyHomePresentation(
    todayAction: _todayAction(summary),
    patterns: _patterns(summary),
    milestones: (summary?.badges ?? const [])
        .where((badge) => badge.isUnlocked)
        .take(4)
        .toList(growable: false),
    completedQuestCount: completedQuestCount,
    totalQuestCount: totalQuestCount,
    levelProgress: _levelProgress(summary),
  );
}

JourneyHomeAction _todayAction(ConscienceJourneySummary? summary) {
  ConscienceQuest? quest;
  for (final candidate in summary?.weeklyQuests ?? const <ConscienceQuest>[]) {
    if (!candidate.isCompleted) {
      quest = candidate;
      break;
    }
  }
  if (quest != null) {
    return JourneyHomeAction(
      icon: _questIcon(quest.key),
      title: quest.title,
      description: quest.description,
      ctaLabel: 'Continue journey',
    );
  }

  return const JourneyHomeAction(
    icon: Icons.auto_stories_rounded,
    title: 'Check in with a recent purchase',
    description: 'Pick one transaction and mark whether it still feels worth it.',
    ctaLabel: 'Continue journey',
  );
}

List<JourneyHomePatternSignal> _patterns(ConscienceJourneySummary? summary) {
  final momentumDays = summary?.momentumDays ?? 0;
  final completed = summary == null
      ? 0
      : summary.weeklyQuests.where((quest) => quest.isCompleted).length;
  final total = summary?.weeklyQuests.length ?? 0;

  return [
    JourneyHomePatternSignal(
      icon: Icons.local_fire_department_rounded,
      title: momentumDays > 0 ? 'Momentum is forming' : 'Start the streak',
      description: momentumDays > 0
          ? '$momentumDays mindful days in a row. Keep the next action small.'
          : 'One reflection or pause today will start the trail.',
      tone: JourneyHomePatternTone.positive,
    ),
    JourneyHomePatternSignal(
      icon: Icons.flag_rounded,
      title: total == 0 ? 'Weekly rhythm is open' : 'Weekly rhythm',
      description: total == 0
          ? 'Conscia will surface commitments as your activity builds.'
          : '$completed of $total commitments complete this week.',
      tone: completed == total && total > 0
          ? JourneyHomePatternTone.positive
          : JourneyHomePatternTone.watch,
    ),
  ];
}

double _levelProgress(ConscienceJourneySummary? summary) {
  if (summary == null || summary.nextLevel == null) return 1;
  final span = summary.nextLevel!.requiredXp - summary.currentLevel.requiredXp;
  if (span <= 0) return 1;
  return (summary.xpIntoLevel / span).clamp(0, 1).toDouble();
}

IconData _questIcon(String key) {
  return switch (key) {
    'reflect_three_purchases' => Icons.auto_stories_rounded,
    'check_before_purchase' => Icons.psychology_rounded,
    'review_regret_pattern' => Icons.loop_rounded,
    'send_family_invite' => Icons.group_add_rounded,
    'add_family_expense' => Icons.receipt_long_rounded,
    _ => Icons.flag_rounded,
  };
}
```

- [ ] **Step 4: Run the presenter tests to verify they pass**

Run:

```powershell
flutter test app/test/screens/dashboard/journey_home_presenter_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit the presenter**

Run:

```powershell
git add app/lib/screens/dashboard/journey_home_presenter.dart app/test/screens/dashboard/journey_home_presenter_test.dart
git commit -m "feat: add journey home presentation model"
```

Expected: commit succeeds.

---

### Task 2: Add Journey-Led Home Section Widgets

**Files:**
- Create: `app/lib/screens/dashboard/widgets/journey_led_home_sections.dart`
- Create: `app/test/screens/dashboard/journey_led_home_sections_test.dart`

- [ ] **Step 1: Write the focused widget tests**

Create `app/test/screens/dashboard/journey_led_home_sections_test.dart`:

```dart
import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:conscia_app/screens/dashboard/widgets/journey_led_home_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('JourneyLedHomeSections renders primary Journey modules',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: JourneyLedHomeSections(
              summary: _summary(),
              presentation: buildJourneyHomePresentation(_summary()),
              onContinueJourney: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Today with Conscia'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-home-today-card')),
        findsOneWidget);
  });
}

ConscienceJourneySummary _summary() => const ConscienceJourneySummary(
      xpTotal: 125,
      currentLevel: ConscienceLevel(
        key: 'awakening',
        title: 'Awakening',
        requiredXp: 0,
      ),
      nextLevel: ConscienceLevel(
        key: 'impulse_spotter',
        title: 'Impulse Spotter',
        requiredXp: 250,
      ),
      xpIntoLevel: 125,
      xpToNextLevel: 125,
      momentumDays: 6,
      bestMomentumDays: 8,
      weeklyQuests: [
        ConscienceQuest(
          key: 'reflect_three_purchases',
          title: 'Reflect on three purchases',
          description: 'Check how recent spending felt after the moment passed.',
          progress: 1,
          target: 3,
          xpReward: 40,
          isCompleted: false,
        ),
      ],
      badges: [
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'You checked in once.',
          progress: 1,
          target: 1,
          isUnlocked: true,
        ),
      ],
    );
```

- [ ] **Step 2: Run the widget test to verify it fails**

Run:

```powershell
flutter test app/test/screens/dashboard/journey_led_home_sections_test.dart
```

Expected: fail because `journey_led_home_sections.dart` does not exist.

- [ ] **Step 3: Add the widget file**

Create `app/lib/screens/dashboard/widgets/journey_led_home_sections.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/conscience_journey.dart';
import '../../../widgets/feed_card.dart';
import '../../../widgets/screen_section.dart';
import '../journey_home_presenter.dart';

class JourneyLedHomeSections extends StatelessWidget {
  const JourneyLedHomeSections({
    super.key,
    required this.summary,
    required this.presentation,
    required this.onContinueJourney,
  });

  final ConscienceJourneySummary? summary;
  final JourneyHomePresentation presentation;
  final VoidCallback onContinueJourney;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenSection(
            title: 'Today with Conscia',
            subtitle: 'The smallest useful move for your money behavior today.',
            compact: true,
            child: _TodayWithConsciaCard(
              action: presentation.todayAction,
              onPressed: onContinueJourney,
            ),
          ),
          ScreenSection(
            title: 'This Week',
            subtitle: 'A gentle arc for building consistency.',
            compact: true,
            child: _WeeklyArc(
              quests: summary?.weeklyQuests ?? const [],
              completed: presentation.completedQuestCount,
              total: presentation.totalQuestCount,
            ),
          ),
          ScreenSection(
            title: 'Patterns',
            subtitle: 'What Conscia is noticing without judging.',
            compact: true,
            child: _PatternPreview(patterns: presentation.patterns),
          ),
          if (presentation.milestones.isNotEmpty)
            ScreenSection(
              title: 'Milestones',
              subtitle: 'Proof that small check-ins are adding up.',
              compact: true,
              child: _MilestoneStrip(badges: presentation.milestones),
            ),
        ],
      ),
    );
  }
}

class _TodayWithConsciaCard extends StatelessWidget {
  const _TodayWithConsciaCard({
    required this.action,
    required this.onPressed,
  });

  final JourneyHomeAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return FeedCard(
      key: const ValueKey('journey-home-today-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(icon: action.icon, color: colors.deepNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(action.ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _WeeklyArc extends StatelessWidget {
  const _WeeklyArc({
    required this.quests,
    required this.completed,
    required this.total,
  });

  final List<ConscienceQuest> quests;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final visibleQuests = quests.take(3).toList(growable: false);

    if (visibleQuests.isEmpty) {
      return FeedCard(
        child: Text(
          'Conscia will shape weekly commitments as your activity builds.',
          style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
        ),
      );
    }

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed/$total commitments complete',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final quest in visibleQuests)
            _QuestRow(quest: quest),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});

  final ConscienceQuest quest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            quest.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: quest.isCompleted ? colors.income : colors.mutedInk,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quest.title,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPreview extends StatelessWidget {
  const _PatternPreview({required this.patterns});

  final List<JourneyHomePatternSignal> patterns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final pattern in patterns)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FeedCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  _SoftIcon(icon: pattern.icon, color: _toneColor(context, pattern)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pattern.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pattern.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).appColors.mutedInk,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _toneColor(BuildContext context, JourneyHomePatternSignal pattern) {
    final colors = Theme.of(context).appColors;
    return pattern.tone == JourneyHomePatternTone.positive
        ? colors.income
        : colors.deepNavy;
  }
}

class _MilestoneStrip extends StatelessWidget {
  const _MilestoneStrip({required this.badges});

  final List<ConscienceBadge> badges;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final badge in badges)
            Container(
              width: 112,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                badge.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.deepNavy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
```

- [ ] **Step 4: Run the widget test to verify it passes**

Run:

```powershell
flutter test app/test/screens/dashboard/journey_led_home_sections_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit the section widgets**

Run:

```powershell
git add app/lib/screens/dashboard/widgets/journey_led_home_sections.dart app/test/screens/dashboard/journey_led_home_sections_test.dart
git commit -m "feat: add journey-led home sections"
```

Expected: commit succeeds.

---

### Task 3: Wire Journey-Led Sections Into Dashboard

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Update Dashboard widget expectations first**

In `app/test/screens/dashboard/dashboard_alerts_test.dart`, update the existing Dashboard hero tests to expect the new Home structure:

```dart
expect(find.byKey(const ValueKey('dashboard-editorial-hero')), findsOneWidget);
expect(find.text('Today with Conscia'), findsOneWidget);
expect(find.text('This Week'), findsOneWidget);
expect(find.text('Patterns'), findsOneWidget);
expect(find.text('BUDGETS'), findsOneWidget);
expect(find.text('RECENT TRANSACTIONS'), findsOneWidget);
expect(find.byKey(const ValueKey('dashboard-journey-link')), findsNothing);
```

Also update the ordering test so `Today with Conscia` appears before `BUDGETS`:

```dart
final today = find.text('Today with Conscia');
final budgets = find.text('BUDGETS');

expect(today, findsOneWidget);
expect(budgets, findsOneWidget);
expect(tester.getTopLeft(today).dy, lessThan(tester.getTopLeft(budgets).dy));
```

- [ ] **Step 2: Run the Dashboard tests to verify they fail**

Run:

```powershell
flutter test app/test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: fail because Dashboard still renders the old shortcut-led hero and does not render Journey-led sections.

- [ ] **Step 3: Import the presenter and section widgets**

Modify `app/lib/screens/dashboard/dashboard_screen.dart` imports:

```dart
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:conscia_app/screens/dashboard/widgets/journey_led_home_sections.dart';
```

- [ ] **Step 4: Build Journey presentation inside `DashboardScreen.build`**

After `final journey = journeyState.valueOrNull;`, add:

```dart
final journeyHome = buildJourneyHomePresentation(journey);
```

- [ ] **Step 5: Replace the old Journey shortcut callback with a local continue action**

Inside `_DashboardScreenState`, add:

```dart
void _continueJourney() {
  context.push(AppRoutes.assistant);
}
```

- [ ] **Step 6: Change the Hero from shortcut-led to Journey-led**

Modify `_DashboardEditorialHeroCard` constructor and usage:

```dart
_DashboardEditorialHeroCard(
  monthExpenseTotal: monthExpenseTotal,
  currencyCode: userPreferences.currency,
  locale: userPreferences.locale,
  journey: journey,
  summary: insightSummary,
  loading: (journeyState.isLoading && journey == null) ||
      (insightSummaryState.isLoading && insightSummary == null),
)
```

Remove `onJourneyTap` and `onInsightsTap` from the constructor and fields.

Inside `_DashboardEditorialHeroCard`, replace the shortcut row with:

```dart
Text(
  'Journey',
  style: textTheme.titleLarge?.copyWith(
    color: colors.deepNavy,
    fontWeight: FontWeight.w900,
  ),
),
const SizedBox(height: 8),
Text(
  journey == null
      ? 'Conscia is ready to shape your next few choices into a clearer pattern.'
      : '${journey!.currentLevel.title} · ${journey!.xpTotal} XP earned',
  style: textTheme.bodyMedium?.copyWith(
    color: colors.ink,
    height: 1.35,
  ),
),
```

Keep the existing spend summary and metric pills so Home still has grounded financial context.

- [ ] **Step 7: Insert Journey-led sections before budgets**

After the hero `SliverToBoxAdapter`, insert:

```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.only(top: 18),
    child: JourneyLedHomeSections(
      summary: journey,
      presentation: journeyHome,
      onContinueJourney: _continueJourney,
    ),
  ),
),
```

Keep the existing `BUDGETS`, `REFLECT`, and `RECENT TRANSACTIONS` sections below this block.

- [ ] **Step 8: Run formatter**

Run:

```powershell
dart format app/lib/screens/dashboard/dashboard_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: formatter completes with no syntax errors.

- [ ] **Step 9: Run Dashboard tests to verify they pass**

Run:

```powershell
flutter test app/test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: pass.

- [ ] **Step 10: Commit Dashboard wiring**

Run:

```powershell
git add app/lib/screens/dashboard/dashboard_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat: make home journey-led"
```

Expected: commit succeeds.

---

### Task 4: Route Journey Alerts Back To Home

**Files:**
- Modify: `app/lib/providers/alert_provider.dart`
- Modify: `app/test/providers/conscience_journey_provider_test.dart`

- [ ] **Step 1: Update the alert provider test expectation**

In `app/test/providers/conscience_journey_provider_test.dart`, change:

```dart
expect(alerts.first.actionRoute, '/journey');
```

to:

```dart
expect(alerts.first.actionRoute, '/');
```

- [ ] **Step 2: Run the provider test to verify it fails**

Run:

```powershell
flutter test app/test/providers/conscience_journey_provider_test.dart
```

Expected: fail because Journey alerts still use `/journey`.

- [ ] **Step 3: Update Journey alert routes**

In `app/lib/providers/alert_provider.dart`, change each Journey-generated `actionRoute: '/journey'` to:

```dart
actionRoute: '/',
```

Keep non-Journey alert routes unchanged.

- [ ] **Step 4: Run provider tests to verify they pass**

Run:

```powershell
flutter test app/test/providers/conscience_journey_provider_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit alert routing**

Run:

```powershell
git add app/lib/providers/alert_provider.dart app/test/providers/conscience_journey_provider_test.dart
git commit -m "fix: route journey alerts to home"
```

Expected: commit succeeds.

---

### Task 5: Final Verification

**Files:**
- Verify only.

- [ ] **Step 1: Run targeted Flutter tests**

Run:

```powershell
flutter test app/test/screens/dashboard/journey_home_presenter_test.dart app/test/screens/dashboard/journey_led_home_sections_test.dart app/test/screens/dashboard/dashboard_alerts_test.dart app/test/providers/conscience_journey_provider_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: no new analyzer errors.

- [ ] **Step 3: Check git status**

Run:

```powershell
git status --short --branch
```

Expected: branch is `feature/journey-class-1-redesign` with no uncommitted implementation changes.

---

## Self-Review Notes

- Spec coverage: The plan makes Home Journey-led, keeps the current dock, keeps budgets and recent transactions as supporting context, and routes Journey alerts back to Home.
- Scope control: The plan does not require backend contract changes and does not delete `/journey`.
- Test coverage: Pure presentation decisions, focused widgets, Dashboard integration, and Journey alert routing are covered.
