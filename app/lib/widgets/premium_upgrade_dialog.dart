import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';
import 'conscia_bottom_sheet.dart';
import '../screens/settings/widgets/subscription_sheet.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  final String feature;

  const PremiumUpgradeDialog({super.key, required this.feature});

  static Future<void> show(BuildContext context, {required String feature}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => PremiumUpgradeDialog(feature: feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return ConsciaBottomSheetScaffold(
      title: 'Premium Feature',
      subtitle: 'Unlock the full Conscia flow without extra limits.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              SubscriptionSheet.show(context);
            },
            child: const Text('Upgrade to Premium'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.navySoft.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppIcons.icon(
                    AppIconKey.premium,
                    color: colors.deepNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upgrade when you want the full category set and unlimited access.',
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
          ),
        ],
      ),
    );
  }
}
