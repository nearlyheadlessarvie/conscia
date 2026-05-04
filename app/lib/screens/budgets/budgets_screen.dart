import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/tier_limits.dart';
import '../../providers/budget_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_form_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _onAddBudget(context, ref),
          ),
        ],
      ),
      body: _buildBody(context, ref, budgetState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BudgetListState state,
  ) {
    if (state.isLoading && state.budgets.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 3,
        itemBuilder: (_, __) => const BudgetListSkeletonCard(),
      );
    }

    if (state.budgets.isEmpty) {
      return EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'No budgets yet',
        subtitle: 'Create a budget to track your spending by category.',
        actionLabel: 'Create Budget',
        onAction: () => _onAddBudget(context, ref),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(budgetListProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.budgets.length,
        itemBuilder: (context, index) {
          final budget = state.budgets[index];
          return BudgetCard(
            budget: budget,
            onEdit: () => BudgetFormSheet.show(context, existing: budget),
            onDelete: () => _confirmDelete(context, ref, budget.id),
          );
        },
      ),
    );
  }

  void _onAddBudget(BuildContext context, WidgetRef ref) {
    final budgetState = ref.read(budgetListProvider);
    final subAsync = ref.read(subscriptionProvider);
    final isPremium = subAsync.valueOrNull?.isPremium ?? false;

    if (!isPremium &&
        budgetState.budgets.length >= TierLimits.freeBudgetCategories) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve reached the free tier limit of ${TierLimits.freeBudgetCategories} budget categories.',
      );
      return;
    }
    BudgetFormSheet.show(context);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(budgetListProvider.notifier).delete(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
