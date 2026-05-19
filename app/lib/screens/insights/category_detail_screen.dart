import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/category_icons.dart';
import '../../core/theme/app_layout.dart';
import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../dashboard/widgets/recent_transaction_tile.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import '../transactions/widgets/editorial_transaction_row.dart';
import 'widgets/insight_drilldown_scaffold.dart';
import 'widgets/insight_list_editorial_hero.dart';
import 'widgets/insights_formatting.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(categoryDetailProvider(category));
    final prefs = ref.watch(userPreferencesProvider);

    return InsightDrilldownScaffold(
      title: category,
      child: detailAsync.when(
        loading: () => const _StatePadding(
          child: Center(child: CircularProgressIndicator()),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScreenSection(
                  title: 'Latest matches',
                  subtitle: 'Last 30 days of purchases matching this category.',
                  child: detail.recentTransactions.isEmpty
                      ? const _StateCard(
                          title: 'No recent transactions',
                          body:
                              'There are not any recent purchases to show for this category yet.',
                        )
                      : EditorialTransactionRowsGroup(
                          horizontalPadding: 0,
                          children: [
                            for (final tx in detail.recentTransactions)
                              RecentTransactionTile(
                                id: tx.id,
                                categoryBadge: CategoryIcons.badge(
                                  tx.category,
                                  size: 30,
                                  type: 'Expense',
                                ),
                                counterparty: tx.merchant ?? tx.category,
                                category: tx.category,
                                date: tx.date,
                                amount: tx.amount,
                                isIncome: false,
                                currencyCode: tx.currencyCode,
                                regretLevel:
                                    insightRegretLevelValue(tx.regretLevel),
                                locale: prefs.locale,
                              ),
                          ],
                        ),
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
    final regrettedText = formatInsightCurrency(
      stats.regrettedSpend,
      currencyCode: currencyCode,
      locale: locale,
    );
    final spentText = formatInsightCurrency(
      stats.totalSpend,
      currencyCode: currencyCode,
      locale: locale,
    );
    final projectedText = formatInsightCompactCurrency(
      stats.projectedAnnual,
      currencyCode: currencyCode,
      locale: locale,
    );
    final rateText = '${(stats.regretRate * 100).toStringAsFixed(0)}% rate';

    return InsightListEditorialHero(
      bleed: true,
      topPadding: AppLayout.drilldownHeroTop(context),
      leading: CategoryIcons.badge(
        stats.category,
        size: 30,
        type: 'Expense',
      ),
      label: 'TOP REGRET CATEGORY',
      primary: regrettedText,
      body:
          '${stats.category} has ${stats.transactionCount} tracked purchases driving this regret signal.',
      chips: [
        '$spentText spent',
        rateText,
        '$projectedText yearly projection',
      ],
    );
  }
}

class _StatePadding extends StatelessWidget {
  const _StatePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        AppLayout.drilldownHeroTop(context),
        16,
        28,
      ),
      child: child,
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

    return _StatePadding(
      child: FeedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
      ),
    );
  }
}
