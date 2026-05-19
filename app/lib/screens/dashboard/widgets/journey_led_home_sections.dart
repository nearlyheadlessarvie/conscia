import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/conscience_journey.dart';
import '../../../widgets/feed_card.dart';
import '../journey_home_presenter.dart';

class JourneyLedHomeSections extends StatelessWidget {
  const JourneyLedHomeSections({
    super.key,
    required this.summary,
    required this.presentation,
    required this.onOpenWeeklyArc,
    required this.onOpenWeeklyInsights,
  });

  final ConscienceJourneySummary? summary;
  final JourneyHomePresentation presentation;
  final VoidCallback onOpenWeeklyArc;
  final VoidCallback onOpenWeeklyInsights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JourneyHomeSection(
            title: 'This Week',
            subtitle: 'A gentle arc for building consistency.',
            linkKey: const ValueKey('journey-home-weekly-link'),
            onTap: onOpenWeeklyArc,
            trailing: const _SectionHint(label: 'Your weekly arc'),
            child: _WeeklyArc(
              quests: summary?.weeklyQuests ?? const [],
            ),
          ),
          _JourneyHomeSection(
            title: 'Patterns',
            subtitle: 'What Conscia is noticing without judging.',
            linkKey: const ValueKey('journey-home-patterns-link'),
            onTap: onOpenWeeklyInsights,
            trailing: const _SectionHint(label: 'Signals from your week'),
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
    this.trailing,
    this.linkKey,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final Key? linkKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;

    final content = Padding(
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
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
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

    if (onTap == null) return content;

    return GestureDetector(
      key: linkKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class _WeeklyArc extends StatelessWidget {
  const _WeeklyArc({required this.quests});

  final List<ConscienceQuest> quests;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in visibleQuests.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: entry.$1 == visibleQuests.length - 1 ? 0 : 8,
                  ),
                  child: _QuestTile(quest: entry.$2, index: entry.$1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest, required this.index});

  final ConscienceQuest quest;
  final int index;

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

    return Container(
      height: 174,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SoftIcon(icon: _questIcon(quest.key), color: accent),
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
              Icon(
                quest.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: quest.isCompleted ? colors.income : colors.deepNavy,
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
    );
  }
}

class _PatternPreview extends StatelessWidget {
  const _PatternPreview({required this.patterns});

  final List<JourneyHomePatternSignal> patterns;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in patterns.take(2).indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.$1 == 1 ? 0 : 8),
              child: _PatternSignalCard(
                pattern: entry.$2,
                color: _toneColor(context, entry.$2),
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

class _PatternSignalCard extends StatelessWidget {
  const _PatternSignalCard({
    required this.pattern,
    required this.color,
  });

  final JourneyHomePatternSignal pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pattern.tone == JourneyHomePatternTone.positive
            ? colors.incomeSoft.withValues(alpha: 0.54)
            : colors.devilSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pattern.icon, color: color, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  pattern.tone == JourneyHomePatternTone.positive
                      ? 'Improving'
                      : 'Watch this',
                  style: GoogleFonts.nunitoSans(
                    textStyle: textTheme.labelSmall,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pattern.title,
            key: const ValueKey('journey-home-pattern-title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunitoSans(
              textStyle: textTheme.labelLarge,
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: CustomPaint(
              painter: _SignalLinePainter(
                color: color,
                positive: pattern.tone == JourneyHomePatternTone.positive,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pattern.description,
            key: const ValueKey('journey-home-pattern-description'),
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
    );
  }
}

class _SignalLinePainter extends CustomPainter {
  const _SignalLinePainter({
    required this.color,
    required this.positive,
  });

  final Color color;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final x = size.width * i / 5;
      final base = positive
          ? size.height * (0.82 - i * 0.09)
          : size.height * (0.56 + (i == 4 ? 0.18 : 0.02 * i));
      final y = base + (i.isEven ? 4 : -3);
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
    canvas.drawCircle(
      Offset(size.width, positive ? size.height * 0.33 : size.height * 0.68),
      3.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SignalLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.positive != positive;
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
                style: GoogleFonts.libreBaskerville(
                  textStyle: Theme.of(context).textTheme.labelMedium,
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w700,
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

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            textStyle: Theme.of(context).textTheme.labelSmall,
            color: colors.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 15, color: colors.mutedInk),
      ],
    );
  }
}

IconData _questIcon(String key) {
  return switch (key) {
    'reflect_three_purchases' => Icons.auto_stories_rounded,
    'check_before_purchase' => Icons.psychology_rounded,
    'review_regret_pattern' => Icons.loop_rounded,
    'send_family_invite' => Icons.group_add_rounded,
    'add_family_expense' => Icons.receipt_long_rounded,
    _ => Icons.flag_rounded,
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
