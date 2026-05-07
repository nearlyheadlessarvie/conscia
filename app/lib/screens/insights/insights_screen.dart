import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import 'widgets/category_trend_card.dart';
import 'widgets/insights_formatting.dart';
import 'widgets/merchant_spotlight_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    final merchantsAsync = ref.watch(insightsMerchantsProvider);
    final categoriesAsync = ref.watch(insightsCategoriesProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Regret Patterns')),
      child: summaryAsync.when(
        loading: () => const _CenteredState(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const _InsightMessageCard(
          icon: Icons.auto_graph_rounded,
          title: 'Insights are taking a minute',
          body: 'We could not load your regret patterns just now.',
        ),
        data: (summary) {
          if (summary == null) {
            return const _InsightMessageCard(
              icon: Icons.timeline_rounded,
              title: 'Patterns show up after a little history',
              body:
                  'Check back after your first week of tracking and Conscia will start surfacing your regret trends.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(
                summary: summary,
                currencyCode: prefs.currency,
                locale: prefs.locale,
              ),
              const SizedBox(height: 26),
              ScreenSection(
                title: 'Merchant spotlight',
                subtitle:
                    'The place most likely to nudge you into a purchase you later rethink.',
                child: merchantsAsync.when(
                  loading: () => const _InlineLoader(),
                  error: (_, __) => const _SectionFallbackCard(
                    message: 'Merchant trends are unavailable right now.',
                  ),
                  data: (merchants) {
                    if (merchants.isEmpty) {
                      return const _SectionFallbackCard(
                        message:
                            'Track a few more merchants and this spotlight will fill in automatically.',
                      );
                    }

                    return MerchantSpotlightCard(merchant: merchants.first);
                  },
                ),
              ),
              ScreenSection(
                title: 'Category trend',
                subtitle:
                    'Where your regret spend is stacking up fastest right now.',
                child: categoriesAsync.when(
                  loading: () => const _InlineLoader(),
                  error: (_, __) => const _SectionFallbackCard(
                    message: 'Category trends are unavailable right now.',
                  ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const _SectionFallbackCard(
                        message:
                            'Track a few more purchases and category trends will start to emerge here.',
                      );
                    }

                    return CategoryTrendCard(
                      category: categories.first,
                      currencyCode: prefs.currency,
                      locale: prefs.locale,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.currencyCode,
    required this.locale,
  });

  final dynamic summary;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final regretText = formatInsightCurrency(
      summary.regrettedAmount,
      currencyCode: currencyCode,
      locale: locale,
    );

    return FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your regret pulse',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$regretText tied to ${summary.regrettedCategory} lately.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${formatInsightDate(summary.updatedAt, locale: locale, pattern: 'MMM d, y')}',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Regretted',
                  value: regretText,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: 'Avg rate',
                  value: '${(summary.avgRegretRate * 100).toStringAsFixed(0)}%',
                  emphasize: insightRateColor(context, summary.avgRegretRate),
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: 'Patterns',
                  value: '${summary.patternCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.emphasize,
  });

  final String label;
  final String value;
  final Color? emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

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

class _InsightMessageCard extends StatelessWidget {
  const _InsightMessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
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
          Icon(icon, size: 28, color: colors.primary),
          const SizedBox(height: 14),
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

class _SectionFallbackCard extends StatelessWidget {
  const _SectionFallbackCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const FeedCard(
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Center(child: child),
    );
  }
}
