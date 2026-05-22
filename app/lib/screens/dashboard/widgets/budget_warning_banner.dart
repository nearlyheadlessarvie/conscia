import 'package:flutter/material.dart';

import 'package:conscia_app/core/constants/app_icons.dart';
import 'package:conscia_app/widgets/feed_card.dart';

class BudgetWarningBanner extends StatelessWidget {
  final int overBudgetCount;
  final VoidCallback? onDismiss;

  const BudgetWarningBanner({
    super.key,
    required this.overBudgetCount,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FeedCard(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AppIcons.icon(
                  AppIconKey.warning,
                  color: const Color(0xFFFF9800),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Alert',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$overBudgetCount budget${overBudgetCount > 1 ? 's' : ''} over 80%',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: AppIcons.icon(
                      AppIconKey.close,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
