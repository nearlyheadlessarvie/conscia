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
      onContinueJourney: () {},
    ));

    expect(find.text('Today with Conscia'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('journey-home-today-card')), findsOneWidget);
  });

  testWidgets('Today CTA invokes callback and renders presentation action copy',
      (tester) async {
    var continueCount = 0;
    const presentation = JourneyHomePresentation(
      todayAction: JourneyHomeAction(
        icon: Icons.psychology_rounded,
        title: 'Pause before buying',
        description: 'Take one breath and name what this purchase is solving.',
        ctaLabel: 'Start the pause',
      ),
      patterns: [],
      milestones: [],
      completedQuestCount: 0,
      totalQuestCount: 0,
      levelProgress: 0,
    );

    await tester.pumpWidget(_buildSubject(
      summary: _summary(weeklyQuests: const []),
      presentation: presentation,
      onContinueJourney: () => continueCount++,
    ));

    expect(find.text('Pause before buying'), findsOneWidget);
    expect(
      find.text('Take one breath and name what this purchase is solving.'),
      findsOneWidget,
    );
    expect(find.text('Start the pause'), findsOneWidget);

    await tester.tap(find.text('Start the pause'));
    await tester.pump();

    expect(continueCount, 1);
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
      onContinueJourney: () {},
    ));

    expect(find.text('1/4 commitments complete'), findsOneWidget);
    expect(find.text('First quest'), findsOneWidget);
    expect(find.text('Second quest'), findsOneWidget);
    expect(find.text('Third quest'), findsOneWidget);
    expect(find.text('Fourth quest'), findsNothing);
  });

  testWidgets('Empty weekly state renders and milestones hide without badges',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [],
      badges: const [],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      onContinueJourney: () {},
    ));

    expect(
      find.text(
          'Conscia will shape weekly commitments as your activity builds.'),
      findsOneWidget,
    );
    expect(find.text('Milestones'), findsNothing);
    expect(
        find.byKey(const ValueKey('journey-home-today-card')), findsOneWidget);
  });
}

Widget _buildSubject({
  required ConscienceJourneySummary summary,
  JourneyHomePresentation? presentation,
  required VoidCallback onContinueJourney,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: JourneyLedHomeSections(
          summary: summary,
          presentation: presentation ?? buildJourneyHomePresentation(summary),
          onContinueJourney: onContinueJourney,
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
