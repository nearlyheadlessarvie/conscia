import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:conscia_app/screens/dashboard/widgets/journey_led_home_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('JourneyLedHomeSections renders primary Journey modules',
      (tester) async {
    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () {},
    ));

    expect(find.text('Today with Conscia'), findsNothing);
    expect(find.byKey(const ValueKey('journey-home-today-card')), findsNothing);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
  });

  testWidgets('Pattern preview renders presentation pattern copy',
      (tester) async {
    const presentation = JourneyHomePresentation(
      todayAction: JourneyHomeAction(
        icon: Icons.auto_stories_rounded,
        title: 'Separate today action',
        description: 'Today copy stays outside the pattern assertions.',
        ctaLabel: 'Continue journey',
      ),
      patterns: [
        JourneyHomePatternSignal(
          icon: Icons.local_fire_department_rounded,
          title: 'Momentum is forming',
          description: 'Three mindful days are starting to look like a rhythm.',
          tone: JourneyHomePatternTone.positive,
        ),
      ],
      milestones: [],
      completedQuestCount: 0,
      totalQuestCount: 0,
      levelProgress: 0,
    );

    await tester.pumpWidget(_buildSubject(
      summary: _summary(weeklyQuests: const [], badges: const []),
      presentation: presentation,
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () {},
    ));

    expect(find.text('Momentum is forming'), findsOneWidget);
    expect(
      find.text('Three mindful days are starting to look like a rhythm.'),
      findsOneWidget,
    );
  });

  testWidgets('Weekly arc renders progress and only first three quests',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [
        ConscienceQuest(
          key: 'quest_one',
          title: 'First quest',
          description: 'First quest description.',
          progress: 1,
          target: 1,
          xpReward: 10,
          isCompleted: true,
        ),
        ConscienceQuest(
          key: 'quest_two',
          title: 'Second quest',
          description: 'Second quest description.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
        ConscienceQuest(
          key: 'quest_three',
          title: 'Third quest',
          description: 'Third quest description.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
        ConscienceQuest(
          key: 'quest_four',
          title: 'Fourth quest',
          description: 'Fourth quest description.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
      ],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      presentation: const JourneyHomePresentation(
        todayAction: JourneyHomeAction(
          icon: Icons.auto_stories_rounded,
          title: 'Separate today action',
          description: 'Today action copy stays outside the weekly assertions.',
          ctaLabel: 'Continue journey',
        ),
        patterns: [],
        milestones: [],
        completedQuestCount: 1,
        totalQuestCount: 4,
        levelProgress: 0.5,
      ),
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () {},
    ));

    expect(find.text('1/4 commitments complete'), findsNothing);
    expect(find.text('First quest'), findsOneWidget);
    expect(find.text('Second quest'), findsOneWidget);
    expect(find.text('Third quest'), findsOneWidget);
    expect(find.text('Fourth quest'), findsNothing);
  });

  testWidgets('Journey sections use locked storybook typography',
      (tester) async {
    const presentation = JourneyHomePresentation(
      todayAction: JourneyHomeAction(
        icon: Icons.auto_stories_rounded,
        title: 'Separate today action',
        description: 'Today copy stays outside typography assertions.',
        ctaLabel: 'Continue journey',
      ),
      patterns: [
        JourneyHomePatternSignal(
          icon: Icons.local_fire_department_rounded,
          title: 'Momentum is forming',
          description: 'Three mindful days are starting to look like a rhythm.',
          tone: JourneyHomePatternTone.positive,
        ),
      ],
      milestones: [],
      completedQuestCount: 1,
      totalQuestCount: 1,
      levelProgress: 0,
    );

    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      presentation: presentation,
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () {},
    ));

    final sectionTitle = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-section-title-This Week')),
    );
    final sectionSubtitle = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-section-subtitle-This Week')),
    );
    final questTitle = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-quest-title')),
    );
    final questDescription = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-quest-description')),
    );
    final patternTitle = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-pattern-title')),
    );
    final patternDescription = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-pattern-description')),
    );

    expect(sectionTitle.style?.fontFamily, contains('CormorantGaramond'));
    expect(sectionSubtitle.style?.fontFamily, contains('Nunito'));
    expect(questTitle.style?.fontFamily, contains('CormorantGaramond'));
    expect(questDescription.style?.fontFamily, contains('Nunito'));
    expect(patternTitle.style?.fontFamily, contains('CormorantGaramond'));
    expect(patternDescription.style?.fontFamily, contains('Nunito'));
  });

  testWidgets('Weekly arc opens the Journey quests board', (tester) async {
    var openCount = 0;

    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      onOpenWeeklyArc: () => openCount++,
      onOpenWeeklyInsights: () {},
    ));

    await tester.tap(find.byKey(const ValueKey('journey-home-weekly-link')));
    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('Pattern signals open weekly insights', (tester) async {
    var openCount = 0;

    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () => openCount++,
    ));

    await tester.tap(find.byKey(const ValueKey('journey-home-patterns-link')));
    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('Empty weekly state renders and milestones hide without badges',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [],
      badges: const [],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      onOpenWeeklyArc: () {},
      onOpenWeeklyInsights: () {},
    ));

    expect(
      find.text(
          'Conscia will shape weekly commitments as your activity builds.'),
      findsOneWidget,
    );
    expect(find.text('Milestones'), findsNothing);
    expect(find.byKey(const ValueKey('journey-home-today-card')), findsNothing);
  });
}

Widget _buildSubject({
  required ConscienceJourneySummary summary,
  JourneyHomePresentation? presentation,
  required VoidCallback onOpenWeeklyArc,
  required VoidCallback onOpenWeeklyInsights,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: JourneyLedHomeSections(
          summary: summary,
          presentation: presentation ?? buildJourneyHomePresentation(summary),
          onOpenWeeklyArc: onOpenWeeklyArc,
          onOpenWeeklyInsights: onOpenWeeklyInsights,
        ),
      ),
    ),
  );
}

ConscienceJourneySummary _summary({
  List<ConscienceQuest> weeklyQuests = const [
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
  List<ConscienceBadge> badges = const [
    ConscienceBadge(
      key: 'first_reflection',
      title: 'First Reflection',
      description: 'You checked in once.',
      progress: 1,
      target: 1,
      isUnlocked: true,
    ),
  ],
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
      weeklyQuests: weeklyQuests,
      badges: badges,
    );
