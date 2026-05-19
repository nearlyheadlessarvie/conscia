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
    expect(
        find.byKey(const ValueKey('journey-home-today-card')), findsOneWidget);
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
          description:
              'Check how recent spending felt after the moment passed.',
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
