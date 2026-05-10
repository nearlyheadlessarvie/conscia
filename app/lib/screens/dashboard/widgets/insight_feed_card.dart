import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InsightFeedCard extends StatelessWidget {
  const InsightFeedCard({
    super.key,
    required this.item,
    this.onDismiss,
  });

  final InsightFeedItem item;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(colors);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MascotCameo(item: item, color: toneColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (item.caption != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.caption!,
                        style: textTheme.labelSmall?.copyWith(
                          color: toneColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.dismissible && onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Dismiss insight',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

class _MascotCameo extends StatelessWidget {
  const _MascotCameo({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (item.mascot == InsightFeedMascot.none) {
      return _FallbackIcon(item: item, color: color);
    }

    return SizedBox(
      width: 48,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (item.mascot == InsightFeedMascot.angel ||
              item.mascot == InsightFeedMascot.both)
            MascotSpriteFrame(
              atlas: angelMascotAtlas,
              frameName:
                  _frameFor('angel', item.mascotFrame) ?? '1_neutral.png',
              width: item.mascot == InsightFeedMascot.both ? 36 : 44,
            ),
          if (item.mascot == InsightFeedMascot.devil ||
              item.mascot == InsightFeedMascot.both)
            Positioned(
              left: item.mascot == InsightFeedMascot.both ? 16 : 0,
              top: item.mascot == InsightFeedMascot.both ? 8 : 0,
              child: MascotSpriteFrame(
                atlas: devilMascotAtlas,
                frameName:
                    _frameFor('devil', item.mascotFrame) ?? '1_neutral.png',
                width: item.mascot == InsightFeedMascot.both ? 36 : 44,
              ),
            ),
        ],
      ),
    );
  }

  static String? _frameFor(String family, String? descriptor) {
    if (descriptor == null) return null;
    for (final part in descriptor.split('|')) {
      final pieces = part.split(':');
      if (pieces.length == 2 && pieces.first == family) {
        return pieces.last;
      }
    }
    return null;
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_icon, color: color),
    );
  }

  IconData get _icon {
    switch (item.kind) {
      case InsightFeedKind.budgetTrend:
        return Icons.account_balance_wallet_rounded;
      case InsightFeedKind.regretSummary:
        return Icons.warning_amber_rounded;
      case InsightFeedKind.impulseTrend:
        return Icons.trending_up_rounded;
      case InsightFeedKind.weeklyMood:
        return Icons.psychology_rounded;
      case InsightFeedKind.worthIt:
        return Icons.thumb_up_alt_rounded;
      case InsightFeedKind.merchantPattern:
        return Icons.storefront_rounded;
    }
  }
}
