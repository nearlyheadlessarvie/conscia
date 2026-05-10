import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

class BudgetTrendsCard extends StatelessWidget {
  const BudgetTrendsCard({
    super.key,
    required this.trends,
  });

  final List<BudgetTrendInsight> trends;

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget trends',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This month against your last 3 months.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...trends.take(3).map((trend) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BudgetTrendRow(trend: trend),
                )),
          ],
        ),
      ),
    );
  }
}

class _BudgetTrendRow extends StatelessWidget {
  const _BudgetTrendRow({required this.trend});

  final BudgetTrendInsight trend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TransactionTile.badgeFor(
              trend.category,
              size: 16,
              filled: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                trend.category,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              trend.hasBudget
                  ? '${trend.currentMonthPercentUsed?.toStringAsFixed(0) ?? '0'}%'
                  : _formatCurrency(trend.currencyCode, trend.currentMonthSpend),
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _buildMonthsLabel(trend),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          trend.nudge ?? trend.insightLabel,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _buildMonthsLabel(BudgetTrendInsight trend) {
    final values = trend.months.map((value) {
      if (trend.hasBudget) {
        return '${value.toStringAsFixed(0)}%';
      }

      return _formatCurrency(trend.currencyCode, value);
    }).join('  •  ');

    return values;
  }

  static String _formatCurrency(String currencyCode, double value) {
    final whole = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return '$currencyCode$whole';
  }
}
