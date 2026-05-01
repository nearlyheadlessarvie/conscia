import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/widgets/budget_progress_bar.dart';
import 'package:conscia_app/widgets/currency_badge.dart';

class BudgetSummaryCard extends StatelessWidget {
  final IconData categoryIcon;
  final String categoryName;
  final double spent;
  final double limit;
  final String currencyCode;
  final String locale;

  const BudgetSummaryCard({
    super.key,
    required this.categoryIcon,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.currencyCode,
    this.locale = 'en-US',
  });

  double get _percentage => limit > 0 ? spent / limit : 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 0,
    );

    final pctText = '${(_percentage * 100).round()}%';

    return GestureDetector(
      onTap: () => context.push('/settings/budgets'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(categoryIcon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatter.format(spent)} / ${formatter.format(limit)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  pctText,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BudgetProgressBar(percentage: _percentage),
            const SizedBox(height: 8),
            CurrencyBadge(currencyCode: currencyCode),
          ],
        ),
      ),
    );
  }
}
