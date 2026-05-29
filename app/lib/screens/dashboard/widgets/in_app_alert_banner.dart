import 'package:flutter/material.dart';

import 'package:conscia_app/core/constants/app_icons.dart';
import 'package:conscia_app/widgets/feed_card.dart';

class InAppAlertBanner extends StatelessWidget {
  const InAppAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onTap,
    this.onDismiss,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FeedCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcons.icon(
              AppIconKey.sparkleGuidance,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
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
    );
  }
}
