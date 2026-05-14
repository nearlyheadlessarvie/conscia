import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetTrendsCard extends ConsumerWidget {
  const BudgetTrendsCard({
    super.key,
    required this.trends,
  });

  final List<BudgetTrendInsight> trends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = ref.watch(userPreferencesProvider).locale;

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
                  child: _BudgetTrendRow(trend: trend, locale: locale),
                )),
          ],
        ),
      ),
    );
  }
}

class _BudgetTrendRow extends StatelessWidget {
  const _BudgetTrendRow({required this.trend, required this.locale});

  final BudgetTrendInsight trend;
  final String? locale;

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
                  : _formatCurrency(
                      trend.currencyCode,
                      trend.currentMonthSpend,
                      locale,
                    ),
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

  String _buildMonthsLabel(BudgetTrendInsight trend) {
    final values = trend.months.map((value) {
      if (trend.hasBudget) {
        return '${value.toStringAsFixed(0)}%';
      }

      return _formatCurrency(trend.currencyCode, value, locale);
    }).join('  •  ');

    return values;
  }

  static String _formatCurrency(
    String currencyCode,
    double value,
    String? locale,
  ) {
    return CurrencyFormatter.format(
      value,
      currencyCode: currencyCode,
      locale: locale,
    );
  }
}
