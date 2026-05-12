import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/screens/journey/conscience_journey_screen.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders journey progress, quests, and badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConscienceJourneyContent(summary: _summary()),
          ),
        ),
      ),
    );

    expect(find.text('Budget Guardian'), findsOneWidget);
    expect(find.text('485 XP'), findsOneWidget);
    expect(find.text('6-day momentum'), findsOneWidget);
    expect(find.text('Weekly quests'), findsOneWidget);
    expect(find.text('Reflect on 3 purchases'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First Reflection'), findsOneWidget);
    expect(find.text('Budget Rescuer'), findsOneWidget);
    expect(find.text('Mascot moment'), findsOneWidget);
    expect(find.text('You paused before buying.'), findsOneWidget);
  });

  testWidgets('opens the journey guide from the header help icon',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conscienceJourneyServiceProvider
              .overrideWithValue(_StaticConscienceJourneyService()),
        ],
        child: const MaterialApp(home: ConscienceJourneyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Journey guide'));
    await tester.pumpAndSettle();

    expect(find.text('How Journey works'), findsOneWidget);
    expect(find.text('Only 3 quests show up each week.'), findsOneWidget);
    expect(find.text('400 XP'), findsOneWidget);
    expect(
        find.text('More levels can arrive in future updates.'), findsOneWidget);
    expect(find.text('Possible weekly quest'), findsNothing);
    expect(find.text('Counts reflections that turn spending into signal.'),
        findsOneWidget);
    expect(find.text('Invited someone into a family space.'), findsOneWidget);
    expect(find.text('Invite a family member.'), findsOneWidget);
    expect(find.text('Add a household contribution.'), findsNothing);
    expect(find.text('Mystery achievements'), findsOneWidget);
    expect(find.text('Mascot moments'), findsOneWidget);
  });
}

class _StaticConscienceJourneyService extends ConscienceJourneyService {
  _StaticConscienceJourneyService() : super(Dio());

  @override
  Future<ConscienceJourneySummary> fetchJourney() async => _summary();
}

ConscienceJourneySummary _summary() => ConscienceJourneySummary(
      xpTotal: 485,
      currentLevel: const ConscienceLevel(
        key: 'budget_guardian',
        title: 'Budget Guardian',
        requiredXp: 400,
      ),
      nextLevel: const ConscienceLevel(
        key: 'conscience_captain',
        title: 'Conscience Captain',
        requiredXp: 1000,
      ),
      xpIntoLevel: 85,
      xpToNextLevel: 515,
      momentumDays: 6,
      bestMomentumDays: 9,
      weeklyQuests: [
        ConscienceQuest(
          key: 'reflect_three_purchases',
          title: 'Reflect on 3 purchases',
          description: 'Turn recent decisions into useful signal.',
          progress: 3,
          target: 3,
          xpReward: 15,
          isCompleted: true,
          completedAt: DateTime.utc(2026, 5, 11),
        ),
      ],
      badges: [
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'Reflected on your first purchase.',
          progress: 1,
          target: 1,
          isUnlocked: true,
          unlockedAt: DateTime.utc(2026, 5, 1),
        ),
        const ConscienceBadge(
          key: 'budget_rescuer',
          title: 'Budget Rescuer',
          description: 'Created a budget from a nudge.',
          progress: 0,
          target: 1,
          isUnlocked: false,
        ),
      ],
      recentMascotMoment: ConscienceMascotMoment(
        key: 'pause_before_purchase',
        persona: 'both',
        title: 'You paused before buying.',
        message: 'Impulse and Reason both got a seat at the table.',
        createdAt: DateTime.utc(2026, 5, 11),
      ),
    );
