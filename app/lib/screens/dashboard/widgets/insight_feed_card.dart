import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'package:conscia_app/models/insight_feed_item.dart';

class InsightFeedCard extends StatelessWidget {
  const InsightFeedCard({
    super.key,
    required this.item,
    this.onDismiss,
    this.onTap,
    this.enableNavigation = true,
    this.groupedRow = false,
  });

  final InsightFeedItem item;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final bool enableNavigation;
  final bool groupedRow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(colors);
    final effectiveOnTap =
        onTap ?? (enableNavigation ? () => context.push(item.route) : null);
    final isAction = item.interaction == InsightFeedInteraction.action;
    final isDrillDown = item.interaction == InsightFeedInteraction.drillDown &&
        effectiveOnTap != null;

    final content = InkWell(
      borderRadius: BorderRadius.circular(groupedRow ? 0 : 12),
      onTap: effectiveOnTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: groupedRow ? 0 : 16,
          vertical: groupedRow ? 14 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindIcon(item: item, color: toneColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (item.metric != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: toneColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.metric!,
                      style: textTheme.labelLarge?.copyWith(
                        color: toneColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (isDrillDown) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailIcon(item: item, color: toneColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.body,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (item.caption != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          isAction ? '+ ${item.caption!}' : item.caption!,
                          style: textTheme.labelSmall?.copyWith(
                            color: toneColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (groupedRow) return content;

    return Card(child: content);
  }

  Color _toneColor(ColorScheme colors) {
    switch (item.tone) {
      case InsightFeedTone.positive:
        return colors.primary;
      case InsightFeedTone.caution:
        return colors.tertiary;
      case InsightFeedTone.urgent:
        return colors.error;
      case InsightFeedTone.neutral:
        return colors.secondary;
    }
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: _icon,
      color: color,
      size: 18,
      strokeWidth: 1.9,
    );
  }

  List<List<dynamic>> get _icon {
    switch (item.kind) {
      case InsightFeedKind.budgetTrend:
        return HugeIconsStrokeRounded.wallet01;
      case InsightFeedKind.regretSummary:
        return HugeIconsStrokeRounded.alertCircle;
      case InsightFeedKind.impulseTrend:
        return HugeIconsStrokeRounded.chartUp;
      case InsightFeedKind.weeklyMood:
        return HugeIconsStrokeRounded.brain02;
      case InsightFeedKind.worthIt:
        return HugeIconsStrokeRounded.checkmarkBadge02;
      case InsightFeedKind.merchantPattern:
        return HugeIconsStrokeRounded.store01;
    }
  }
}

class _DetailIcon extends StatelessWidget {
  const _DetailIcon({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: HugeIcon(
          icon: _icon,
          color: color,
          size: 28,
          strokeWidth: 1.9,
        ),
      ),
    );
  }

  List<List<dynamic>> get _icon {
    switch (item.kind) {
      case InsightFeedKind.budgetTrend:
        return HugeIconsStrokeRounded.targetDollar;
      case InsightFeedKind.regretSummary:
        return HugeIconsStrokeRounded.alert02;
      case InsightFeedKind.impulseTrend:
        return HugeIconsStrokeRounded.chartBarLine;
      case InsightFeedKind.weeklyMood:
        return HugeIconsStrokeRounded.sparkles;
      case InsightFeedKind.worthIt:
        return HugeIconsStrokeRounded.award01;
      case InsightFeedKind.merchantPattern:
        return HugeIconsStrokeRounded.storeLocation01;
    }
  }
}
