import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/generated/app_constants.g.dart';
import '../../providers/budget_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_form_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) {
    return ref.read(budgetListProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetListProvider);

    return HeroScreenScaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _onAddBudget(context, ref),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildBody(context, ref, budgetState),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BudgetListState state,
  ) {
    if (state.isLoading && state.budgets.isEmpty) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: BudgetListSkeletonCard(),
          ),
        ),
      );
    }

    if (state.budgets.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          title: 'Budgets that match how you actually spend',
          subtitle:
              'Create flexible monthly limits for the categories you care about most.',
          actionLabel: 'Create your first budget',
          onAction: () => _onAddBudget(context, ref),
        ),
      );
    }

    return Column(
      children: [
        ScreenSection(
          title: 'Active budgets',
          subtitle: 'Track how each category is pacing this month.',
          compact: true,
          child: Column(
            children: [
              for (final budget in state.budgets)
                BudgetCard(
                  budget: budget,
                  onEdit: () => BudgetFormSheet.show(context, existing: budget),
                  onDelete: () => _confirmDelete(context, ref, budget.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onAddBudget(BuildContext context, WidgetRef ref) {
    final budgetState = ref.read(budgetListProvider);
    final subAsync = ref.read(subscriptionProvider);
    final isPremium = subAsync.valueOrNull?.isPremium ?? false;

    if (!isPremium &&
        budgetState.budgets.length >= FreemiumLimits.freeBudgetCategories) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve reached the free tier limit of ${FreemiumLimits.freeBudgetCategories} budget categories.',
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
