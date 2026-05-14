import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conscia_app/core/constants/generated/app_constants.g.dart';
import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/core/theme/app_colors.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
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
import 'package:conscia_app/screens/transactions/widgets/editorial_transaction_row.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/empty_state.dart';
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Set<String> _dismissedPrompts = {};
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _hasRestoredScrollOffset = false;

  static const _scrollOffsetStorageIdentifier =
      'dashboard-header-scroll-offset';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasRestoredScrollOffset) {
      final restoredOffset = PageStorage.maybeOf(context)?.readState(
        context,
        identifier: _scrollOffsetStorageIdentifier,
      );
      if (restoredOffset is num) {
        _scrollOffset = restoredOffset.toDouble();
      }
      _hasRestoredScrollOffset = true;
    }
    _syncScrollOffsetAfterLayout();
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
    PageStorage.maybeOf(context)?.writeState(
      context,
      nextOffset,
      identifier: _scrollOffsetStorageIdentifier,
    );
    if ((nextOffset - _scrollOffset).abs() < 1) return;
    setState(() => _scrollOffset = nextOffset);
  }

  void _syncScrollOffsetAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final nextOffset = _scrollController.offset;
      PageStorage.maybeOf(context)?.writeState(
        context,
        nextOffset,
        identifier: _scrollOffsetStorageIdentifier,
      );
      if ((nextOffset - _scrollOffset).abs() < 1) return;
      setState(() => _scrollOffset = nextOffset);
    });
  }

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
    final userPreferences = ref.watch(userPreferencesProvider);
    final alerts =
        _visibleAlerts(ref.watch(activeAlertsProvider), budgetState.budgets);

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
    final stickyProgress = ((_scrollOffset - 5) / 10).clamp(0.0, 1.0);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            key: const PageStorageKey('dashboard-shell-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _DashboardEditorialHeroCard(
                  monthExpenseTotal: monthExpenseTotal,
                  currencyCode: userPreferences.currency,
                  locale: userPreferences.locale,
                  journey: journey,
                  summary: insightSummary,
                  loading: (journeyState.isLoading && journey == null) ||
                      (insightSummaryState.isLoading && insightSummary == null),
                  onJourneyTap: () => context.push(AppRoutes.journey),
                  onInsightsTap: () => context.push(AppRoutes.insights),
                  onAddTransactionTap: () =>
                      context.push(AppRoutes.addTransaction),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'BUDGETS'),
              ),
              if (budgetState.isLoading && budgets.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        _FlatBudgetRowSkeleton(),
                        Divider(height: 1),
                        _FlatBudgetRowSkeleton(),
                        Divider(height: 1),
                        _FlatBudgetRowSkeleton(),
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
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final budget = budgets[index];
                        return Column(
                          children: [
                            _BudgetSummaryRow(
                              categoryBadge: TransactionTile.badgeFor(
                                budget.category,
                                size: 30,
                                filled: false,
                              ),
                              categoryName: budget.category,
                              spent: budget.spent,
                              limit: budget.monthlyLimit,
                              currencyCode: budget.currencyCode,
                              locale: userPreferences.locale,
                              percentage: budget.percentage,
                            ),
                            if (index < budgets.take(4).length - 1)
                              Divider(
                                  height: 1,
                                  color: Theme.of(context).appColors.border),
                          ],
                        );
                      },
                      childCount: budgets.take(4).length,
                    ),
                  ),
                ),
              if (regretPrompts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(context, 'REFLECT'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: regretPrompts.length,
                    itemBuilder: (context, index) {
                      final tx = regretPrompts[index];
                      final displayCounterparty = tx.description.isNotEmpty
                          ? tx.description
                          : 'Unknown';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RegretPromptCard(
                          categoryBadge: TransactionTile.badgeFor(
                            tx.category,
                            size: 30,
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
                child: _buildSectionHeader(context, 'RECENT TRANSACTIONS'),
              ),
              if (txState.isLoading && transactions.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        _FlatTransactionRowSkeleton(),
                        Divider(height: 1),
                        _FlatTransactionRowSkeleton(),
                        Divider(height: 1),
                        _FlatTransactionRowSkeleton(),
                      ],
                    ),
                  ),
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
                SliverToBoxAdapter(
                  child: EditorialTransactionRowsGroup(
                    horizontalPadding: 20,
                    children: [
                      for (final transaction in recentTransactions)
                        RecentTransactionTile(
                          id: transaction.id,
                          categoryBadge: CategoryIcons.badge(
                            displayCategoryForTransaction(transaction),
                            size: 30,
                          ),
                          counterparty: transaction.description.trim().isEmpty
                              ? 'Unknown'
                              : transaction.description.trim(),
                          category: displayCategoryForTransaction(transaction),
                          date: transaction.date,
                          amount: transaction.amount,
                          isIncome: transaction.type == 'income',
                          currencyCode: transaction.currencyCode,
                          regretLevel: transaction.regretLevel,
                          isRecurring: transaction.isRecurring,
                          isFamily: transaction.isFamily,
                          locale: userPreferences.locale,
                        ),
                    ],
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _DashboardStickyOverlayHeader(
            progress: stickyProgress,
            topPadding: MediaQuery.paddingOf(context).top,
            profile: profile,
            greetingName: greetingName,
            alertsCount: alerts.length,
            onNotificationsTap: () => _showNotificationsSheet(alerts),
          ),
        ),
      ],
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
    final budgetCategories =
        budgets.map((budget) => budget.category.toLowerCase()).toSet();
    return alerts.where((alert) {
      if (alert.type != 'budget_nudge') {
        return true;
      }
      final category = alert.category?.toLowerCase();
      return category == null || !budgetCategories.contains(category);
    }).toList(growable: false);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _DashboardEditorialHeroCard extends StatelessWidget {
  const _DashboardEditorialHeroCard({
    required this.monthExpenseTotal,
    required this.currencyCode,
    required this.locale,
    required this.journey,
    required this.summary,
    required this.loading,
    required this.onJourneyTap,
    required this.onInsightsTap,
    required this.onAddTransactionTap,
  });

  final double monthExpenseTotal;
  final String currencyCode;
  final String? locale;
  final ConscienceJourneySummary? journey;
  final DashboardInsightSummary? summary;
  final bool loading;
  final VoidCallback onJourneyTap;
  final VoidCallback onInsightsTap;
  final VoidCallback onAddTransactionTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    if (loading) {
      return const _DashboardHeroSkeleton();
    }

    return Container(
      key: const ValueKey('dashboard-editorial-hero'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft,
            colors.amberSoft,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT THIS MONTH',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(
              monthExpenseTotal,
              currencyCode: currencyCode,
              locale: locale,
            ),
            style: GoogleFonts.inter(
              textStyle: textTheme.displaySmall,
              color: colors.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary?.text ??
                (journey == null
                    ? 'Conscia will turn your next few transactions into a clearer monthly story.'
                    : '${journey!.momentumDays}-day mindful streak · ${_DashboardJourneyCard._completedQuestCount(journey!.weeklyQuests)}/${journey!.weeklyQuests.length} quests this week'),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
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
                  buttonKey: const ValueKey('dashboard-journey-link'),
                  icon: Icons.flag_rounded,
                  label: 'Journey',
                  onPressed: onJourneyTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardQuickLink(
                  buttonKey: const ValueKey('dashboard-insights-link'),
                  icon: Icons.auto_graph_rounded,
                  label: 'Insights',
                  onPressed: onInsightsTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardQuickLink(
                  buttonKey: const ValueKey('dashboard-add-link'),
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
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      key: buttonKey,
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

class _DashboardStickyOverlayHeader extends StatelessWidget {
  const _DashboardStickyOverlayHeader({
    required this.progress,
    required this.topPadding,
    required this.profile,
    required this.greetingName,
    required this.alertsCount,
    required this.onNotificationsTap,
  });

  final double progress;
  final double topPadding;
  final UserProfile? profile;
  final String greetingName;
  final int alertsCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final opacity = progress >= 1.0 ? 1.0 : 0.0;
    final radius = BorderRadius.circular(999);
    final headerBackground = Color.lerp(
      Colors.transparent,
      colors.paper.withValues(alpha: 0.64),
      opacity,
    )!;
    final borderColor = Color.lerp(
      Colors.transparent,
      colors.border.withValues(alpha: 0.84),
      opacity,
    )!;

    return Padding(
      padding: EdgeInsets.fromLTRB(5, topPadding + 8, 5, 0),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 18 * opacity,
            sigmaY: 18 * opacity,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            key: const ValueKey('dashboard-sticky-identity-header'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: headerBackground,
              borderRadius: radius,
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
            child: _DashboardStickyIdentityHeader(
              profile: profile,
              greetingName: greetingName,
              alertsCount: alertsCount,
              onNotificationsTap: onNotificationsTap,
              collapsed: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStickyIdentityHeader extends StatelessWidget {
  const _DashboardStickyIdentityHeader({
    required this.profile,
    required this.greetingName,
    required this.alertsCount,
    required this.onNotificationsTap,
    required this.collapsed,
  });

  final UserProfile? profile;
  final String greetingName;
  final int alertsCount;
  final VoidCallback onNotificationsTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return _DashboardIdentityRow(
      profile: profile,
      greetingName: greetingName,
      alertsCount: alertsCount,
      onNotificationsTap: onNotificationsTap,
      compact: collapsed,
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

    if (compact) {
      return Row(
        children: [
          _ProfileAvatar(photoUrl: profile?.photoUrl, compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              greetingName,
              style: GoogleFonts.poppins(
                textStyle: textTheme.titleSmall,
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Notifications',
              visualDensity: VisualDensity.compact,
              onPressed: onNotificationsTap,
              icon: _NotificationBell(count: alertsCount),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _ProfileAvatar(photoUrl: profile?.photoUrl, compact: false),
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
                  textStyle: textTheme.titleLarge,
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: colors.surfaceRaised.withValues(alpha: 0.92),
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
      foregroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
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
    required this.locale,
    required this.percentage,
  });

  final Widget categoryBadge;
  final String categoryName;
  final double spent;
  final double limit;
  final String currencyCode;
  final String? locale;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/settings/budgets'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categoryBadge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: textTheme.titleSmall?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${CurrencyFormatter.format(
                                spent,
                                currencyCode: currencyCode,
                                locale: locale,
                              )} / ${CurrencyFormatter.format(
                                limit,
                                currencyCode: currencyCode,
                                locale: locale,
                              )}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.mutedInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(percentage * 100).round()}%',
                        style: textTheme.titleSmall?.copyWith(
                          color: _budgetColor(colors),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

class _FlatBudgetRowSkeleton extends StatelessWidget {
  const _FlatBudgetRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 30, height: 30, borderRadius: 15),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: SkeletonLoader(height: 14, width: 90)),
                    SizedBox(width: 12),
                    SkeletonLoader(height: 14, width: 34),
                  ],
                ),
                SizedBox(height: 6),
                SkeletonLoader(height: 12, width: 130),
                SizedBox(height: 10),
                SkeletonLoader(height: 6, borderRadius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatTransactionRowSkeleton extends StatelessWidget {
  const _FlatTransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SkeletonLoader(width: 30, height: 30, borderRadius: 15),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 14, width: 120),
                SizedBox(height: 6),
                SkeletonLoader(height: 12, width: 72),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonLoader(height: 14, width: 84),
        ],
      ),
    );
  }
}

class _DashboardHeroSkeleton extends StatelessWidget {
  const _DashboardHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      key: const ValueKey('dashboard-hero-skeleton'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 28),
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 12, width: 100),
          SizedBox(height: 10),
          SkeletonLoader(height: 38, width: 210),
          SizedBox(height: 10),
          SkeletonLoader(height: 14),
          SizedBox(height: 6),
          SkeletonLoader(height: 14, width: 220),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 38, borderRadius: 999)),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 38, borderRadius: 999)),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 64, borderRadius: 18)),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 64, borderRadius: 18)),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 64, borderRadius: 18)),
            ],
          ),
        ],
      ),
    );
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
