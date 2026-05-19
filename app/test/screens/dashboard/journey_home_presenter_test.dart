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
