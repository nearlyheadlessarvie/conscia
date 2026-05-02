import 'package:flutter/material.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/budget_progress_bar.dart';

int _daysUntilReset() {
  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 1);
  return endOfMonth.difference(now).inDays;
}

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onEdit,
    this.onDelete,
  });

  Color _healthColor(BuildContext context, double pct) {
    final colors = Theme.of(context).appColors;
    if (pct >= 1.0) return colors.budgetDanger;
    if (pct >= 0.8) return colors.budgetWarning;
    if (pct >= 0.5) return colors.budgetCaution;
    return colors.budgetHealthy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final pct = budget.percentage;
    final healthColor = _healthColor(context, pct);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: budget.isOverBudget
            ? BorderSide(
                color: theme.appColors.budgetDanger.withOpacity(0.5),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Icon(
                    CategoryIcons.forCategory(budget.category),
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    budget.category,
                    style: textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\$${budget.spent.toStringAsFixed(2)} / \$${budget.monthlyLimit.toStringAsFixed(2)}',
                    style: textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: textTheme.bodyLarge?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BudgetProgressBar(percentage: pct),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  budget.currencyCode,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Resets in ${_daysUntilReset()} days',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
