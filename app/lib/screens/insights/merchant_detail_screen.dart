import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import 'widgets/insight_detail_back_button.dart';
import 'widgets/insight_transaction_card.dart';
import 'widgets/insights_formatting.dart';

class MerchantDetailScreen extends ConsumerWidget {
  const MerchantDetailScreen({super.key, required this.merchant});

  final String merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(merchantDetailProvider(merchant));
    final prefs = ref.watch(userPreferencesProvider);

    return HeroScreenScaffold(
      appBar: AppBar(
        leading: const InsightDetailBackButton(),
        title: Text(merchant),
      ),
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _StateCard(
          title: 'Could not load merchant details',
          body: 'Try this merchant again in a moment.',
        ),
        data: (detail) {
          if (detail == null) {
            return const _StateCard(
              title: 'No merchant details yet',
              body:
                  'Once enough purchases cluster around this merchant, the story will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MerchantSummaryCard(
                stats: detail.stats,
                locale: prefs.locale,
              ),
              const SizedBox(height: 26),
              ScreenSection(
                title: 'Recent transactions',
                subtitle:
                    'The purchases currently shaping this merchant pattern.',
                child: detail.recentTransactions.isEmpty
                    ? const _StateCard(
                        title: 'No recent transactions',
                        body:
                            'There are not any recent purchases to show for this merchant yet.',
                      )
                    : Column(
                        children: [
                          for (final tx in detail.recentTransactions) ...[
                            InsightTransactionCard(
                              tx: tx,
                              locale: prefs.locale,
                              title: tx.merchant ?? merchant,
                              subtitle:
                                  '${tx.category} • ${formatInsightDate(tx.date, locale: prefs.locale)}',
                              leading:
                                  _MerchantLeadingBadge(category: tx.category),
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

class _MerchantSummaryCard extends StatelessWidget {
  const _MerchantSummaryCard({
    required this.stats,
    required this.locale,
  });

  final MerchantStat stats;
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.merchant,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last visit ${formatInsightLastVisit(stats.lastVisitDate, locale: locale)}',
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
                  label: 'Visits',
                  value: '${stats.visitCount}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Regrets',
                  value: '${stats.regretCount}',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.regretRate,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              color: rateColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantLeadingBadge extends StatelessWidget {
  const _MerchantLeadingBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.receipt_long_rounded,
        color: colors.onSecondaryContainer,
        size: 18,
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
