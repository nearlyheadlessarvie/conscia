import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../screens/transactions/widgets/transaction_tile.dart';
import '../../../widgets/budget_progress_bar.dart';

class BudgetContextCard extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final String currencyCode;
  final String? locale;
  final double projectedAmount;

  const BudgetContextCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.currencyCode,
    this.locale,
    required this.projectedAmount,
  });

  double get _currentPct => limit > 0 ? spent / limit : 0;
  double get _projectedPct => limit > 0 ? (spent + projectedAmount) / limit : 0;

  Color _projectedColor() {
    final pct = _projectedPct;
    if (pct >= 1.0) return const Color(0xFFE53935);
    if (pct >= 0.8) return const Color(0xFFFF9800);
    if (pct >= 0.5) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final projPctInt = (_projectedPct * 100).round();

    return Card(
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  TransactionTile.iconFor(category),
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$category Budget',
                  style: textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(
                    spent,
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / ${CurrencyFormatter.format(
                    limit,
                    currencyCode: currencyCode,
                    locale: locale,
                  )}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_currentPct * 100).round()}%',
                  style: textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            BudgetProgressBar(percentage: _currentPct),
            const SizedBox(height: 12),
            Text(
              'This purchase would bring you to $projPctInt%',
              style: textTheme.bodyMedium?.copyWith(
                color: _projectedColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
