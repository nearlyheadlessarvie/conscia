import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/insights_provider.dart';
import 'widgets/category_trend_card.dart';
import 'widgets/merchant_spotlight_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    final merchantsAsync = ref.watch(insightsMerchantsProvider);
    final categoriesAsync = ref.watch(insightsCategoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Regret Patterns')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load insights.')),
        data: (summary) {
          if (summary == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Check back after your first week of tracking.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats header
              Row(
                children: [
                  _StatCell(label: 'Regretted', value: '£${summary.regrettedAmount.toStringAsFixed(0)}'),
                  _StatCell(label: 'Avg rate', value: '${(summary.avgRegretRate * 100).toStringAsFixed(0)}%'),
                  _StatCell(label: 'Patterns', value: '${summary.patternCount}'),
                ],
              ),
              const SizedBox(height: 16),

              // Merchant spotlight
              merchantsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (merchants) {
                  if (merchants.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      MerchantSpotlightCard(merchant: merchants.first),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              // Category trend
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return CategoryTrendCard(category: categories.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
