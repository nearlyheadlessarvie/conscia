import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/category_icons.dart';
import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import 'widgets/insight_transaction_card.dart';
import 'widgets/insights_formatting.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(categoryDetailProvider(category));
    final prefs = ref.watch(userPreferencesProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: Text(category)),
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _StateCard(
          title: 'Could not load category details',
          body: 'Try this category again in a moment.',
        ),
        data: (detail) {
          if (detail == null) {
            return const _StateCard(
              title: 'No category details yet',
              body:
                  'Once enough purchases land in this category, the transaction story will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategorySummaryCard(
                stats: detail.stats,
                currencyCode: prefs.currency,
                locale: prefs.locale,
              ),
              const SizedBox(height: 26),
              ScreenSection(
                title: 'Recent transactions',
                subtitle:
                    'The purchases currently driving this category pattern.',
                child: detail.recentTransactions.isEmpty
                    ? const _StateCard(
                        title: 'No recent transactions',
                        body:
                            'There are not any recent purchases to show for this category yet.',
                      )
                    : Column(
                        children: [
                          for (final tx in detail.recentTransactions) ...[
                            InsightTransactionCard(
                              tx: tx,
                              locale: prefs.locale,
                              subtitle:
                                  '${tx.merchant ?? tx.category} • ${formatInsightDate(tx.date, locale: prefs.locale)}',
                              leading: CategoryIcons.badge(tx.category, size: 18),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  const _CategorySummaryCard({
    required this.stats,
    required this.currencyCode,
    required this.locale,
  });

  final CategoryStat stats;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rateColor = insightRateColor(context, stats.regretRate);

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcons.badge(stats.category, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.category,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.transactionCount} tracked purchases in this category',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Spent',
                  value: formatInsightCurrency(
                    stats.totalSpend,
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Regretted',
                  value: formatInsightCurrency(
                    stats.regrettedSpend,
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                  emphasize: rateColor,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Rate',
                  value: '${(stats.regretRate * 100).toStringAsFixed(0)}%',
                  emphasize: rateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.timeline_rounded, color: rateColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${formatInsightCompactCurrency(stats.projectedAnnual, currencyCode: currencyCode, locale: locale)} projected in yearly regret spend if this pace holds.',
                      style: textTheme.bodySmall?.copyWith(
                        color: rateColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasize,
  });

  final String label;
  final String value;
  final Color? emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
