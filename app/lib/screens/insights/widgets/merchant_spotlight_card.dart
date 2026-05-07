import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';
import '../../../widgets/feed_card.dart';
import 'insights_formatting.dart';

class MerchantSpotlightCard extends StatelessWidget {
  final MerchantStat merchant;

  const MerchantSpotlightCard({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rate = (merchant.regretRate * 100).toStringAsFixed(0);
    final rateColor = insightRateColor(context, merchant.regretRate);

    return FeedCard(
      onTap: () => context.push('/insights/merchants'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Merchant to watch',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            merchant.merchant,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${merchant.regretCount} of ${merchant.visitCount} purchases ended in regret',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: merchant.regretRate,
              backgroundColor: colors.surfaceContainerHighest,
              color: rateColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                '$rate% regret rate',
                style: textTheme.labelSmall?.copyWith(
                  color: rateColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
