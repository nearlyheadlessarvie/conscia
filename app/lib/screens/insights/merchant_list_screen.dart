import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import 'widgets/insight_drilldown_scaffold.dart';
import 'widgets/insights_formatting.dart';
import 'widgets/insight_list_editorial_hero.dart';

class MerchantListScreen extends ConsumerWidget {
  const MerchantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(insightsMerchantsProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return InsightDrilldownScaffold(
      title: 'Merchants',
      child: merchantsAsync.when(
        loading: () => const _StatePadding(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const _MessageCard(
          title: 'Merchants are unavailable',
          body: 'We could not load merchant insights right now.',
        ),
        data: (merchants) {
          if (merchants.isEmpty) {
            return const _MessageCard(
              title: 'No merchant patterns yet',
              body:
                  'Track a few more purchases and the merchants that trigger the most regret will surface here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MerchantEditorialHero(
                merchant: merchants.first,
                locale: prefs.locale,
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScreenSection(
                  title: 'Merchants to watch',
                  subtitle:
                      'The places with the highest share of purchases you later regretted.',
                  child: Column(
                    children: [
                      for (final merchant in merchants) ...[
                        _MerchantCard(
                          merchant: merchant,
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

class _MerchantEditorialHero extends StatelessWidget {
  const _MerchantEditorialHero({
    required this.merchant,
    required this.locale,
  });

  final MerchantStat merchant;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final regretLabel =
        '${merchant.regretCount} regret${merchant.regretCount == 1 ? '' : 's'}';

    return InsightListEditorialHero(
      bleed: true,
      topPadding: AppLayout.drilldownHeroTop(context),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).appColors.navySoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.storefront_rounded,
          color: Theme.of(context).appColors.deepNavy,
        ),
      ),
      label: 'MERCHANT SIGNAL',
      primary: merchant.merchant,
      body:
          '${merchant.merchant} is carrying your strongest merchant regret signal.',
      chips: [
        'Top: ${merchant.merchant}',
        regretLabel,
        'Last visit ${formatInsightLastVisit(
          merchant.lastVisitDate,
          locale: locale,
        )}',
      ],
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.merchant,
    required this.locale,
  });

  final MerchantStat merchant;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rateColor = insightRateColor(context, merchant.regretRate);
    final rateText =
        '${(merchant.regretRate * 100).toStringAsFixed(0)}% regret';

    return FeedCard(
      onTap: () => context.push(
        '/insights/merchants/${Uri.encodeComponent(merchant.merchant)}',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
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
                  merchant.merchant,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${merchant.regretCount} regrets across ${merchant.visitCount} visits',
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
                      label:
                          'Last visit ${formatInsightLastVisit(merchant.lastVisitDate, locale: locale)}',
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
