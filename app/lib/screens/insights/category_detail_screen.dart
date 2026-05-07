import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(categoryDetailProvider(category));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load data.')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('No data found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CategoryStatsHeader(stats: detail.stats),
              const SizedBox(height: 16),
              Text('Recent transactions',
                  style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...detail.recentTransactions.map((t) => _TransactionRow(tx: t)),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryStatsHeader extends StatelessWidget {
  final CategoryStat stats;

  const _CategoryStatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final rate = (stats.regretRate * 100).toStringAsFixed(0);
    final rateColor = stats.regretRate >= 0.6
        ? colors.error
        : stats.regretRate >= 0.4
            ? colors.tertiary
            : colors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('£${stats.totalSpend.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('spent', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
                Column(children: [
                  Text('£${stats.regrettedSpend.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: rateColor)),
                  Text('regretted', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
                Column(children: [
                  Text('$rate%',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: rateColor)),
                  Text('rate', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: colors.onErrorContainer, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '£${stats.projectedAnnual.toStringAsFixed(0)} in regretted spend projected this year',
                    style: textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionSummary tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretEmoji = switch (tx.regretLevel?.toLowerCase()) {
      'worthit' => '✅',
      'regret' => '❌',
      'notsure' => '🤔',
      _ => '—',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(regretEmoji),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tx.merchant ?? tx.category, style: textTheme.bodyMedium),
          ),
          Text('${tx.currencyCode} ${tx.amount.toStringAsFixed(2)}',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
