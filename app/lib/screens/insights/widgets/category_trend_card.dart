import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_icons.dart';
import '../../../models/insights_models.dart';
import '../../../widgets/feed_card.dart';
import 'insights_formatting.dart';

class CategoryTrendCard extends StatelessWidget {
  final CategoryStat category;
  final String currencyCode;
  final String? locale;

  const CategoryTrendCard({
    super.key,
    required this.category,
    required this.currencyCode,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretText = formatInsightCurrency(
      category.regrettedSpend,
      currencyCode: currencyCode,
      locale: locale,
    );
    final projectedText = formatInsightCompactCurrency(
      category.projectedAnnual,
      currencyCode: currencyCode,
      locale: locale,
    );
    final rate = (category.regretRate * 100).toStringAsFixed(0);

    return FeedCard(
      onTap: () => context.push('/insights/categories'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcons.badge(category.category, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Category trend',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            category.category,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '$regretText regretted across ${category.transactionCount} purchases',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                label: '$rate% regret rate',
                tint: insightRateColor(context, category.regretRate),
              ),
              _InfoPill(
                label: '$projectedText projected yearly',
                tint: colors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: tint,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
