import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insight_feed_item.dart';
import '../../models/insights_models.dart';
import '../../providers/budget_providers.dart';
import '../../providers/insight_feed_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../budgets/widgets/budget_form_sheet.dart';
import '../dashboard/widgets/insight_feed_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import 'widgets/category_trend_card.dart';
import 'widgets/insights_formatting.dart';
import 'widgets/merchant_spotlight_card.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((nextOffset - _scrollOffset).abs() < 1) return;
    setState(() => _scrollOffset = nextOffset);
  }

  Future<void> _onRefresh() async {
    ref.invalidate(insightFeedBySectionProvider);
    ref.invalidate(insightsSummaryProvider);
    ref.invalidate(insightsMerchantsProvider);
    ref.invalidate(insightsCategoriesProvider);

    await Future.wait([
      ref.read(insightFeedBySectionProvider.future),
      ref.read(insightsSummaryProvider.future),
      ref.read(insightsMerchantsProvider.future),
      ref.read(insightsCategoriesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    final merchantsAsync = ref.watch(insightsMerchantsProvider);
    final categoriesAsync = ref.watch(insightsCategoriesProvider);
    final feedSectionsAsync = ref.watch(insightFeedBySectionProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final colors = Theme.of(context).appColors;
    final stickyProgress = ((_scrollOffset - 5) / 10).clamp(0.0, 1.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageTop, colors.pageBottom],
          ),
        ),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: feedSectionsAsync.when(
                loading: () => CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CenteredState(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                error: (_, __) => CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: const [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 96, 20, 28),
                      sliver: SliverToBoxAdapter(
                        child: _InsightMessageCard(
                          icon: Icons.auto_graph_rounded,
                          title: 'Insights are taking a minute',
                          body: 'We could not load your patterns just now.',
                        ),
                      ),
                    ),
                  ],
                ),
                data: (sections) => _buildInsightScroll(
                  sections: sections,
                  summary: summaryAsync.valueOrNull,
                  merchantsAsync: merchantsAsync,
                  categoriesAsync: categoriesAsync,
                  currencyCode: prefs.currency,
                  locale: prefs.locale,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _InsightsStickyHeader(
                progress: stickyProgress,
                topPadding: MediaQuery.paddingOf(context).top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightScroll({
    required Map<InsightFeedSection, List<InsightFeedItem>> sections,
    required InsightsSummary? summary,
    required AsyncValue<List<MerchantStat>> merchantsAsync,
    required AsyncValue<List<CategoryStat>> categoriesAsync,
    required String currencyCode,
    required String? locale,
  }) {
    final hasAnyInsight =
        sections.values.any((items) => items.isNotEmpty) || summary != null;

    if (!hasAnyInsight) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 96, 20, 28),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.auto_graph_rounded,
                title: 'No insights yet',
                subtitle:
                    'Keep tracking for a week and Conscia will surface your spending patterns.',
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (summary != null)
          SliverToBoxAdapter(
            child: _InsightEditorialHighlight(
              summary: summary,
              currencyCode: currencyCode,
              locale: locale,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, summary == null ? 96 : 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null) ...[
                  _SummaryCard(
                    summary: summary,
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                  const SizedBox(height: 26),
                ],
                _InsightFeedSection(
                  title: 'Regret patterns',
                  subtitle:
                      'The repeat signals worth noticing before the next purchase.',
                  items:
                      sections[InsightFeedSection.regretPatterns] ?? const [],
                ),
                _MerchantSpotlightSection(merchantsAsync: merchantsAsync),
                _CategoryTrendSection(
                  categoriesAsync: categoriesAsync,
                  currencyCode: currencyCode,
                  locale: locale,
                ),
                _InsightFeedSection(
                  title: 'This week',
                  subtitle:
                      'The freshest read on how your money decisions feel.',
                  items: sections[InsightFeedSection.thisWeek] ?? const [],
                ),
                _InsightFeedSection(
                  title: 'Budget trends',
                  subtitle:
                      'Where spending is pacing high or ready for a budget.',
                  items: sections[InsightFeedSection.budgetTrends] ?? const [],
                ),
                _InsightFeedSection(
                  title: 'Recent signals',
                  subtitle: 'Small changes that may deserve a pause.',
                  items: sections[InsightFeedSection.recentSignals] ?? const [],
                ),
                const SizedBox(height: 112),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightFeedSection extends StatelessWidget {
  const _InsightFeedSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<InsightFeedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, _) {
        final budgetCategories = ref
            .watch(budgetListProvider)
            .budgets
            .map((budget) => budget.category.trim().toLowerCase())
            .toSet();
        final currentItems = [
          for (final item in items)
            if (_currentBudgetAction(item, budgetCategories)
                case final currentItem?)
              currentItem,
        ];

        if (currentItems.isEmpty) return const SizedBox.shrink();

        return ScreenSection(
          title: title,
          subtitle: subtitle,
          child: FeedCard(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
            child: Column(
              children: [
                for (var index = 0; index < currentItems.length; index++) ...[
                  InsightFeedCard(
                    item: currentItems[index],
                    groupedRow: true,
                    enableNavigation: currentItems[index].route != '/insights',
                    onTap: currentItems[index].budgetCategory == null
                        ? null
                        : () => BudgetFormSheet.show(
                              context,
                              initialCategory:
                                  currentItems[index].budgetCategory,
                            ),
                  ),
                  if (index < currentItems.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).appColors.border,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  InsightFeedItem? _currentBudgetAction(
    InsightFeedItem item,
    Set<String> budgetCategories,
  ) {
    final budgetCategory = item.budgetCategory;
    if (budgetCategory == null) return item;

    final hasCurrentBudget = budgetCategories.contains(
      budgetCategory.trim().toLowerCase(),
    );
    if (!hasCurrentBudget) return item;

    return null;
  }
}

class _InsightsStickyHeader extends StatelessWidget {
  const _InsightsStickyHeader({
    required this.progress,
    required this.topPadding,
  });

  final double progress;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final opacity = Curves.easeOut.transform(progress);
    final canPop = Navigator.of(context).canPop();
    final background = Color.lerp(
      Colors.transparent,
      colors.paper.withValues(alpha: 0.9),
      opacity,
    )!;
    final borderColor = Color.lerp(
      Colors.transparent,
      colors.border.withValues(alpha: 0.9),
      opacity,
    )!;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 0),
      child: AnimatedContainer(
        key: const ValueKey('insights-sticky-header'),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: opacity > 0.02
              ? [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.05 * opacity),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: canPop
                  ? IconButton(
                      tooltip: 'Back',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: colors.deepNavy,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Insights',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40, height: 40),
          ],
        ),
      ),
    );
  }
}

class _MerchantSpotlightSection extends StatelessWidget {
  const _MerchantSpotlightSection({required this.merchantsAsync});

  final AsyncValue<List<MerchantStat>> merchantsAsync;

  @override
  Widget build(BuildContext context) {
    return merchantsAsync.when(
      loading: () => const ScreenSection(
        title: 'Merchant spotlight',
        subtitle:
            'The place most likely to nudge you into a purchase you later rethink.',
        child: _InlineLoader(),
      ),
      error: (_, __) => const ScreenSection(
        title: 'Merchant spotlight',
        subtitle:
            'The place most likely to nudge you into a purchase you later rethink.',
        child: _SectionFallbackCard(
          message: 'Merchant trends are unavailable right now.',
        ),
      ),
      data: (merchants) {
        if (merchants.isEmpty) return const SizedBox.shrink();

        return ScreenSection(
          title: 'Merchant spotlight',
          subtitle:
              'The place most likely to nudge you into a purchase you later rethink.',
          child: MerchantSpotlightCard(merchant: merchants.first),
        );
      },
    );
  }
}

class _InsightEditorialHighlight extends StatelessWidget {
  const _InsightEditorialHighlight({
    required this.summary,
    required this.currencyCode,
    required this.locale,
  });

  final InsightsSummary summary;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final regretText = formatInsightCurrency(
      summary.regrettedAmount,
      currencyCode: currencyCode,
      locale: locale,
    );

    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      key: const ValueKey('insights-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 70, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft,
            colors.amberSoft,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(children: [
            Text(
              'REGRET SIGNAL',
              style: textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${(summary.avgRegretRate * 100).toStringAsFixed(0)}% regret rate',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            regretText,
            style: textTheme.displaySmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.regrettedCategory} is carrying your strongest regret signal right now.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InsightHeroMetricPill(
                  icon: Icons.category_rounded,
                  label: summary.regrettedCategory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightHeroMetricPill(
                  icon: Icons.auto_graph_rounded,
                  label: '${summary.patternCount} patterns',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InsightHeroQuickLink(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  onTap: () => context.push('/insights/categories'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightHeroQuickLink(
                  icon: Icons.storefront_rounded,
                  label: 'Merchants',
                  onTap: () => context.push('/insights/merchants'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightHeroMetricPill extends StatelessWidget {
  const _InsightHeroMetricPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: colors.deepNavy),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightHeroQuickLink extends StatelessWidget {
  const _InsightHeroQuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceRaised.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: colors.deepNavy),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTrendSection extends StatelessWidget {
  const _CategoryTrendSection({
    required this.categoriesAsync,
    required this.currencyCode,
    required this.locale,
  });

  final AsyncValue<List<CategoryStat>> categoriesAsync;
  final String currencyCode;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      loading: () => const ScreenSection(
        title: 'Category trend',
        subtitle: 'Where your regret spend is stacking up fastest right now.',
        child: _InlineLoader(),
      ),
      error: (_, __) => const ScreenSection(
        title: 'Category trend',
        subtitle: 'Where your regret spend is stacking up fastest right now.',
        child: _SectionFallbackCard(
          message: 'Category trends are unavailable right now.',
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return ScreenSection(
          title: 'Category trend',
          subtitle: 'Where your regret spend is stacking up fastest right now.',
          child: CategoryTrendCard(
            category: categories.first,
            currencyCode: currencyCode,
            locale: locale,
          ),
        );
      },
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
            'YOUR REGRET PULSE',
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).appColors.mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
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
