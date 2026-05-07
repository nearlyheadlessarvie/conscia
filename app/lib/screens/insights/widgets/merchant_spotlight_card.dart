import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';

class MerchantSpotlightCard extends StatelessWidget {
  final MerchantStat merchant;

  const MerchantSpotlightCard({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rate = (merchant.regretRate * 100).toStringAsFixed(0);

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights/merchants'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🏪 Merchant to watch',
                      style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(merchant.merchant,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${merchant.regretCount} of ${merchant.visitCount} purchases regretted',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: merchant.regretRate,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: colors.error,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('$rate% regret rate',
                  style: textTheme.labelSmall?.copyWith(color: colors.error)),
            ],
          ),
        ),
      ),
    );
  }
}
