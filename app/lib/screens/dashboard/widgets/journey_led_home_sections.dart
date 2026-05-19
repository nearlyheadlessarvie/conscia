import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/conscience_journey.dart';
import '../../../widgets/feed_card.dart';
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
          _JourneyHomeSection(
            title: 'Today with Conscia',
            subtitle: 'The smallest useful move for your money behavior today.',
            child: _TodayWithConsciaCard(
              action: presentation.todayAction,
              onPressed: onContinueJourney,
            ),
          ),
          _JourneyHomeSection(
            title: 'This Week',
            subtitle: 'A gentle arc for building consistency.',
            child: _WeeklyArc(
              quests: summary?.weeklyQuests ?? const [],
              completed: presentation.completedQuestCount,
              total: presentation.totalQuestCount,
            ),
          ),
          _JourneyHomeSection(
            title: 'Patterns',
            subtitle: 'What Conscia is noticing without judging.',
            child: _PatternPreview(patterns: presentation.patterns),
          ),
          if (presentation.milestones.isNotEmpty)
            _JourneyHomeSection(
              title: 'Milestones',
              subtitle: 'Proof that small check-ins are adding up.',
              child: _MilestoneStrip(badges: presentation.milestones),
            ),
        ],
      ),
    );
  }
}

class _JourneyHomeSection extends StatelessWidget {
  const _JourneyHomeSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          child,
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
          for (final quest in visibleQuests) _QuestRow(quest: quest),
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
                  _SoftIcon(
                    icon: pattern.icon,
                    color: _toneColor(context, pattern),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pattern.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pattern.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
