import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/core/constants/app_icons.dart';
import 'package:conscia_app/core/constants/generated/app_constants.g.dart';
import 'package:conscia_app/core/constants/conscience_journey.dart';
import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/core/theme/app_colors.dart';
import 'package:conscia_app/core/theme/app_layout.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/auth_provider.dart';
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
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';
import 'package:conscia_app/widgets/horizontal_edge_fade.dart';
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
      await ref.read(conscienceJourneyProvider.notifier).recordEvent(
            eventType: ConscienceJourneyEvents.reflectionCompleted,
            sourceId: tx.id,
          );
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

  void _openJourneyQuest(ConscienceQuest quest) {
    if (quest.key == 'add_family_expense') {
      context.push(AppRoutes.addTransaction, extra: {'scope': 'family'});
      return;
    }
    if (quest.key == 'review_regret_pattern') {
      _recordJourneyEvent(
        eventType: ConscienceJourneyEvents.regretPatternReviewed,
        sourceId: 'quest:${quest.key}:${DateTime.now().millisecondsSinceEpoch}',
      );
    } else if (quest.key == 'read_two_insights') {
      _recordJourneyEvent(
        eventType: ConscienceJourneyEvents.insightReviewed,
        sourceId: 'quest:${quest.key}:${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    context.push(_journeyQuestRoute(quest));
  }

  void _openWeeklyInsights() {
    _recordJourneyEvent(
      eventType: ConscienceJourneyEvents.insightReviewed,
      sourceId: 'dashboard-insights:${DateTime.now().millisecondsSinceEpoch}',
    );
    context.push(AppRoutes.insights);
  }

  void _recordJourneyEvent({
    required String eventType,
    required String sourceId,
  }) {
    if (!ref.read(authProvider).isAuthenticated) return;
    unawaited(
      () async {
        try {
          await ref.read(conscienceJourneyProvider.notifier).recordEvent(
                eventType: eventType,
                sourceId: sourceId,
              );
        } catch (_) {
          // Journey progress is supportive context; never block navigation on it.
        }
      }(),
    );
  }

  String _journeyQuestRoute(ConscienceQuest quest) {
    return switch (quest.key) {
      'reflect_three_purchases' => AppRoutes.transactions,
      'check_before_purchase' => AppRoutes.assistant,
      'review_regret_pattern' => AppRoutes.insights,
      'read_two_insights' => AppRoutes.insights,
      'create_budget_guardrail' => AppRoutes.budgets,
      'send_family_invite' => AppRoutes.familyInvites,
      _ => AppRoutes.journey,
    };
  }

  ConscienceQuest? _nextOutstandingQuest(ConscienceJourneySummary? journey) {
    for (final quest in journey?.weeklyQuests ?? const <ConscienceQuest>[]) {
      if (!quest.isCompleted) return quest;
    }
    return null;
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
                final appColors = Theme.of(context).appColors;
                final textTheme = Theme.of(context).textTheme;
                final grouped = _groupAlerts(sheetAlerts);

                return Material(
                  color: appColors.paper,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _NotificationsSheetHeaderDelegate(
                          subtitle: sheetAlerts.isEmpty
                              ? 'Nothing needs your attention right now.'
                              : 'The latest nudges and reminders from Conscia.',
                          backgroundColor: appColors.paper,
                        ),
                      ),
                      if (sheetAlerts.isEmpty)
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: EmptyState(
                              icon: AppIconKey.notifications,
                              illustration: _DashboardEmptyStateIcon(
                                iconKey: AppIconKey.notifications,
                              ),
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
                              color:
                                  colors.outlineVariant.withValues(alpha: 0.6),
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
                                      icon: AppIconKey.delete,
                                      label: 'Dismiss',
                                      foregroundColor:
                                          Theme.of(context).appColors.expense,
                                      backgroundColor: Theme.of(context)
                                          .appColors
                                          .expenseSoft,
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
                  ),
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
    final nextJourneyQuest = _nextOutstandingQuest(journey);
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
                  onContinueJourney: nextJourneyQuest == null
                      ? () => context.push(AppRoutes.transactions)
                      : () => _openJourneyQuest(nextJourneyQuest),
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
                child: _buildSectionHeader(
                  context,
                  'Budgets',
                  subtitle: 'A quick pulse check on your monthly guardrails.',
                  topPadding: 10,
                ),
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
                    icon: AppIconKey.wallet,
                    illustration: const _DashboardEmptyStateIcon(
                      iconKey: AppIconKey.wallet,
                    ),
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
                  child: _buildSectionHeader(
                    context,
                    'Reflect',
                    subtitle:
                        'A small pause can show whether this moment fit your rhythm.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DashboardReflectQueue(
                        prompts: regretPrompts,
                        onReflect: _recordReflection,
                        onDismiss: (tx) =>
                            setState(() => _dismissedPrompts.add(tx.id)),
                      ),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  'Recent transactions',
                  subtitle: 'The latest money moments feeding your Journey.',
                ),
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
                    icon: AppIconKey.receipt,
                    illustration: const _DashboardEmptyStateIcon(
                      iconKey: AppIconKey.receipt,
                    ),
                    title: 'No transactions yet',
                    subtitle: 'Add your first transaction to get started.',
                    actionLabel: 'Add Transaction',
                    onAction: () => context.push(AppRoutes.addTransaction),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _DashboardRecentTransactionsList(
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
    double topPadding = 24,
  }) {
    final colors = Theme.of(context).appColors;
    final isEditorial = title != title.toUpperCase();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isEditorial
                ? GoogleFonts.libreBaskerville(
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  )
                : Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedInk,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.nunitoSans(
                textStyle: Theme.of(context).textTheme.bodySmall,
                color: colors.mutedInk,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardReflectQueue extends StatefulWidget {
  const _DashboardReflectQueue({
    required this.prompts,
    required this.onReflect,
    required this.onDismiss,
  });

  final List<Transaction> prompts;
  final Future<void> Function(Transaction tx, String feeling) onReflect;
  final ValueChanged<Transaction> onDismiss;

  @override
  State<_DashboardReflectQueue> createState() => _DashboardReflectQueueState();
}

enum _ReflectDeckMotion {
  worthIt,
  notSure,
  regret,
}

class _DashboardReflectQueueState extends State<_DashboardReflectQueue> {
  static const _advanceDuration = Duration(milliseconds: 560);
  static const _deckHeight = 248.0;

  late List<Transaction> _visiblePrompts;
  List<Transaction>? _bufferedExternalPrompts;
  Transaction? _exitingPrompt;
  _ReflectDeckMotion? _motion;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _visiblePrompts = List<Transaction>.from(widget.prompts);
  }

  @override
  void didUpdateWidget(covariant _DashboardReflectQueue oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.prompts.map((tx) => tx.id).toList(growable: false);
    final newIds = widget.prompts.map((tx) => tx.id).toList(growable: false);
    if (oldIds.join('|') == newIds.join('|')) {
      return;
    }

    if (_isAdvancing) {
      _bufferedExternalPrompts = List<Transaction>.from(widget.prompts);
      return;
    }

    setState(() {
      _syncVisiblePrompts(widget.prompts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMountedDeck =
        _visiblePrompts.isNotEmpty || _exitingPrompt != null || _isAdvancing;
    if (!hasMountedDeck) {
      return const SizedBox.shrink();
    }

    final activePrompt = _visiblePrompts.firstOrNull;
    final previewPrompts =
        _visiblePrompts.skip(1).take(2).toList(growable: false);

    return SizedBox(
      height: _deckHeight,
      child: Stack(
        key: const ValueKey('dashboard-reflect-deck-frame'),
        clipBehavior: Clip.none,
        children: [
          if (previewPrompts.length > 1)
            Positioned(
              key: const ValueKey('dashboard-reflect-preview-card-1'),
              left: 26,
              right: 26,
              top: 24,
              child: _ReflectDeckPreviewCard(
                prompt: previewPrompts[1],
                insetOpacity: 0.62,
              ),
            ),
          if (previewPrompts.isNotEmpty)
            Positioned(
              key: const ValueKey('dashboard-reflect-preview-card-0'),
              left: 13,
              right: 13,
              top: 12,
              child: _ReflectDeckPreviewCard(
                prompt: previewPrompts.first,
                insetOpacity: 0.82,
              ),
            ),
          if (activePrompt != null) _buildIncomingCard(activePrompt),
          if (_exitingPrompt != null) _buildOutgoingCard(_exitingPrompt!),
        ],
      ),
    );
  }

  Widget _buildIncomingCard(Transaction prompt) {
    final animationValue = _isAdvancing ? 1.0 : 0.0;
    return TweenAnimationBuilder<double>(
      key: ValueKey('dashboard-reflect-incoming-${prompt.id}'),
      tween: Tween<double>(begin: 0, end: animationValue),
      duration: _advanceDuration,
      curve: Curves.easeOutCubic,
      child: _buildPromptCard(
        prompt,
        onWorthIt:
            _isAdvancing ? null : () => _advanceQueue(prompt, 'worth_it'),
        onNotSure:
            _isAdvancing ? null : () => _advanceQueue(prompt, 'not_sure'),
        onRegret: _isAdvancing ? null : () => _advanceQueue(prompt, 'regret'),
        onDismiss: _isAdvancing ? null : () => _dismiss(prompt),
      ),
      builder: (context, value, child) {
        final translateY = _isAdvancing ? (26 * (1 - value)) : 0.0;
        final scale = _isAdvancing ? (0.95 + (0.05 * value)) : 1.0;
        final opacity = _isAdvancing ? (0.72 + (0.28 * value)) : 1.0;
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutgoingCard(Transaction prompt) {
    final motion = _motion ?? _ReflectDeckMotion.notSure;
    return TweenAnimationBuilder<double>(
      key: ValueKey('dashboard-reflect-outgoing-${prompt.id}-${motion.name}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _advanceDuration,
      curve: Curves.easeInOutCubic,
      child: IgnorePointer(
        child: _buildPromptCard(
          prompt,
          onWorthIt: null,
          onNotSure: null,
          onRegret: null,
          onDismiss: null,
        ),
      ),
      builder: (context, value, child) {
        final dx = switch (motion) {
          _ReflectDeckMotion.worthIt => -116 * value,
          _ReflectDeckMotion.regret => 116 * value,
          _ReflectDeckMotion.notSure => 0.0,
        };
        final dy = switch (motion) {
          _ReflectDeckMotion.notSure => -18 * value,
          _ => -8 * value,
        };
        final scale = switch (motion) {
          _ReflectDeckMotion.notSure => 1 - (0.1 * value),
          _ => 1 - (0.035 * value),
        };
        final opacity = 1 - (0.88 * value);
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromptCard(
    Transaction prompt, {
    required VoidCallback? onWorthIt,
    required VoidCallback? onNotSure,
    required VoidCallback? onRegret,
    required VoidCallback? onDismiss,
  }) {
    final displayCounterparty =
        prompt.description.isNotEmpty ? prompt.description : 'Unknown';
    return RegretPromptCard(
      categoryBadge: CategoryIcons.badge(
        displayCategoryForTransaction(prompt),
        size: 32,
        type: prompt.type == 'income' ? 'Income' : 'Expense',
      ),
      counterparty: displayCounterparty,
      amount: prompt.amount.abs(),
      currencyCode: prompt.currencyCode,
      date: prompt.date,
      onWorthIt: onWorthIt,
      onNotSure: onNotSure,
      onRegret: onRegret,
      onDismiss: onDismiss,
    );
  }

  Future<void> _advanceQueue(Transaction tx, String feeling) async {
    if (_isAdvancing || _visiblePrompts.isEmpty) return;
    final nextVisiblePrompts = List<Transaction>.from(_visiblePrompts)
      ..removeAt(0);
    setState(() {
      _isAdvancing = true;
      _motion = switch (feeling) {
        'worth_it' => _ReflectDeckMotion.worthIt,
        'regret' => _ReflectDeckMotion.regret,
        _ => _ReflectDeckMotion.notSure,
      };
      _exitingPrompt = tx;
      _visiblePrompts = nextVisiblePrompts;
    });
    await Future<void>.delayed(_advanceDuration);
    if (mounted) {
      setState(() {
        _isAdvancing = false;
        _exitingPrompt = null;
        _motion = null;
        if (_bufferedExternalPrompts != null) {
          _syncVisiblePrompts(_bufferedExternalPrompts!);
          _bufferedExternalPrompts = null;
        }
      });
    }
    unawaited(widget.onReflect(tx, feeling));
  }

  void _dismiss(Transaction tx) {
    if (_isAdvancing || _visiblePrompts.isEmpty) return;
    setState(() {
      _visiblePrompts = List<Transaction>.from(_visiblePrompts)..removeAt(0);
    });
    widget.onDismiss(tx);
  }

  void _syncVisiblePrompts(List<Transaction> externalPrompts) {
    final currentIds = _visiblePrompts.map((tx) => tx.id).toSet();
    final retained = externalPrompts
        .where((tx) => currentIds.contains(tx.id))
        .toList(growable: true);
    if (retained.isEmpty) {
      _visiblePrompts = List<Transaction>.from(externalPrompts);
    } else {
      final retainedIds = retained.map((tx) => tx.id).toSet();
      retained.addAll(
        externalPrompts.where((tx) => !retainedIds.contains(tx.id)),
      );
      _visiblePrompts = retained;
    }
  }
}

class _ReflectDeckPreviewCard extends StatelessWidget {
  const _ReflectDeckPreviewCard({
    required this.prompt,
    required this.insetOpacity,
  });

  final Transaction prompt;
  final double insetOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayCounterparty =
        prompt.description.isNotEmpty ? prompt.description : 'Unknown';
    final formatter = NumberFormat.currency(
      symbol: prompt.currencyCode,
      decimalDigits: 2,
    );

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: insetOpacity),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 226,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  Opacity(
                    opacity: 0.74,
                    child: TransactionTile.badgeFor(
                      prompt.category,
                      size: 24,
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayCounterparty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatter.format(prompt.amount.abs()),
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              child: AppIcons.icon(
                AppIconKey.fire,
                color: Colors.white,
                size: 14,
                strokeWidth: 1.8,
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
              child: AppIcons.icon(
                AppIconKey.chevronRight,
                keyId: const ValueKey('dashboard-journey-next-step-chevron'),
                color: foreground,
                size: 30,
              ),
            ),
          ),
        ],
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
              Text(
                greetingName,
                style: GoogleFonts.nunitoSans(
                  textStyle: textTheme.titleLarge,
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
      child: AppIcons.icon(
        AppIconKey.person,
        size: compact ? 20 : 24,
        color: colors.deepNavy,
      ),
    );
  }
}

class _DashboardRecentTransactionsList extends StatelessWidget {
  const _DashboardRecentTransactionsList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Column(
        children: [
          for (final entry in children.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == children.length - 1 ? 0 : 10,
              ),
              child: Container(
                key: const ValueKey('dashboard-recent-transaction-card'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.deepNavy.withValues(alpha: 0.025),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: entry.$2,
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetManageRow extends StatelessWidget {
  const _BudgetManageRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('dashboard-budget-manage-row'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: colors.navySoft.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.deepNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcons.icon(
                  AppIconKey.pieChart,
                  color: colors.deepNavy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage budgets',
                      style: GoogleFonts.nunitoSans(
                        textStyle: textTheme.labelLarge,
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tune caps and scope',
                      style: GoogleFonts.nunitoSans(
                        textStyle: textTheme.labelSmall,
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcons.icon(
                AppIconKey.chevronRight,
                color: colors.mutedInk,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardEmptyStateIcon extends StatelessWidget {
  const _DashboardEmptyStateIcon({
    required this.iconKey,
  });

  final AppIconKey iconKey;

  @override
  Widget build(BuildContext context) {
    return AppIcons.icon(
      iconKey,
      color: Theme.of(context).colorScheme.outlineVariant,
      size: 64,
      strokeWidth: 1.7,
    );
  }
}

class _DashboardBudgetSummary extends StatefulWidget {
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
  State<_DashboardBudgetSummary> createState() =>
      _DashboardBudgetSummaryState();
}

class _DashboardBudgetSummaryState extends State<_DashboardBudgetSummary> {
  final _mixRailController = ScrollController();
  final _pillKeys = <GlobalKey>[];
  int? _calledOutMixIndex;
  int _shakeSerial = 0;

  @override
  void dispose() {
    _mixRailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final mix = _budgetMix(widget.budgets);
    final activeMix = mix.where((budget) => budget.spent > 0).toList();
    _syncPillKeys(activeMix.length);
    final totalSpent =
        widget.budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final totalLimit =
        widget.budgets.fold<double>(0, (sum, b) => sum + b.monthlyLimit);
    final currencyCode =
        widget.budgets.isEmpty ? 'PHP' : widget.budgets.first.currencyCode;
    final usedPercent =
        totalLimit <= 0 ? 0 : ((totalSpent / totalLimit) * 100).round();

    return Column(
      key: const ValueKey('dashboard-budget-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('dashboard-budget-editorial-card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.deepNavy.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
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
                              'Used this month',
                              style: GoogleFonts.nunitoSans(
                                textStyle: textTheme.labelSmall,
                                color: colors.mutedInk,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${CurrencyFormatter.format(
                                totalSpent,
                                currencyCode: currencyCode,
                                locale: widget.locale,
                              )} used',
                              style: GoogleFonts.libreBaskerville(
                                textStyle: textTheme.titleLarge,
                                color: colors.deepNavy,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'of ${CurrencyFormatter.format(
                                totalLimit,
                                currencyCode: currencyCode,
                                locale: widget.locale,
                              )} monthly cap',
                              style: GoogleFonts.nunitoSans(
                                textStyle: textTheme.bodySmall,
                                color: colors.mutedInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'A calmer view of what your money is doing.',
                              style: GoogleFonts.nunitoSans(
                                textStyle: textTheme.bodySmall,
                                color: colors.mutedInk,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                            if (widget.showScopeSwitch) ...[
                              const SizedBox(height: 12),
                              ScopePillSwitch(
                                value: widget.selectedScope,
                                familyEnabled: true,
                                onChanged: widget.onScopeChanged,
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
                            onSegmentTap: _callOutMixPill,
                            center: Text(
                              '$usedPercent%',
                              style: GoogleFonts.nunitoSans(
                                textStyle: textTheme.labelSmall,
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
              if (activeMix.isNotEmpty) ...[
                const SizedBox(height: 14),
                HorizontalEdgeFade(
                  child: SingleChildScrollView(
                    key: const ValueKey('dashboard-budget-mix-pill-rail'),
                    controller: _mixRailController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      children: [
                        for (final entry in activeMix.indexed)
                          Padding(
                            padding: EdgeInsets.only(
                              right: entry.$1 == activeMix.length - 1 ? 20 : 8,
                            ),
                            child: BudgetMixPill(
                              key: _pillKeys[entry.$1],
                              index: entry.$1,
                              category: entry.$2.category,
                              type: 'Expense',
                              share: totalSpent <= 0
                                  ? 0
                                  : entry.$2.spent / totalSpent,
                              active: _calledOutMixIndex == entry.$1,
                              shakeSerial: _shakeSerial,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _BudgetManageRow(onTap: widget.onManageTap),
            ],
          ),
        ),
      ],
    );
  }

  void _syncPillKeys(int count) {
    while (_pillKeys.length < count) {
      _pillKeys.add(GlobalKey());
    }
    while (_pillKeys.length > count) {
      _pillKeys.removeLast();
    }
  }

  void _callOutMixPill(int index) {
    if (index < 0 || index >= _pillKeys.length) return;
    setState(() {
      _calledOutMixIndex = index;
      _shakeSerial++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _pillKeys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
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
        AppIcons.icon(
          AppIconKey.notifications,
          color: colors.onSurface,
          size: 24,
        ),
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

class _NotificationsSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  _NotificationsSheetHeaderDelegate({
    required this.subtitle,
    required this.backgroundColor,
  });

  final String subtitle;
  final Color backgroundColor;

  static const double _extent = 110;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        key: const ValueKey('notifications-sheet-sticky-header'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ConsciaSheetHandle(),
            const SizedBox(height: 18),
            ConsciaSheetHeader(
              title: 'Notifications',
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _NotificationsSheetHeaderDelegate oldDelegate) {
    return subtitle != oldDelegate.subtitle ||
        backgroundColor != oldDelegate.backgroundColor;
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(
              child: AppIcons.icon(
                _iconFor(alert.type),
                color: iconFg,
                size: 24,
              ),
            ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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

  AppIconKey _iconFor(String type) {
    switch (type) {
      case 'budget_nudge':
        return AppIconKey.wallet;
      case 'journey_level_up':
        return AppIconKey.arrowUp;
      case 'journey_badge':
        return AppIconKey.achievement;
      case 'journey_quest':
        return AppIconKey.flag;
      case 'ReflectionFollowUp':
        return AppIconKey.aiReflect;
      case 'recurring_transaction_created':
        return AppIconKey.recurring;
      default:
        return AppIconKey.notifications;
    }
  }
}
