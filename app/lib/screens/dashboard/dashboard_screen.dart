import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conscia_app/screens/dashboard/widgets/budget_summary_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_warning_banner.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/widgets/empty_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _bannerDismissed = false;

  // Mock data — will be replaced by providers
  final _budgets = [
    (icon: Icons.restaurant, name: 'Food', spent: 380.0, limit: 500.0, currency: 'USD'),
    (icon: Icons.directions_car, name: 'Transport', spent: 220.0, limit: 250.0, currency: 'USD'),
    (icon: Icons.shopping_bag, name: 'Shopping', spent: 190.0, limit: 300.0, currency: 'USD'),
    (icon: Icons.movie, name: 'Entertainment', spent: 95.0, limit: 150.0, currency: 'USD'),
  ];

  final _regretPrompts = [
    (icon: Icons.coffee, merchant: 'Starbucks', amount: 6.50, date: DateTime.now().subtract(const Duration(hours: 30)), currency: 'USD'),
    (icon: Icons.shopping_bag, merchant: 'Amazon', amount: 49.99, date: DateTime.now().subtract(const Duration(hours: 36)), currency: 'USD'),
  ];

  final _recentTransactions = [
    (id: '1', icon: Icons.restaurant, merchant: 'Chipotle', category: 'Food', date: DateTime.now().subtract(const Duration(hours: 2)), amount: 12.50, isIncome: false, currency: 'USD', regret: null),
    (id: '2', icon: Icons.work, merchant: 'Salary', category: 'Income', date: DateTime.now().subtract(const Duration(days: 1)), amount: 3200.0, isIncome: true, currency: 'USD', regret: null),
    (id: '3', icon: Icons.directions_car, merchant: 'Uber', category: 'Transport', date: DateTime.now().subtract(const Duration(days: 1)), amount: 18.75, isIncome: false, currency: 'USD', regret: 3),
    (id: '4', icon: Icons.shopping_bag, merchant: 'Target', category: 'Shopping', date: DateTime.now().subtract(const Duration(days: 2)), amount: 67.30, isIncome: false, currency: 'USD', regret: 1),
    (id: '5', icon: Icons.movie, merchant: 'Netflix', category: 'Entertainment', date: DateTime.now().subtract(const Duration(days: 3)), amount: 15.99, isIncome: false, currency: 'USD', regret: 2),
  ];

  int get _overBudgetCount =>
      _budgets.where((b) => b.spent / b.limit >= 0.8).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

        // Budget Warning Banner
        if (_overBudgetCount > 0 && !_bannerDismissed)
          SliverToBoxAdapter(
            child: BudgetWarningBanner(
              overBudgetCount: _overBudgetCount,
              onDismiss: () => setState(() => _bannerDismissed = true),
            ),
          ),

        // Budget Summary Cards
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Budgets'),
        ),
        if (_budgets.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No budgets yet',
              subtitle: 'Set up budgets to track your spending limits.',
              actionLabel: 'Add Budget',
              onAction: () {},
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _budgets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final b = _budgets[index];
                  return BudgetSummaryCard(
                    categoryIcon: b.icon,
                    categoryName: b.name,
                    spent: b.spent,
                    limit: b.limit,
                    currencyCode: b.currency,
                  );
                },
              ),
            ),
          ),

        // Regret Prompt Cards
        if (_regretPrompts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Reflect'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: _regretPrompts.length,
              itemBuilder: (context, index) {
                final r = _regretPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RegretPromptCard(
                    categoryIcon: r.icon,
                    merchant: r.merchant,
                    amount: r.amount,
                    currencyCode: r.currency,
                    date: r.date,
                    onWorthIt: () {},
                    onNotSure: () {},
                    onRegret: () {},
                    onDismiss: () {},
                  ),
                );
              },
            ),
          ),
        ],

        // Recent Transactions
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Recent Transactions'),
        ),
        if (_recentTransactions.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Add your first transaction to get started.',
              actionLabel: 'Add Transaction',
              onAction: () {},
            ),
          )
        else
          SliverList.builder(
            itemCount: _recentTransactions.length,
            itemBuilder: (context, index) {
              final t = _recentTransactions[index];
              return RecentTransactionTile(
                id: t.id,
                categoryIcon: t.icon,
                merchant: t.merchant,
                category: t.category,
                date: t.date,
                amount: t.amount,
                isIncome: t.isIncome,
                currencyCode: t.currency,
                regretLevel: t.regret,
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
