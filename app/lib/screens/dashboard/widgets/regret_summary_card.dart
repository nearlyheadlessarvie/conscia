import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';
import '../../../providers/insights_provider.dart';
import '../../../providers/user_provider.dart';
import '../../insights/widgets/insights_formatting.dart';

class RegretSummaryCard extends ConsumerWidget {
  const RegretSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return _buildCard(
          context,
          summary,
          currencyCode: prefs.currency,
          locale: prefs.locale,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    InsightsSummary summary, {
    required String currencyCode,
    required String? locale,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretText = formatInsightCurrency(
      summary.regrettedAmount,
      currencyCode: currencyCode,
      locale: locale,
    );

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: colors.onErrorContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$regretText regretted on ${summary.regrettedCategory}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'last 30 days · tap to see patterns',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
