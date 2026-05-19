import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/category_icons.dart';
import '../../core/theme/app_layout.dart';
import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import 'widgets/insight_drilldown_scaffold.dart';
import 'widgets/insights_formatting.dart';
import 'widgets/insight_list_editorial_hero.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(insightsCategoriesProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return InsightDrilldownScaffold(
      title: 'Categories',
      child: categoriesAsync.when(
        loading: () => const _StatePadding(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const _MessageCard(
          title: 'Categories are unavailable',
          body: 'We could not load category insights right now.',
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const _MessageCard(
              title: 'No category patterns yet',
              body:
                  'Once you track a few more purchases, your most regret-prone categories will show up here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryEditorialHero(
                category: categories.first,
                currencyCode: prefs.currency,
                locale: prefs.locale,
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScreenSection(
                  title: 'Top regret categories',
                  subtitle:
                      'Ordered by how much spend you ended up second-guessing.',
                  child: Column(
                    children: [
                      for (final category in categories) ...[
                        _CategoryCard(
                          category: category,
                          currencyCode: prefs.currency,
                          locale: prefs.locale,
                        ),
                        const SizedBox(height: 12),
                      ],
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

class _CategoryEditorialHero extends StatelessWidget {
  const _CategoryEditorialHero({
    required this.category,
    required this.currencyCode,
    required this.locale,
  });

  final CategoryStat category;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final regrettedText = formatInsightCurrency(
      category.regrettedSpend,
      currencyCode: currencyCode,
      locale: locale,
    );
    final rateText =
        '${(category.regretRate * 100).toStringAsFixed(0)}% regret';

    return InsightListEditorialHero(
      bleed: true,
      topPadding: AppLayout.drilldownHeroTop(context),
      leading: CategoryIcons.badge(
        category.category,
        size: 30,
        type: 'Expense',
      ),
      label: 'TOP REGRET CATEGORY',
      primary: regrettedText,
      body:
          '${category.category} is your strongest repeat regret signal right now.',
      chips: [
        'Top: ${category.category}',
        '${category.transactionCount} purchases',
        rateText,
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.currencyCode,
    required this.locale,
  });

  final CategoryStat category;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rateText =
        '${(category.regretRate * 100).toStringAsFixed(0)}% regret';
    final regretText = formatInsightCurrency(
      category.regrettedSpend,
      currencyCode: currencyCode,
      locale: locale,
    );
    final annualText = formatInsightCompactCurrency(
      category.projectedAnnual,
      currencyCode: currencyCode,
      locale: locale,
    );
    final rateColor = insightRateColor(context, category.regretRate);

    return FeedCard(
      onTap: () => context.push(
        '/insights/categories/${Uri.encodeComponent(category.category)}',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcons.badge(
            category.category,
            size: 20,
            type: 'Expense',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.category,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$regretText regretted across ${category.transactionCount} purchases',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: rateText, tint: rateColor),
                    _Pill(
                      label: '$annualText yearly projection',
                      tint: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
        ),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

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
