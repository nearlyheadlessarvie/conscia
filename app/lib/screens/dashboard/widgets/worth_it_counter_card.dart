import 'package:flutter/material.dart';

class WorthItCounterCard extends StatelessWidget {
  final int thisMonthCount;
  final int previousMonthCount;

  const WorthItCounterCard({
    super.key,
    required this.thisMonthCount,
    required this.previousMonthCount,
  });

  String _trendIndicator() {
    if (thisMonthCount > previousMonthCount) {
      return '📈 +${thisMonthCount - previousMonthCount} vs last month';
    } else if (thisMonthCount < previousMonthCount) {
      return '📉 ${thisMonthCount - previousMonthCount} vs last month';
    } else {
      return '➡️ Same as last month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withOpacity(0.1),
              colors.primary.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Worth It This Month',
              style: textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You've made $thisMonthCount decisions",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      "you're proud of",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withOpacity(0.2),
                  ),
                  child: Text(
                    thisMonthCount.toString(),
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _trendIndicator(),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
