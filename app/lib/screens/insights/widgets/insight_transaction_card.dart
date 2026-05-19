import 'package:flutter/material.dart';

import '../../../core/constants/category_icons.dart';
import '../../../models/insights_models.dart';
import '../../../widgets/feed_card.dart';
import 'insights_formatting.dart';

class InsightTransactionCard extends StatelessWidget {
  const InsightTransactionCard({
    super.key,
    required this.tx,
    this.locale,
    this.title,
    this.subtitle,
    this.leading,
  });

  final TransactionSummary tx;
  final String? locale;
  final String? title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regret = insightRegretPresentation(context, tx.regretLevel);
    final amountText = formatInsightCurrency(
      tx.amount,
      currencyCode: tx.currencyCode,
      locale: locale,
    );

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading ??
              CategoryIcons.badge(
                tx.category,
                size: 18,
                type: 'Expense',
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? tx.merchant ?? tx.category,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? formatInsightDate(tx.date, locale: locale),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: regret.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(regret.icon, size: 14, color: regret.color),
                        const SizedBox(width: 6),
                        Text(
                          regret.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: regret.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
