import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:conscia_app/screens/dashboard/widgets/journey_led_home_sections.dart';
import 'package:conscia_app/widgets/horizontal_edge_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('JourneyLedHomeSections renders primary Journey modules',
      (tester) async {
    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      insightSummary: const DashboardInsightSummary(
        text: 'Dining is above your recent 3-month pace.',
        tone: InsightFeedTone.caution,
      ),
      insightTrend: _budgetTrend(),
    ));

    expect(find.text('Today with Conscia'), findsNothing);
    expect(find.byKey(const ValueKey('journey-home-today-card')), findsNothing);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Patterns'), findsNothing);
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
      insightSummary: const DashboardInsightSummary(
        text: 'More of your decisions are feeling worth it than last month.',
        tone: InsightFeedTone.positive,
      ),
      insightTrend: null,
    ));

    expect(find.text('Insights'), findsOneWidget);
    expect(
      find.text('More of your decisions are feeling worth it than last month.'),
      findsOneWidget,
    );
  });

  testWidgets('Weekly arc renders progress for every current quest',
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
      insightSummary: null,
      insightTrend: null,
    ));

    expect(find.text('1/4 commitments complete'), findsNothing);
    expect(find.text('First quest'), findsOneWidget);
    expect(find.text('Second quest'), findsOneWidget);
    expect(find.text('Third quest'), findsOneWidget);
    expect(find.text('Fourth quest'), findsOneWidget);
  });

  testWidgets('Weekly arc shows all quests in fixed-width horizontal cards',
      (tester) async {
    final summary = _summary(
      weeklyQuests: List.generate(
        5,
        (index) => ConscienceQuest(
          key: 'quest_$index',
          title: 'Quest ${index + 1}',
          description: 'Quest ${index + 1} description.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
      ),
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      insightSummary: null,
      insightTrend: null,
    ));

    expect(find.text('Your weekly arc'), findsNothing);
    expect(
        find.byKey(const ValueKey('journey-home-weekly-link')), findsNothing);
    expect(find.text('0/5 commitments complete'), findsNothing);
    expect(find.byKey(const ValueKey('journey-home-quest-card')),
        findsNWidgets(5));
    expect(find.byType(HorizontalEdgeFade), findsWidgets);
    expect(find.byKey(const ValueKey('journey-home-quest-open-hint')),
        findsNothing);
    expect(find.byKey(const ValueKey('journey-home-quest-pending-icon')),
        findsNWidgets(5));
    expect(find.byKey(const ValueKey('journey-home-quest-complete-icon')),
        findsNothing);

    final firstCard = tester.getSize(
      find.byKey(const ValueKey('journey-home-quest-card')).first,
    );
    final secondCard = tester.getSize(
      find.byKey(const ValueKey('journey-home-quest-card')).at(1),
    );

    expect(firstCard.width, closeTo(164, 0.1));
    expect(secondCard.width, firstCard.width);
  });

  testWidgets('Weekly quest cards invoke the selected quest', (tester) async {
    ConscienceQuest? selectedQuest;
    final summary = _summary(
      weeklyQuests: const [
        ConscienceQuest(
          key: 'review_regret_pattern',
          title: 'Review one regret pattern',
          description: 'Spot one repeat spending signal.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
      ],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      insightSummary: null,
      insightTrend: null,
      onQuestSelected: (quest) => selectedQuest = quest,
    ));

    await tester.tap(find.byKey(const ValueKey('journey-home-quest-card')));
    await tester.pump();

    expect(selectedQuest?.key, 'review_regret_pattern');
  });

  testWidgets('Weekly quest cards distinguish complete and outstanding states',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [
        ConscienceQuest(
          key: 'quest_open',
          title: 'Open quest',
          description: 'Still outstanding.',
          progress: 0,
          target: 1,
          xpReward: 10,
          isCompleted: false,
        ),
        ConscienceQuest(
          key: 'quest_done',
          title: 'Done quest',
          description: 'Already complete.',
          progress: 1,
          target: 1,
          xpReward: 10,
          isCompleted: true,
        ),
      ],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      insightSummary: null,
      insightTrend: null,
    ));

    expect(find.byKey(const ValueKey('journey-home-quest-pending-icon')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey-home-quest-complete-icon')),
        findsOneWidget);
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
      insightSummary: const DashboardInsightSummary(
        text: 'Recent reflections point to a calmer week.',
        tone: InsightFeedTone.positive,
      ),
      insightTrend: _budgetTrend(),
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
      find.byKey(const ValueKey('journey-home-insight-title')),
    );
    final patternDescription = tester.widget<Text>(
      find.byKey(const ValueKey('journey-home-insight-description')),
    );

    expect(sectionTitle.style?.fontFamily, contains('LibreBaskerville'));
    expect(sectionSubtitle.style?.fontFamily, contains('Nunito'));
    expect(questTitle.style?.fontFamily, contains('Nunito'));
    expect(questDescription.style?.fontFamily, contains('Nunito'));
    expect(patternTitle.style?.fontFamily, contains('LibreBaskerville'));
    expect(patternDescription.style?.fontFamily, contains('Nunito'));
  });

  testWidgets('Insights section renders real summary and optional graph',
      (tester) async {
    var openedInsights = false;

    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      insightSummary: const DashboardInsightSummary(
        text: 'Dining is above your recent 3-month pace.',
        tone: InsightFeedTone.caution,
      ),
      insightTrend: _budgetTrend(),
      onOpenInsights: () => openedInsights = true,
    ));

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Patterns'), findsNothing);
    expect(find.text('Signals from your week'), findsNothing);
    expect(
        find.byKey(const ValueKey('journey-home-patterns-link')), findsNothing);
    expect(
        find.text('Dining is above your recent 3-month pace.'), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-home-insight-graph')),
        findsOneWidget);
    expect(find.text('Needs care'), findsNothing);
    expect(find.byKey(const ValueKey('journey-home-insight-body-icon')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey-home-insight-chevron')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('journey-home-insight-card')));
    await tester.pump();

    expect(openedInsights, isTrue);
  });

  testWidgets('Insights summary shrinks when no trend graph is available',
      (tester) async {
    await tester.pumpWidget(_buildSubject(
      summary: _summary(),
      insightSummary: const DashboardInsightSummary(
        text: 'Shopping is carrying your strongest regret signal right now.',
        tone: InsightFeedTone.urgent,
      ),
      insightTrend: null,
    ));

    expect(
        find.byKey(const ValueKey('journey-home-insight-graph')), findsNothing);
    final cardSize =
        tester.getSize(find.byKey(const ValueKey('journey-home-insight-card')));
    expect(cardSize.height, lessThan(120));
  });

  testWidgets('Milestones render fixed-size cards and tease locked badges',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [],
      badges: const [
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'Reflected on your first purchase.',
          progress: 1,
          target: 1,
          isUnlocked: true,
        ),
        ConscienceBadge(
          key: 'future_badge',
          title: 'Future Badge',
          description: 'Should be hidden while locked.',
          progress: 0,
          target: 2,
          isUnlocked: false,
        ),
      ],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      insightSummary: null,
      insightTrend: null,
    ));

    expect(find.text('Milestones'), findsOneWidget);
    final firstCard = find.byKey(
      const ValueKey('journey-home-milestone-card-first_reflection'),
    );
    final lockedCard = find.byKey(
      const ValueKey('journey-home-milestone-card-future_badge'),
    );
    expect(firstCard, findsOneWidget);
    expect(lockedCard, findsOneWidget);
    expect(tester.getSize(firstCard), const Size(176, 144));
    expect(tester.getSize(lockedCard), const Size(176, 144));
    expect(find.text('First Reflection'), findsOneWidget);
    expect(find.text('Reflected on your first purchase.'), findsOneWidget);
    expect(find.text('1/1'), findsNothing);
    expect(find.text('Future Badge'), findsNothing);
    expect(find.text('Should be hidden while locked.'), findsNothing);
    expect(find.text('?????'), findsOneWidget);
    expect(find.text('Keep checking in to reveal this milestone.'),
        findsOneWidget);
  });

  testWidgets('Empty weekly state renders and milestones hide without badges',
      (tester) async {
    final summary = _summary(
      weeklyQuests: const [],
      badges: const [],
    );

    await tester.pumpWidget(_buildSubject(
      summary: summary,
      insightSummary: null,
      insightTrend: null,
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
  required DashboardInsightSummary? insightSummary,
  required BudgetTrendInsight? insightTrend,
  ValueChanged<ConscienceQuest>? onQuestSelected,
  VoidCallback? onOpenInsights,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: JourneyLedHomeSections(
          summary: summary,
          presentation: presentation ?? buildJourneyHomePresentation(summary),
          insightSummary: insightSummary,
          insightTrend: insightTrend,
          onQuestSelected: onQuestSelected ?? (_) {},
          onOpenInsights: onOpenInsights ?? () {},
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

BudgetTrendInsight _budgetTrend() => const BudgetTrendInsight(
      category: 'Dining',
      hasBudget: true,
      currencyCode: 'PHP',
      months: [42, 54, 68, 82],
      currentMonthSpend: 8200,
      currentMonthPercentUsed: 82,
      insightLabel: 'Dining is trending higher.',
    );
