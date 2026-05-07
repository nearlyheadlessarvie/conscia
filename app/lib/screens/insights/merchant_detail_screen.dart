import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class MerchantDetailScreen extends ConsumerWidget {
  final String merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(merchantDetailProvider(merchant));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(merchant)),
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
              _StatsHeader(stats: detail.stats),
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

class _StatsHeader extends StatelessWidget {
  final MerchantStat stats;

  const _StatsHeader({required this.stats});

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(children: [
              Text('${stats.visitCount}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('visits', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
            Column(children: [
              Text('${stats.regretCount}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: rateColor)),
              Text('regrets', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
            Column(children: [
              Text('$rate%', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: rateColor)),
              Text('rate', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ]),
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
            child: Text(tx.category,
                style: textTheme.bodyMedium),
          ),
          Text('${tx.currencyCode} ${tx.amount.toStringAsFixed(2)}',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
