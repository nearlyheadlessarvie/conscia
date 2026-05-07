import 'package:flutter/material.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';

class ImpulseTrendsCard extends StatelessWidget {
  final List<CategoryTrend> trends;

  const ImpulseTrendsCard({
    super.key,
    required this.trends,
  });

  String _trendArrow(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return '↓ Improving';
      case TrendDirection.steady:
        return '➡️ Steady';
      case TrendDirection.worsening:
        return '↗️ Impulsive';
    }
  }

  Color _trendColor(TrendDirection trend, Brightness brightness) {
    switch (trend) {
      case TrendDirection.improving:
        return brightness == Brightness.light
            ? const Color(0xFF4CAF50)
            : const Color(0xFF81C784);
      case TrendDirection.steady:
        return brightness == Brightness.light
            ? const Color(0xFF2196F3)
            : const Color(0xFF64B5F6);
      case TrendDirection.worsening:
        return brightness == Brightness.light
            ? const Color(0xFFF44336)
            : const Color(0xFFEF5350);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final topTrends = trends.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Recent Impulse Trends',
              style: textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...topTrends.map((trend) {
              final trendColor = _trendColor(trend.trend, brightness);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          TransactionTile.badgeFor(
                            trend.category,
                            size: 16,
                            filled: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trend.category,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _trendArrow(trend.trend),
                        style: textTheme.labelSmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
