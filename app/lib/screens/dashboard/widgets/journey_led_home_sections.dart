import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/behavioral_insights.dart';
import '../../../models/conscience_journey.dart';
import '../../../models/insight_feed_item.dart';
import '../../../providers/insight_feed_provider.dart';
import '../../../widgets/conscia_glyph.dart';
import '../../../widgets/feed_card.dart';
import '../../../widgets/horizontal_edge_fade.dart';
import '../journey_home_presenter.dart';

class JourneyLedHomeSections extends StatelessWidget {
  const JourneyLedHomeSections({
    super.key,
    required this.summary,
    required this.presentation,
    required this.insightSummary,
    required this.insightTrend,
    required this.onQuestSelected,
    required this.onOpenInsights,
  });

  final ConscienceJourneySummary? summary;
  final JourneyHomePresentation presentation;
  final DashboardInsightSummary? insightSummary;
  final BudgetTrendInsight? insightTrend;
  final ValueChanged<ConscienceQuest> onQuestSelected;
  final VoidCallback onOpenInsights;

  @override
  Widget build(BuildContext context) {
    final hasRealInsights = insightSummary != null || insightTrend != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JourneyHomeSection(
            title: 'This Week',
            subtitle: 'A gentle arc for building consistency.',
            child: _WeeklyArc(
              quests: _visibleWeeklyQuests(
                summary?.weeklyQuests ?? const [],
                hasRealInsights: hasRealInsights,
              ),
              onQuestSelected: onQuestSelected,
            ),
          ),
          _JourneyHomeSection(
            title: 'Insights',
            subtitle: 'What Conscia is noticing without judging.',
            child: _InsightSummaryCard(
              summary: insightSummary,
              trend: insightTrend,
              onOpenInsights: onOpenInsights,
            ),
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

const _insightDependentQuestKeys = {
  'review_regret_pattern',
  'read_two_insights',
};

List<ConscienceQuest> _visibleWeeklyQuests(
  List<ConscienceQuest> quests, {
  required bool hasRealInsights,
}) {
  if (hasRealInsights) return quests;
  return quests
      .where((quest) => !_insightDependentQuestKeys.contains(quest.key))
      .toList(growable: false);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  key: ValueKey('journey-home-section-title-$title'),
                  style: GoogleFonts.libreBaskerville(
                    textStyle: textTheme.titleLarge,
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            key: ValueKey('journey-home-section-subtitle-$title'),
            style: GoogleFonts.nunitoSans(
              textStyle: textTheme.bodySmall,
              color: colors.mutedInk,
              fontWeight: FontWeight.w500,
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

class _WeeklyArc extends StatelessWidget {
  const _WeeklyArc({
    required this.quests,
    required this.onQuestSelected,
  });

  final List<ConscienceQuest> quests;
  final ValueChanged<ConscienceQuest> onQuestSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    if (quests.isEmpty) {
      return FeedCard(
        child: Text(
          'Conscia will shape weekly commitments as your activity builds.',
          style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: HorizontalEdgeFade(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          itemCount: quests.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => SizedBox(
            width: 164,
            child: _QuestTile(
              quest: quests[index],
              index: index,
              onTap: () => onQuestSelected(quests[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.quest,
    required this.index,
    required this.onTap,
  });

  final ConscienceQuest quest;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = [
      colors.income,
      colors.amber,
      colors.devilAccent,
    ][index % 3];
    final progress = quest.target <= 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0).toDouble();

    return InkWell(
      key: const ValueKey('journey-home-quest-card'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 174,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SoftIcon(
              glyph: ConsciaGlyph.quest(
                quest.key,
                color: accent,
                size: 21,
              ),
              color: accent,
            ),
            const SizedBox(height: 10),
            Text(
              _compactQuestTitle(quest.title),
              key: const ValueKey('journey-home-quest-title'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunitoSans(
                textStyle: textTheme.labelLarge,
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Text(
                quest.description,
                key: const ValueKey('journey-home-quest-description'),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunitoSans(
                  textStyle: textTheme.labelSmall,
                  color: colors.mutedInk,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AppIcons.icon(
                  quest.isCompleted
                      ? AppIconKey.check
                      : AppIconKey.questPending,
                  keyId: ValueKey(
                    quest.isCompleted
                        ? 'journey-home-quest-complete-icon'
                        : 'journey-home-quest-pending-icon',
                  ),
                  color: quest.isCompleted ? colors.income : colors.mutedInk,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: progress,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSummaryCard extends StatelessWidget {
  const _InsightSummaryCard({
    required this.summary,
    required this.trend,
    required this.onOpenInsights,
  });

  final DashboardInsightSummary? summary;
  final BudgetTrendInsight? trend;
  final VoidCallback onOpenInsights;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final tone = summary?.tone ?? InsightFeedTone.neutral;
    final color = _insightToneColor(colors, tone);
    final hasGraph = (trend?.months.length ?? 0) >= 2;

    return InkWell(
      key: const ValueKey('journey-home-insight-card'),
      onTap: onOpenInsights,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _insightToneBackground(colors, tone),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: const ValueKey('journey-home-insight-body-icon'),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: AppIcons.icon(
                      _insightToneIcon(tone),
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trend?.category ?? _insightTitle(tone),
                        key: const ValueKey('journey-home-insight-title'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.libreBaskerville(
                          textStyle: textTheme.titleSmall,
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary?.text ??
                            'Insights are still taking shape as Conscia learns your weekly rhythm.',
                        key: const ValueKey('journey-home-insight-description'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunitoSans(
                          textStyle: textTheme.labelSmall,
                          color: colors.mutedInk,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppIcons.icon(
                  AppIconKey.chevronRight,
                  keyId: const ValueKey('journey-home-insight-chevron'),
                  color: colors.mutedInk,
                  size: 22,
                ),
              ],
            ),
            if (hasGraph) ...[
              const SizedBox(height: 12),
              SizedBox(
                key: const ValueKey('journey-home-insight-graph'),
                height: 42,
                child: CustomPaint(
                  painter: _InsightTrendPainter(
                    color: color,
                    values: trend!.months,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightTrendPainter extends CustomPainter {
  const _InsightTrendPainter({
    required this.color,
    required this.values,
  });

  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final path = Path();
    for (final entry in values.indexed) {
      final i = entry.$1;
      final value = entry.$2;
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final normalized = range == 0 ? 0.5 : (value - minValue) / range;
      final y = size.height - (normalized * size.height * 0.72) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
    final lastValue = values.last;
    final normalizedLast = range == 0 ? 0.5 : (lastValue - minValue) / range;
    canvas.drawCircle(
      Offset(
        size.width,
        size.height - (normalizedLast * size.height * 0.72) - 5,
      ),
      3.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _InsightTrendPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.values != values;
}

class _MilestoneStrip extends StatelessWidget {
  const _MilestoneStrip({required this.badges});

  final List<ConscienceBadge> badges;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 144,
      child: HorizontalEdgeFade(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              for (final badge in badges)
                SizedBox(
                  key: ValueKey('journey-home-milestone-card-${badge.key}'),
                  width: 176,
                  height: 144,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? colors.surfaceRaised
                          : colors.navySoft.withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: badge.isUnlocked
                                ? colors.incomeSoft.withValues(alpha: 0.7)
                                : colors.surfaceRaised.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: ConsciaGlyph.milestone(
                              badge.key,
                              unlocked: badge.isUnlocked,
                              color: badge.isUnlocked
                                  ? colors.income
                                  : colors.mutedInk,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          badge.isUnlocked ? badge.title : '?????',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.libreBaskerville(
                            textStyle: textTheme.labelMedium,
                            color: colors.deepNavy,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge.isUnlocked
                              ? badge.description
                              : 'Keep checking in to reveal this milestone.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunitoSans(
                            textStyle: textTheme.labelSmall,
                            color: colors.mutedInk,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.glyph, required this.color});

  final Widget glyph;
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
      child: Center(child: glyph),
    );
  }
}

Color _insightToneColor(AppColors colors, InsightFeedTone tone) {
  return switch (tone) {
    InsightFeedTone.positive => colors.income,
    InsightFeedTone.caution => colors.amber,
    InsightFeedTone.urgent => colors.devilAccent,
    InsightFeedTone.neutral => colors.deepNavy,
  };
}

Color _insightToneBackground(AppColors colors, InsightFeedTone tone) {
  return switch (tone) {
    InsightFeedTone.positive => colors.incomeSoft.withValues(alpha: 0.54),
    InsightFeedTone.caution => colors.amberSoft.withValues(alpha: 0.52),
    InsightFeedTone.urgent => colors.devilSoft.withValues(alpha: 0.5),
    InsightFeedTone.neutral => colors.navySoft.withValues(alpha: 0.44),
  };
}

AppIconKey _insightToneIcon(InsightFeedTone tone) {
  return switch (tone) {
    InsightFeedTone.positive => AppIconKey.arrowUp,
    InsightFeedTone.caution => AppIconKey.flag,
    InsightFeedTone.urgent => AppIconKey.error,
    InsightFeedTone.neutral => AppIconKey.insightTrend,
  };
}

String _insightTitle(InsightFeedTone tone) {
  return switch (tone) {
    InsightFeedTone.positive => 'Momentum is forming',
    InsightFeedTone.caution => 'Weekly rhythm',
    InsightFeedTone.urgent => 'A signal to slow down',
    InsightFeedTone.neutral => 'Your week in view',
  };
}

String _compactQuestTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('reflect')) return 'Reflect';
  if (lower.contains('insight') || lower.contains('regret')) {
    return 'Review insights';
  }
  if (lower.contains('purchase') || lower.contains('pause')) {
    return 'Hold a spending pause';
  }
  return title;
}
