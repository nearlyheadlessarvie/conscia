import 'package:flutter/material.dart';

import '../../settings/widgets/subscription_sheet.dart';
import '../../../widgets/feed_card.dart';

class PremiumGate extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String description;
  final VoidCallback? onMaybeLater;

  const PremiumGate({
    super.key,
    required this.icon,
    required this.headline,
    required this.description,
    this.onMaybeLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FeedCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => SubscriptionSheet.show(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Upgrade to Premium'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onMaybeLater ?? () => Navigator.of(context).pop(),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
