import 'package:flutter/material.dart';

import '../screens/settings/widgets/subscription_sheet.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  final String feature;

  const PremiumUpgradeDialog({super.key, required this.feature});

  static Future<void> show(BuildContext context, {required String feature}) {
    return showDialog(
      context: context,
      builder: (_) => PremiumUpgradeDialog(feature: feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(Icons.workspace_premium, size: 48, color: colors.secondary),
      title: const Text('Premium Feature'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feature,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Upgrade to Conscia Premium to unlock unlimited access.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            SubscriptionSheet.show(context);
          },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}
