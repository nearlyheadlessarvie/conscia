import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conscia_app/core/constants/tier_limits.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_summary_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_warning_banner.dart';
import 'package:conscia_app/screens/dashboard/widgets/financial_mood_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/impulse_trends_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/worth_it_counter_card.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_tile.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/empty_state.dart';
import 'package:conscia_app/widgets/premium_upgrade_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _bannerDismissed = false;
  final Set<String> _dismissedPrompts = {};

  Future<void> _recordReflection(Transaction tx, String feeling) async {
    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final usage = ref.read(monthlyUsageProvider);
    if (!isPremium && usage.reflections >= TierLimits.freeReflectionsPerMonth) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve used all ${TierLimits.freeReflectionsPerMonth} free reflections this month.',
      );
      return;
    }

    ref.read(monthlyUsageProvider.notifier).recordReflection();

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
    if (!mounted) return;
    setState(() => _dismissedPrompts.add(tx.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tx.description}: $label')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final budgetState = ref.watch(budgetListProvider);
    final txState = ref.watch(transactionListProvider);
    final insightsState = ref.watch(behavioralInsightsProvider);

    final budgets = budgetState.budgets;
    final transactions = txState.transactions;
    final recentTransactions = transactions.take(5).toList();
    final regretPrompts = transactions
        .where((t) =>
            t.regretLevel == null &&
            t.type != 'income' &&
            !_dismissedPrompts.contains(t.id))
        .take(3)
        .toList();

    final overBudgetCount = budgets.where((b) => b.percentage >= 0.8).length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
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
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
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
        // Behavioral Insights Section
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Your Insights'),
        ),
        insightsState.when(
          data: (insights) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FinancialMoodCard(
                  mood: insights.mood,
                  worthItPercentage: insights.worthItPercentage,
                  previousMonthPercentage:
                      insights.previousMonthWorthItCount > 0
                          ? (insights.previousMonthWorthItCount /
                              (insights.previousMonthWorthItCount + 10) *
                              100)
                          : 50,
                ),
                const SizedBox(height: 12),
                WorthItCounterCard(
                  thisMonthCount: insights.worthItCount,
                  previousMonthCount: insights.previousMonthWorthItCount,
                ),
                const SizedBox(height: 12),
                if (insights.impulseeTrends.isNotEmpty)
                  ImpulseTrendsCard(trends: insights.impulseeTrends),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Unable to load insights',
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Budgets'),
        ),
        if (budgetState.isLoading && budgets.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
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
                    categoryIcon: TransactionTile.iconFor(b.category),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RegretPromptCard(
                    categoryIcon: TransactionTile.iconFor(tx.category),
                    merchant: tx.description,
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
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
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
          SliverList.builder(
            itemCount: recentTransactions.length,
            itemBuilder: (context, index) {
              final t = recentTransactions[index];
              return RecentTransactionTile(
                id: t.id,
                categoryIcon: TransactionTile.iconFor(t.category),
                merchant: t.description.isNotEmpty ? t.description : 'Unknown',
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
