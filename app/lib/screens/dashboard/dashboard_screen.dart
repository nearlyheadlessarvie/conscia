import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conscia_app/core/constants/generated/app_constants.g.dart';
import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_summary_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/in_app_alert_banner.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_warning_banner.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/empty_state.dart';
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _bannerDismissed = false;
  final Set<String> _dismissedPrompts = {};

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(budgetListProvider.notifier).load(),
      ref.read(transactionListProvider.notifier).refresh(),
    ]);
    ref.invalidate(behavioralInsightsProvider);
    ref.invalidate(insightFeedProvider);
    ref.invalidate(dashboardInsightFeedProvider);
    ref.invalidate(dashboardInsightSummaryProvider);
  }

  Future<void> _recordReflection(Transaction tx, String feeling) async {
    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final usage = ref.read(monthlyUsageProvider);
    if (!isPremium &&
        usage.reflections >= FreemiumLimits.freeReflectionsPerMonth) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve used all ${FreemiumLimits.freeReflectionsPerMonth} free reflections this month.',
      );
      return;
    }

    final level = switch (feeling) {
      'worth_it' => 0,
      'regret' => 2,
      _ => 1,
    };

    final service = ref.read(transactionServiceProvider);
    try {
      await service.updateRegret(tx.id, level);
      ref.invalidate(transactionListProvider);
      ref.invalidate(transactionDetailProvider(tx.id));
    } catch (_) {}

    final label = switch (feeling) {
      'worth_it' => 'Marked as worth it!',
      'regret' => 'Marked as regret',
      _ => 'Reflection recorded',
    };
    final displayCounterparty =
        tx.description.isNotEmpty ? tx.description : 'Unknown';
    if (!mounted) return;
    setState(() => _dismissedPrompts.add(tx.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$displayCounterparty: $label')),
    );
  }

  void _handleAlertAction(AppAlert alert) {
    if (alert.type == 'budget_nudge') {
      BudgetFormSheet.show(
        context,
        initialCategory: alert.category,
      );
      return;
    }

    ref.read(dismissedAlertIdsProvider.notifier).dismiss(alert.id);
    if (alert.type == 'ReflectionFollowUp' && alert.transactionId != null) {
      context.push(
        AppRoutes.transactionDetail(
          alert.transactionId!,
          autoReflect: true,
        ),
      );
      return;
    }
    context.push(alert.actionRoute ?? AppRoutes.budgets);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.32,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final alerts = ref.watch(activeAlertsProvider);
                final colors = Theme.of(context).colorScheme;
                final textTheme = Theme.of(context).textTheme;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Notifications',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerts.isEmpty
                          ? 'Nothing needs your attention right now.'
                          : 'The latest nudges and reminders from Conscia.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (alerts.isEmpty)
                      const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'All clear',
                        subtitle: 'New reminders will show up here.',
                      )
                    else
                      for (final alert in alerts) ...[
                        _NotificationListTile(
                          alert: alert,
                          onAction: alert.actionLabel == null &&
                                  alert.type != 'budget_nudge'
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  _handleAlertAction(alert);
                                },
                          onDismiss: () => ref
                              .read(dismissedAlertIdsProvider.notifier)
                              .dismiss(alert.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final budgetState = ref.watch(budgetListProvider);
    final txState = ref.watch(transactionListProvider);
    final insightSummaryState = ref.watch(dashboardInsightSummaryProvider);
    final alerts = ref.watch(activeAlertsProvider);

    final budgets = budgetState.budgets;
    final transactions = txState.transactions;
    final recentTransactions = transactions.take(5).toList();
    final highlightedAlert = alerts.isNotEmpty ? alerts.first : null;
    final regretPrompts = transactions
        .where((t) =>
            t.regretLevel == null &&
            t.type != 'income' &&
            !_dismissedPrompts.contains(t.id))
        .take(3)
        .toList();

    final overBudgetCount = budgets.where((b) => b.percentage >= 0.8).length;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Text(
              'Conscia',
              style: GoogleFonts.poppins(
                textStyle: textTheme.titleLarge,
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                icon: _NotificationBell(count: alerts.length),
                onPressed: _showNotificationsSheet,
              ),
            ],
          ),
          if (overBudgetCount > 0 && !_bannerDismissed)
            SliverToBoxAdapter(
              child: BudgetWarningBanner(
                overBudgetCount: overBudgetCount,
                onDismiss: () => setState(() => _bannerDismissed = true),
              ),
            ),
          if (highlightedAlert != null)
            SliverToBoxAdapter(
              child: InAppAlertBanner(
                title: highlightedAlert.title,
                message: highlightedAlert.message,
                actionLabel: highlightedAlert.actionLabel ??
                    (highlightedAlert.type == 'budget_nudge'
                        ? 'Add budget'
                        : null),
                onAction: (highlightedAlert.actionRoute == null &&
                        highlightedAlert.type != 'budget_nudge')
                    ? null
                    : () => _handleAlertAction(highlightedAlert),
                onDismiss: () => ref
                    .read(dismissedAlertIdsProvider.notifier)
                    .dismiss(highlightedAlert.id),
              ),
            ),
          ...insightSummaryState.when<List<Widget>>(
            loading: () => [
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'Your Insights'),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: DashboardInsightSummarySkeletonCard(),
                ),
              ),
            ],
            data: (summary) {
              if (summary == null) return <Widget>[];
              return [
                SliverToBoxAdapter(
                  child: _buildSectionHeader(context, 'Your Insights'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _DashboardInsightSummaryCard(
                      summary: summary,
                      onTap: () => context.push(AppRoutes.insights),
                    ),
                  ),
                ),
              ];
            },
            error: (_, __) => <Widget>[],
          ),
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Budgets'),
          ),
          if (budgetState.isLoading && budgets.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const BudgetSummarySkeletonCard(),
                ),
              ),
            )
          else if (budgets.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No budgets yet',
                subtitle: 'Set up budgets to track your spending limits.',
                actionLabel: 'Add Budget',
                onAction: () => context.push(AppRoutes.budgets),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final b = budgets[index];
                    return BudgetSummaryCard(
                      categoryBadge: TransactionTile.badgeFor(
                        b.category,
                        size: 16,
                        filled: false,
                      ),
                      categoryName: b.category,
                      spent: b.spent,
                      limit: b.monthlyLimit,
                      currencyCode: b.currencyCode,
                    );
                  },
                ),
              ),
            ),
          if (regretPrompts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Reflect'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: regretPrompts.length,
                itemBuilder: (context, index) {
                  final tx = regretPrompts[index];
                  final displayCounterparty =
                      tx.description.isNotEmpty ? tx.description : 'Unknown';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RegretPromptCard(
                      categoryBadge: TransactionTile.badgeFor(
                        tx.category,
                        size: 16,
                        filled: false,
                      ),
                      counterparty: displayCounterparty,
                      amount: tx.amount,
                      currencyCode: tx.currencyCode,
                      date: tx.date,
                      onWorthIt: () => _recordReflection(tx, 'worth_it'),
                      onNotSure: () => _recordReflection(tx, 'not_sure'),
                      onRegret: () => _recordReflection(tx, 'regret'),
                      onDismiss: () =>
                          setState(() => _dismissedPrompts.add(tx.id)),
                    ),
                  );
                },
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Recent Transactions'),
          ),
          if (txState.isLoading && transactions.isEmpty)
            SliverList.builder(
              itemCount: 5,
              itemBuilder: (_, __) => const SkeletonListTile(),
            )
          else if (transactions.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                subtitle: 'Add your first transaction to get started.',
                actionLabel: 'Add Transaction',
                onAction: () => context.push(AppRoutes.addTransaction),
              ),
            )
          else
            SliverList.builder(
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                final t = recentTransactions[index];
                final displayCounterparty =
                    t.description.isNotEmpty ? t.description : 'Unknown';
                return RecentTransactionTile(
                  id: t.id,
                  categoryBadge: TransactionTile.badgeFor(
                    t.category,
                    size: 16,
                    filled: false,
                  ),
                  counterparty: displayCounterparty,
                  category: t.category,
                  date: t.date,
                  amount: t.amount,
                  isIncome: t.type == 'income',
                  currencyCode: t.currencyCode,
                  regretLevel: t.regretLevel,
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: colors.surface, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onError,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardInsightSummaryCard extends StatelessWidget {
  const _DashboardInsightSummaryCard({
    required this.summary,
    required this.onTap,
  });

  final DashboardInsightSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(colors, summary.tone);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: toneColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Summary',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SummaryMascot(tone: summary.tone),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(ColorScheme colors, InsightFeedTone tone) {
    switch (tone) {
      case InsightFeedTone.positive:
        return colors.primary;
      case InsightFeedTone.caution:
        return colors.tertiary;
      case InsightFeedTone.urgent:
        return colors.error;
      case InsightFeedTone.neutral:
        return colors.secondary;
    }
  }
}

class _SummaryMascot extends StatelessWidget {
  const _SummaryMascot({
    required this.tone,
  });

  final InsightFeedTone tone;

  @override
  Widget build(BuildContext context) {
    final (atlas, frameName) = switch (tone) {
      InsightFeedTone.positive => (angelMascotAtlas, '4_win.png'),
      InsightFeedTone.caution => (devilMascotAtlas, '9_coin.png'),
      InsightFeedTone.urgent => (devilMascotAtlas, '14_frustrated.png'),
      InsightFeedTone.neutral => (angelMascotAtlas, '1_neutral.png'),
    };

    return MascotSpriteFrame(
      atlas: atlas,
      frameName: frameName,
      width: 64,
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({
    required this.alert,
    required this.onDismiss,
    this.onAction,
  });

  final AppAlert alert;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actionLabel = alert.actionLabel ??
        (alert.type == 'budget_nudge' ? 'Add budget' : null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(alert.type),
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss notification',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'budget_nudge':
        return Icons.account_balance_wallet_rounded;
      case 'ReflectionFollowUp':
        return Icons.psychology_alt_rounded;
      case 'recurring_transaction_created':
        return Icons.repeat_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
