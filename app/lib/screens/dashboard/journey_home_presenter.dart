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
    milestones: _milestones(summary),
    completedQuestCount: completedQuestCount,
    totalQuestCount: totalQuestCount,
    levelProgress: _levelProgress(summary),
  );
}

List<ConscienceBadge> _milestones(ConscienceJourneySummary? summary) {
  final badges = [...summary?.badges ?? const <ConscienceBadge>[]]
    ..sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      final aProgress = a.target <= 0 ? 0 : a.progress / a.target;
      final bProgress = b.target <= 0 ? 0 : b.progress / b.target;
      return bProgress.compareTo(aProgress);
    });
  return badges.toList(growable: false);
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
    description:
        'Pick one transaction and mark whether it still feels worth it.',
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
    'read_two_insights' => Icons.query_stats_rounded,
    'create_budget_guardrail' => Icons.account_balance_wallet_rounded,
    'send_family_invite' => Icons.group_add_rounded,
    'add_family_expense' => Icons.receipt_long_rounded,
    _ => Icons.flag_rounded,
  };
}
