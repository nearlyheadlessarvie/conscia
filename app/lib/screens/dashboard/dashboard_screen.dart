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
import 'package:conscia_app/core/theme/app_layout.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
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
import 'package:conscia_app/screens/dashboard/journey_home_presenter.dart';
import 'package:conscia_app/screens/dashboard/widgets/journey_led_home_sections.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/screens/transactions/widgets/editorial_transaction_row.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/empty_state.dart';
import 'package:conscia_app/widgets/budget_mix_visuals.dart';
import 'package:conscia_app/widgets/conscia_bottom_sheet.dart';
import 'package:conscia_app/widgets/hero_shortcut_card.dart';
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';
import 'package:conscia_app/widgets/scope_pill_switch.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'package:conscia_app/widgets/swipe_action_tile.dart';

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
  String _budgetScope = 'personal';

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

  void _continueJourney() {
    context.push(AppRoutes.assistant);
  }

  void _openJourneyQuest(ConscienceQuest quest) {
    context.push(_journeyQuestRoute(quest));
  }

  void _openWeeklyInsights() {
    context.push(AppRoutes.insights);
  }

  String _journeyQuestRoute(ConscienceQuest quest) {
    return switch (quest.key) {
      'reflect_three_purchases' => AppRoutes.transactions,
      'check_before_purchase' => AppRoutes.assistant,
      'review_regret_pattern' => AppRoutes.insights,
      'send_family_invite' => AppRoutes.familyInvites,
      'add_family_expense' => AppRoutes.addTransaction,
      _ => AppRoutes.journey,
    };
  }

  BudgetTrendInsight? _graphableBudgetTrend(
    List<BudgetTrendInsight>? trends,
  ) {
    if (trends == null) return null;
    for (final trend in trends) {
      if (trend.months.length >= 2) return trend;
    }
    return null;
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
                final grouped = _groupAlerts(sheetAlerts);

                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ConsciaSheetHandle(),
                            const SizedBox(height: 18),
                            ConsciaSheetHeader(
                              title: 'Notifications',
                              subtitle: sheetAlerts.isEmpty
                                  ? 'Nothing needs your attention right now.'
                                  : 'The latest nudges and reminders from Conscia.',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (sheetAlerts.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'All clear',
                            subtitle: 'New reminders will show up here.',
                          ),
                        ),
                      )
                    else
                      for (final entry in grouped.entries) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              entry.key,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Divider(
                            height: 1,
                            indent: 20,
                            endIndent: 20,
                            color: colors.outlineVariant,
                          ),
                        ),
                        SliverList.separated(
                          itemCount: entry.value.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 76,
                            endIndent: 20,
                            color: colors.outlineVariant.withValues(alpha: 0.6),
                          ),
                          itemBuilder: (context, i) {
                            final alert = entry.value[i];
                            void dismiss() {
                              ref
                                  .read(dismissedAlertIdsProvider.notifier)
                                  .dismiss(alert.id);
                              setSheetState(() {
                                sheetAlerts = sheetAlerts
                                    .where((item) => item.id != alert.id)
                                    .toList(growable: false);
                              });
                            }

                            return Dismissible(
                              key: ValueKey(alert.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => dismiss(),
                              secondaryBackground: SwipeActionBackground(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 12),
                                children: [
                                  SwipeActionTile(
                                    icon: Icons.delete_sweep_rounded,
                                    label: 'Dismiss',
                                    foregroundColor:
                                        Theme.of(context).appColors.expense,
                                    backgroundColor:
                                        Theme.of(context).appColors.expenseSoft,
                                    onTap: () {},
                                  ),
                                ],
                              ),
                              background: const SizedBox.shrink(),
                              child: ColoredBox(
                                color: Theme.of(context).appColors.paper,
                                child: _NotificationListTile(
                                  alert: alert,
                                  onAction: alert.actionLabel == null &&
                                          alert.type != 'budget_nudge'
                                      ? null
                                      : () {
                                          Navigator.of(sheetContext).pop();
                                          _handleAlertAction(alert);
                                        },
                                ),
                              ),
                            );
                          },
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      ],
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static Map<String, List<AppAlert>> _groupAlerts(List<AppAlert> alerts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<AppAlert>>{
      'Today': [],
      'Yesterday': [],
      'A week ago': [],
      'Older': [],
    };

    for (final alert in alerts) {
      final d = DateTime(
          alert.createdAt.year, alert.createdAt.month, alert.createdAt.day);
      if (!d.isBefore(today)) {
        groups['Today']!.add(alert);
      } else if (!d.isBefore(yesterday)) {
        groups['Yesterday']!.add(alert);
      } else if (d.isAfter(weekAgo)) {
        groups['A week ago']!.add(alert);
      } else {
        groups['Older']!.add(alert);
      }
    }

    return Map.fromEntries(groups.entries.where((e) => e.value.isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetListProvider);
    final txState = ref.watch(transactionListProvider);
    final journeyState = ref.watch(conscienceJourneyProvider);
    final profile = ref.watch(currentUserProvider).valueOrNull;
    final userPreferences = ref.watch(userPreferencesProvider);
    final alerts =
        _visibleAlerts(ref.watch(activeAlertsProvider), budgetState.budgets);

    final budgets = budgetState.budgets;
    final hasPersonalBudgets = budgets.any((budget) => !budget.isFamily);
    final hasFamilyBudgets = budgets.any((budget) => budget.isFamily);
    final effectiveBudgetScope = hasPersonalBudgets ? _budgetScope : 'family';
    final visibleBudgets = hasFamilyBudgets
        ? budgets
            .where(
              (budget) => effectiveBudgetScope == 'family'
                  ? budget.isFamily
                  : !budget.isFamily,
            )
            .toList(growable: false)
        : budgets;
    final transactions = txState.transactions;
    final recentTransactions = transactions.take(5).toList();
    final journey = journeyState.valueOrNull;
    final journeyLoadingWithoutData = journeyState.isLoading && journey == null;
    final journeyHome = buildJourneyHomePresentation(journey);
    final dashboardInsightSummary =
        ref.watch(dashboardInsightSummaryProvider).valueOrNull;
    final behavioralInsights =
        ref.watch(behavioralInsightsProvider).valueOrNull;
    final dashboardInsightTrend =
        _graphableBudgetTrend(behavioralInsights?.budgetTrends);
    final regretPrompts = transactions
        .where((t) =>
            t.regretLevel == null &&
            t.type != 'income' &&
            !_dismissedPrompts.contains(t.id))
        .take(3)
        .toList();
    final greetingName = _greetingName(profile);
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
                  journey: journey,
                  presentation: journeyHome,
                  loading: journeyLoadingWithoutData,
                  onContinueJourney: _continueJourney,
                ),
              ),
              if (!journeyLoadingWithoutData)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: JourneyLedHomeSections(
                      summary: journey,
                      presentation: journeyHome,
                      insightSummary: dashboardInsightSummary,
                      insightTrend: dashboardInsightTrend,
                      onQuestSelected: _openJourneyQuest,
                      onOpenInsights: _openWeeklyInsights,
                    ),
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
                  sliver: SliverToBoxAdapter(
                    child: _DashboardBudgetSummary(
                      budgets: visibleBudgets,
                      selectedScope: effectiveBudgetScope,
                      showScopeSwitch: hasPersonalBudgets && hasFamilyBudgets,
                      locale: userPreferences.locale,
                      onScopeChanged: (value) =>
                          setState(() => _budgetScope = value.toLowerCase()),
                      onManageTap: () => context.push(AppRoutes.budgets),
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
                            type: transaction.type == 'income'
                                ? 'Income'
                                : 'Expense',
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
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
    required this.journey,
    required this.presentation,
    required this.loading,
    required this.onContinueJourney,
  });

  final ConscienceJourneySummary? journey;
  final JourneyHomePresentation presentation;
  final bool loading;
  final VoidCallback onContinueJourney;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    if (loading) {
      return const _DashboardHeroSkeleton();
    }

    final heroTopPadding = AppLayout.dashboardHeroTop(context);
    return Container(
      key: const ValueKey('dashboard-editorial-hero'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.paper,
            colors.amberSoft,
            colors.navySoft.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _JourneyHeroAtmospherePainter(),
            ),
          ),
          Positioned(
            right: 14,
            top: heroTopPadding + 28,
            child: const _JourneyHeroMascots(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, heroTopPadding, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey',
                  key: const ValueKey('dashboard-journey-hero-title'),
                  style: GoogleFonts.libreBaskerville(
                    textStyle: textTheme.displayMedium,
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w700,
                    height: 0.96,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Small choices, big freedom.',
                  key: const ValueKey('dashboard-journey-hero-subtitle'),
                  style: GoogleFonts.nunitoSans(
                    textStyle: textTheme.bodyMedium,
                    color: colors.ink.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                _JourneyHeroMomentum(
                  journey: journey,
                ),
                const SizedBox(height: 20),
                _JourneyHeroNextStepCard(
                  action: presentation.todayAction,
                  onPressed: onContinueJourney,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyHeroMomentum extends StatelessWidget {
  const _JourneyHeroMomentum({required this.journey});

  final ConscienceJourneySummary? journey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final momentumDays = journey?.momentumDays ?? 0;
    final bestMomentumDays = journey?.bestMomentumDays ?? 0;
    final remainingDays =
        bestMomentumDays > momentumDays ? bestMomentumDays - momentumDays : 0;
    final detail = momentumDays <= 0
        ? 'Start with one check-in to begin your stride.'
        : remainingDays > 0
            ? '$remainingDays more days to strengthen your stride.'
            : 'Your stride is getting stronger.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOMENTUM',
          style: GoogleFonts.nunitoSans(
            textStyle: textTheme.labelSmall,
            color: colors.deepNavy.withValues(alpha: 0.72),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: const Color(0xFFE97552),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$momentumDays day streak',
              key: const ValueKey('dashboard-journey-momentum-value'),
              style: GoogleFonts.nunitoSans(
                textStyle: textTheme.titleMedium,
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          key: const ValueKey('dashboard-journey-momentum-detail'),
          style: GoogleFonts.nunitoSans(
            textStyle: textTheme.bodySmall,
            color: colors.ink.withValues(alpha: 0.72),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _JourneyHeroNextStepCard extends StatelessWidget {
  const _JourneyHeroNextStepCard({
    required this.action,
    required this.onPressed,
  });

  final JourneyHomeAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const foreground = Colors.white;

    return Container(
      key: const ValueKey('dashboard-journey-next-step-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A34), Color(0xFF132D55)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT STEP',
                  style: GoogleFonts.nunitoSans(
                    textStyle: textTheme.labelSmall,
                    color: foreground.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  style: GoogleFonts.libreBaskerville(
                    textStyle: textTheme.titleLarge,
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '2 min  •  ${action.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    textStyle: textTheme.bodySmall,
                    color: foreground.withValues(alpha: 0.76),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 54,
            height: 54,
            child: FilledButton(
              key: const ValueKey('dashboard-journey-next-step-button'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: const Color(0xFFE97552),
                foregroundColor: foreground,
              ),
              onPressed: onPressed,
              child: const Icon(Icons.arrow_forward_rounded, size: 25),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyHeroMascots extends StatelessWidget {
  const _JourneyHeroMascots();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.88,
        child: SizedBox(
          width: 156,
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 4,
                top: 28,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.44),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Positioned(
                right: 2,
                top: 10,
                child: MascotSpriteFrame(
                  atlas: angelMascotAtlas,
                  frameName: '4_win.png',
                  width: 92,
                ),
              ),
              const Positioned(
                right: 66,
                top: 50,
                child: MascotSpriteFrame(
                  atlas: devilMascotAtlas,
                  frameName: '9_coin.png',
                  width: 68,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyHeroAtmospherePainter extends CustomPainter {
  const _JourneyHeroAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD98A).withValues(alpha: 0.42),
          const Color(0x00FFD98A),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.72, size.height * 0.26),
        radius: size.width * 0.38,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.26),
      size.width * 0.38,
      sunPaint,
    );

    final hillPaint = Paint()
      ..color = const Color(0xFF8CA889).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final backHill = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.46,
        size.width * 0.48,
        size.height * 0.66,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backHill, hillPaint);

    final pathPaint = Paint()
      ..color = const Color(0xFFD9B778).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.74,
        size.width * 0.64,
        size.height * 0.65,
        size.width * 0.78,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.66,
        size.width * 0.68,
        size.height * 0.82,
        size.width * 0.64,
        size.height,
      )
      ..close();
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final horizontalInset = 8.0 * opacity;
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
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        topPadding + AppLayout.stickyHeaderTopGap,
        horizontalInset,
        0,
      ),
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
              style: GoogleFonts.nunitoSans(
                textStyle: textTheme.titleSmall,
                color: colors.ink,
                fontWeight: FontWeight.w800,
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
                style: GoogleFonts.nunitoSans(
                  textStyle: textTheme.bodySmall,
                  color: colors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greetingName,
                style: GoogleFonts.nunitoSans(
                  textStyle: textTheme.titleLarge,
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
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

class _DashboardBudgetSummary extends StatelessWidget {
  const _DashboardBudgetSummary({
    required this.budgets,
    required this.selectedScope,
    required this.showScopeSwitch,
    required this.locale,
    required this.onScopeChanged,
    required this.onManageTap,
  });

  final List<Budget> budgets;
  final String selectedScope;
  final bool showScopeSwitch;
  final String? locale;
  final ValueChanged<String> onScopeChanged;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final mix = _budgetMix(budgets);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final totalLimit =
        budgets.fold<double>(0, (sum, b) => sum + b.monthlyLimit);
    final currencyCode = budgets.isEmpty ? 'PHP' : budgets.first.currencyCode;
    final usedPercent =
        totalLimit <= 0 ? 0 : ((totalSpent / totalLimit) * 100).round();

    return Column(
      key: const ValueKey('dashboard-budget-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          key: const ValueKey('dashboard-budget-top-row'),
          builder: (context, constraints) {
            final columnWidth = constraints.maxWidth / 2;
            final donutSize = columnWidth.clamp(96.0, 120.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: columnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${CurrencyFormatter.format(
                          totalSpent,
                          currencyCode: currencyCode,
                          locale: locale,
                        )} used',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.deepNavy,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${CurrencyFormatter.format(
                          totalLimit,
                          currencyCode: currencyCode,
                          locale: locale,
                        )} monthly cap',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                        ),
                      ),
                      if (showScopeSwitch) ...[
                        const SizedBox(height: 12),
                        ScopePillSwitch(
                          value: selectedScope,
                          familyEnabled: true,
                          onChanged: onScopeChanged,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  key: const ValueKey('dashboard-budget-donut-lane'),
                  width: columnWidth,
                  child: Center(
                    child: BudgetMixDonut(
                      key: const ValueKey('dashboard-budget-donut'),
                      size: donutSize,
                      trackStrokeWidth: donutSize * 0.17,
                      segmentStrokeWidth: donutSize * 0.125,
                      segments: _budgetSegments(mix, totalSpent),
                      center: Text(
                        '$usedPercent%',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.deepNavy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (mix.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            key: const ValueKey('dashboard-budget-mix-pill-rail'),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final entry in mix.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      right: entry.$1 == mix.length - 1 ? 0 : 8,
                    ),
                    child: BudgetMixPill(
                      index: entry.$1,
                      category: entry.$2.category,
                      type: 'Expense',
                      share: totalSpent <= 0 ? 0 : entry.$2.spent / totalSpent,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        HeroShortcutCard(
          key: const ValueKey('dashboard-manage-budgets'),
          icon: Icons.pie_chart_rounded,
          label: 'Manage budgets',
          subtitle: 'Tune caps and scope',
          onPressed: onManageTap,
        ),
      ],
    );
  }

  List<Budget> _budgetMix(List<Budget> budgets) {
    final copy = [...budgets]..sort((a, b) => b.spent.compareTo(a.spent));
    return copy.toList(growable: false);
  }

  List<BudgetMixDonutSegment> _budgetSegments(
    List<Budget> budgets,
    double totalSpent,
  ) {
    if (totalSpent <= 0) return const [];
    return budgets
        .where((budget) => budget.spent > 0)
        .indexed
        .map(
          (entry) => BudgetMixDonutSegment(
            share: entry.$2.spent / totalSpent,
            color: BudgetMixPalette.staticColorForCategory(
              entry.$2.category,
              type: 'Expense',
            ),
          ),
        )
        .toList(growable: false);
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

    final heroTopPadding = AppLayout.dashboardHeroTop(context);

    return Container(
      key: const ValueKey('dashboard-hero-skeleton'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, heroTopPadding, 20, 28),
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
    this.onAction,
  });

  final AppAlert alert;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final actionLabel = alert.actionLabel ??
        (alert.type == 'budget_nudge' ? 'Add budget' : null);
    final (iconBg, iconFg) = _iconColors(alert.type, appColors, colors);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(_iconFor(alert.type), color: iconFg, size: 20),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (actionLabel != null && onAction != null) ...[
                            GestureDetector(
                              onTap: onAction,
                              child: Text(
                                actionLabel,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            _relativeTime(alert.createdAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  (Color, Color) _iconColors(String type, AppColors a, ColorScheme c) {
    return switch (type) {
      'budget_nudge' => (a.amberSoft, a.amber),
      'journey_level_up' => (a.navySoft, a.deepNavy),
      'journey_badge' => (a.familySoft, a.family),
      'journey_quest' => (a.amberSoft, a.amber),
      'ReflectionFollowUp' => (a.angelSoft, a.angelAccent),
      'recurring_transaction_created' => (a.incomeSoft, a.income),
      _ => (c.primaryContainer.withValues(alpha: 0.7), c.primary),
    };
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
