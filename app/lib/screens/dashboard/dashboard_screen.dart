import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show lerpDouble;

import 'package:conscia_app/core/constants/generated/app_constants.g.dart';
import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/core/theme/app_colors.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/empty_state.dart';
import 'package:conscia_app/widgets/grouped_list_card.dart';
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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
    ref.invalidate(conscienceJourneyProvider);
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

  void _showNotificationsSheet(List<AppAlert> initialAlerts) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        var sheetAlerts = initialAlerts;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.32,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
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
                      sheetAlerts.isEmpty
                          ? 'Nothing needs your attention right now.'
                          : 'The latest nudges and reminders from Conscia.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (sheetAlerts.isEmpty)
                      const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'All clear',
                        subtitle: 'New reminders will show up here.',
                      )
                    else
                      for (final alert in sheetAlerts) ...[
                        _NotificationListTile(
                          alert: alert,
                          onAction: alert.actionLabel == null &&
                                  alert.type != 'budget_nudge'
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  _handleAlertAction(alert);
                                },
                          onDismiss: () {
                            ref
                                .read(dismissedAlertIdsProvider.notifier)
                                .dismiss(alert.id);
                            setSheetState(() {
                              sheetAlerts = sheetAlerts
                                  .where((item) => item.id != alert.id)
                                  .toList(growable: false);
                            });
                          },
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
    final budgetState = ref.watch(budgetListProvider);
    final txState = ref.watch(transactionListProvider);
    final insightSummaryState = ref.watch(dashboardInsightSummaryProvider);
    final journeyState = ref.watch(conscienceJourneyProvider);
    final profile = ref.watch(currentUserProvider).valueOrNull;
    final alerts = _visibleAlerts(ref.watch(activeAlertsProvider), budgetState.budgets);

    final budgets = budgetState.budgets;
    final transactions = txState.transactions;
    final recentTransactions = transactions.take(5).toList();
    final insightSummary = insightSummaryState.valueOrNull;
    final journey = journeyState.valueOrNull;
    final regretPrompts = transactions
        .where((t) =>
            t.regretLevel == null &&
            t.type != 'income' &&
            !_dismissedPrompts.contains(t.id))
        .take(3)
        .toList();
    final greetingName = _greetingName(profile);
    final monthExpenseTotal = _currentMonthExpenseTotal(transactions);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey('dashboard-shell-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DashboardEditorialHeroCard(
              profile: profile,
              greetingName: greetingName,
              alertsCount: alerts.length,
              monthExpenseTotal: monthExpenseTotal,
              journey: journey,
              summary: insightSummary,
              loading:
                  (journeyState.isLoading && journey == null) ||
                  (insightSummaryState.isLoading && insightSummary == null),
              onNotificationsTap: () => _showNotificationsSheet(alerts),
              onJourneyTap: () => context.push(AppRoutes.journey),
              onInsightsTap: () => context.push(AppRoutes.insights),
              onAddTransactionTap: () => context.push(AppRoutes.addTransaction),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _DashboardStickyHeaderDelegate(
              topPadding: MediaQuery.paddingOf(context).top,
              child: _DashboardStickyIdentityHeader(
                profile: profile,
                greetingName: greetingName,
                alertsCount: alerts.length,
                onNotificationsTap: () => _showNotificationsSheet(alerts),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Budgets'),
          ),
          if (budgetState.isLoading && budgets.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: GroupedListCard(
                  children: [
                    BudgetSummarySkeletonCard(),
                    BudgetSummarySkeletonCard(),
                    BudgetSummarySkeletonCard(),
                  ],
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: GroupedListCard(
                  children: [
                    for (final budget in budgets.take(4))
                      _BudgetSummaryRow(
                        categoryBadge: TransactionTile.badgeFor(
                          budget.category,
                          size: 18,
                          filled: false,
                        ),
                        categoryName: budget.category,
                        spent: budget.spent,
                        limit: budget.monthlyLimit,
                        currencyCode: budget.currencyCode,
                        percentage: budget.percentage,
                      ),
                  ],
                ),
              ),
            ),
          if (regretPrompts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Reflect'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: GroupedListCard(
                  children: [
                    for (final t in recentTransactions)
                      RecentTransactionTile(
                        id: t.id,
                        categoryBadge: TransactionTile.badgeFor(
                          t.category,
                          size: 16,
                          filled: false,
                        ),
                        counterparty:
                            t.description.isNotEmpty ? t.description : 'Unknown',
                        category: t.category,
                        date: t.date,
                        amount: t.amount,
                        isIncome: t.type == 'income',
                        currencyCode: t.currencyCode,
                        regretLevel: t.regretLevel,
                      ),
                  ],
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
        ],
      ),
    );
  }

  String _greetingName(UserProfile? profile) {
    final displayName = profile?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = profile?.email.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'there';
  }

  double _currentMonthExpenseTotal(List<Transaction> transactions) {
    final now = DateTime.now();
    return transactions
        .where((t) => t.type != 'income')
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  List<AppAlert> _visibleAlerts(List<AppAlert> alerts, List<Budget> budgets) {
    final budgetCategories = budgets.map((budget) => budget.category.toLowerCase()).toSet();
    return alerts.where((alert) {
      if (alert.type != 'budget_nudge') {
        return true;
      }
      final category = alert.category?.toLowerCase();
      return category == null || !budgetCategories.contains(category);
    }).toList(growable: false);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DashboardEditorialHeroCard extends StatelessWidget {
  const _DashboardEditorialHeroCard({
    required this.profile,
    required this.greetingName,
    required this.alertsCount,
    required this.monthExpenseTotal,
    required this.journey,
    required this.summary,
    required this.loading,
    required this.onNotificationsTap,
    required this.onJourneyTap,
    required this.onInsightsTap,
    required this.onAddTransactionTap,
  });

  final UserProfile? profile;
  final String greetingName;
  final int alertsCount;
  final double monthExpenseTotal;
  final ConscienceJourneySummary? journey;
  final DashboardInsightSummary? summary;
  final bool loading;
  final VoidCallback onNotificationsTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onInsightsTap;
  final VoidCallback onAddTransactionTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    if (loading) {
      return const DashboardJourneySkeletonCard();
    }

    return Container(
      key: const ValueKey('dashboard-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.amberSoft,
            colors.paper,
            colors.navySoft,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardIdentityRow(
            profile: profile,
            greetingName: greetingName,
            alertsCount: alertsCount,
            onNotificationsTap: onNotificationsTap,
          ),
          const SizedBox(height: 18),
          Text(
            'Spent this month',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            monthExpenseTotal <= 0
                ? 'PHP 0.00'
                : 'PHP ${monthExpenseTotal.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              textStyle: textTheme.displaySmall,
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary?.text ??
                (journey == null
                    ? 'Conscia will turn your next few transactions into a clearer monthly story.'
                    : '${journey!.momentumDays}-day mindful streak · ${_DashboardJourneyCard._completedQuestCount(journey!.weeklyQuests)}/${journey!.weeklyQuests.length} quests this week'),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetricPill(
                  icon: Icons.local_fire_department_rounded,
                  label: journey == null
                      ? '0-day streak'
                      : '${journey!.momentumDays}-day streak',
                  backgroundColor: colors.surfaceRaised.withValues(alpha: 0.75),
                  foregroundColor: colors.deepNavy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetricPill(
                  icon: Icons.flag_rounded,
                  label: journey == null
                      ? '0/0 quests'
                      : '${_DashboardJourneyCard._completedQuestCount(journey!.weeklyQuests)}/${journey!.weeklyQuests.length} quests',
                  backgroundColor: colors.surfaceRaised.withValues(alpha: 0.75),
                  foregroundColor: colors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DashboardQuickLink(
                  icon: Icons.flag_rounded,
                  label: 'Journey',
                  onPressed: onJourneyTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardQuickLink(
                  icon: Icons.auto_graph_rounded,
                  label: 'Insights',
                  onPressed: onInsightsTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardQuickLink(
                  icon: Icons.add_rounded,
                  label: 'Add',
                  onPressed: onAddTransactionTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickLink extends StatelessWidget {
  const _DashboardQuickLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
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

class _DashboardStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DashboardStickyHeaderDelegate({
    required this.topPadding,
    required this.child,
  });

  final double topPadding;
  final Widget child;

  @override
  double get minExtent => topPadding + 68;

  @override
  double get maxExtent => topPadding + 84;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0).toDouble();
    final colors = Theme.of(context).appColors;

    return Container(
      key: const ValueKey('dashboard-sticky-identity-header'),
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: lerpDouble(0.0, 0.94, progress)!),
        border: progress > 0.35
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DashboardStickyHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding || child != oldDelegate.child;
  }
}

class _DashboardStickyIdentityHeader extends StatelessWidget {
  const _DashboardStickyIdentityHeader({
    required this.profile,
    required this.greetingName,
    required this.alertsCount,
    required this.onNotificationsTap,
  });

  final UserProfile? profile;
  final String greetingName;
  final int alertsCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardIdentityRow(
      profile: profile,
      greetingName: greetingName,
      alertsCount: alertsCount,
      onNotificationsTap: onNotificationsTap,
      compact: true,
    );
  }
}

class _DashboardIdentityRow extends StatelessWidget {
  const _DashboardIdentityRow({
    required this.profile,
    required this.greetingName,
    required this.alertsCount,
    required this.onNotificationsTap,
    this.compact = false,
  });

  final UserProfile? profile;
  final String greetingName;
  final int alertsCount;
  final VoidCallback onNotificationsTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        _ProfileAvatar(photoUrl: profile?.photoUrl, compact: compact),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greetingName,
                style: GoogleFonts.poppins(
                  textStyle:
                      compact ? textTheme.titleMedium : textTheme.headlineSmall,
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: colors.surfaceRaised.withValues(alpha: compact ? 0.72 : 0.92),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: onNotificationsTap,
            icon: _NotificationBell(count: alertsCount),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.compact,
  });

  final String? photoUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final radius = compact ? 20.0 : 24.0;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.surfaceRaised,
      foregroundImage:
          photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
      child: Icon(
        Icons.person_rounded,
        size: compact ? 20 : 24,
        color: colors.deepNavy,
      ),
    );
  }
}

class _BudgetSummaryRow extends StatelessWidget {
  const _BudgetSummaryRow({
    required this.categoryBadge,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.currencyCode,
    required this.percentage,
  });

  final Widget categoryBadge;
  final String categoryName;
  final double spent;
  final double limit;
  final String currencyCode;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/settings/budgets'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            categoryBadge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PHP ${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: percentage.clamp(0.0, 1.0),
                      backgroundColor: colors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_budgetColor(colors)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(percentage * 100).round()}%',
              style: textTheme.labelMedium?.copyWith(
                color: _budgetColor(colors),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _budgetColor(AppColors colors) {
    if (percentage >= 1) return colors.budgetDanger;
    if (percentage >= 0.8) return colors.budgetWarning;
    if (percentage >= 0.6) return colors.budgetCaution;
    return colors.budgetHealthy;
  }
}

class _DashboardJourneyCard extends StatelessWidget {
  const _DashboardJourneyCard({
    required this.journey,
    required this.onTap,
  });

  final ConscienceJourneySummary journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nextLevel = journey.nextLevel;

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
                    Icons.workspace_premium_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conscience Journey',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const _JourneyCardMascots(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.currentLevel.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextLevel == null
                              ? '${journey.xpTotal} XP earned'
                              : '${journey.xpTotal} XP · ${journey.xpToNextLevel} to ${nextLevel.title}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _JourneyMiniPill(
                              label: '${journey.momentumDays}-day streak',
                              icon: Icons.local_fire_department_rounded,
                            ),
                            _JourneyMiniPill(
                              label:
                                  '${_completedQuestCount(journey.weeklyQuests)}/${journey.weeklyQuests.length} quests',
                              icon: Icons.flag_rounded,
                            ),
                          ],
                        ),
                      ],
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

  static int _completedQuestCount(List<ConscienceQuest> quests) =>
      quests.where((quest) => quest.isCompleted == true).length;
}

class _JourneyCardMascots extends StatelessWidget {
  const _JourneyCardMascots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 74,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 24,
            child: MascotSpriteFrame(
              atlas: angelMascotAtlas,
              frameName: '4_win.png',
              width: 54,
            ),
          ),
          MascotSpriteFrame(
            atlas: devilMascotAtlas,
            frameName: '9_coin.png',
            width: 54,
          ),
        ],
      ),
    );
  }
}

class _JourneyMiniPill extends StatelessWidget {
  const _JourneyMiniPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
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
      case 'journey_level_up':
        return Icons.stairs_rounded;
      case 'journey_badge':
        return Icons.workspace_premium_rounded;
      case 'journey_quest':
        return Icons.flag_rounded;
      case 'ReflectionFollowUp':
        return Icons.psychology_alt_rounded;
      case 'recurring_transaction_created':
        return Icons.repeat_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
