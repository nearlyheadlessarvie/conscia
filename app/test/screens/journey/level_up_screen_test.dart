import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/screens/journey/level_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('level up screen renders quiet ceremonial progress',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpScreen(summary: _summary()),
      ),
    );

    expect(find.text('Level up'), findsOneWidget);
    expect(find.text('Budget Guardian'), findsOneWidget);
    expect(find.text('Your boundaries are starting to hold.'), findsOneWidget);
    expect(find.textContaining('steadier money boundaries'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('journey-level-illustration-budget_guardian'),
      ),
      findsOneWidget,
    );
    expect(find.text('Continue your journey'), findsOneWidget);
  });
}

ConscienceJourneySummary _summary() => const ConscienceJourneySummary(
      xpTotal: 485,
      currentLevel: ConscienceLevel(
        key: 'budget_guardian',
        title: 'Budget Guardian',
        requiredXp: 400,
      ),
      nextLevel: ConscienceLevel(
        key: 'conscience_captain',
        title: 'Conscience Captain',
        requiredXp: 1000,
      ),
      xpIntoLevel: 85,
      xpToNextLevel: 515,
      momentumDays: 6,
      bestMomentumDays: 9,
      weeklyQuests: [],
      badges: [],
    );
