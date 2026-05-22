import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../settings/widgets/subscription_sheet.dart';

class PremiumGate extends StatelessWidget {
  final AppIconKey icon;
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
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.navySoft, colors.amberSoft],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppLayout.screenPadding,
              AppLayout.bleedingHeroTop(context),
              AppLayout.screenPadding,
              AppLayout.heroBottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREMIUM RECEIPT SCAN',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Snap receipts. Skip the typing.',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PremiumHeroChip(label: 'Merchant'),
                    _PremiumHeroChip(label: 'Total'),
                    _PremiumHeroChip(label: 'Category'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            26,
            AppLayout.screenPadding,
            36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREMIUM FEATURE',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.mutedInk,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppLayout.listIconSize,
                    height: AppLayout.listIconSize,
                    decoration: BoxDecoration(
                      color: colors.navySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AppIcons.icon(
                        icon,
                        color: colors.deepNavy,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upgrade when you want Conscia to read the receipt for you. You can still add the expense manually.',
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => SubscriptionSheet.show(context),
                  child: const Text('Upgrade to Premium'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onMaybeLater ?? () => Navigator.of(context).pop(),
                  child: const Text('Maybe Later'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumHeroChip extends StatelessWidget {
  const _PremiumHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
