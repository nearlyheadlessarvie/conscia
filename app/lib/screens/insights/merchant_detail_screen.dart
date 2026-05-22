import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../dashboard/widgets/recent_transaction_tile.dart';
import '../transactions/widgets/editorial_transaction_row.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import 'widgets/insight_drilldown_scaffold.dart';
import 'widgets/insight_list_editorial_hero.dart';
import 'widgets/insights_formatting.dart';

class MerchantDetailScreen extends ConsumerWidget {
  const MerchantDetailScreen({super.key, required this.merchant});

  final String merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(merchantDetailProvider(merchant));
    final prefs = ref.watch(userPreferencesProvider);

    return InsightDrilldownScaffold(
      title: merchant,
      child: detailAsync.when(
        loading: () => const _StatePadding(
          child: Center(child: CircularProgressIndicator()),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScreenSection(
                  title: 'Latest matches',
                  subtitle: 'Last 30 days of purchases matching this merchant.',
                  child: detail.recentTransactions.isEmpty
                      ? const _StateCard(
                          title: 'No recent transactions',
                          body:
                              'There are not any recent purchases to show for this merchant yet.',
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
                                counterparty: tx.merchant ?? merchant,
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

class _MerchantSummaryCard extends StatelessWidget {
  const _MerchantSummaryCard({
    required this.stats,
    required this.locale,
  });

  final MerchantStat stats;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final visitLabel =
        '${stats.visitCount} visit${stats.visitCount == 1 ? '' : 's'}';
    final regretLabel =
        '${stats.regretCount} regret${stats.regretCount == 1 ? '' : 's'}';
    final rateLabel = '${(stats.regretRate * 100).toStringAsFixed(0)}% rate';
    final lastVisit =
        formatInsightLastVisit(stats.lastVisitDate, locale: locale);

    return InsightListEditorialHero(
      bleed: true,
      topPadding: AppLayout.drilldownHeroTop(context),
      leading: const _MerchantHeroBadge(),
      label: 'MERCHANT SIGNAL',
      primary: stats.merchant,
      body: 'Last visit $lastVisit · $regretLabel across $visitLabel.',
      chips: [
        visitLabel,
        regretLabel,
        rateLabel,
      ],
    );
  }
}

class _MerchantHeroBadge extends StatelessWidget {
  const _MerchantHeroBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.navySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppIcons.icon(
        AppIconKey.merchant,
        color: colors.deepNavy,
        size: 20,
      ),
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
