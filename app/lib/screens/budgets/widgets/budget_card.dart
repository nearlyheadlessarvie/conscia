import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/budget_progress_bar.dart';
import '../../../widgets/feed_card.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeedCard(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: budget.isOverBudget
                ? Border.all(
                    color: theme.appColors.budgetDanger.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIcons.badge(
                    budget.category,
                    size: 18,
                    type: 'Expense',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            budget.category,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (budget.isFamily) ...[
                          const SizedBox(width: 8),
                          const _FamilyBudgetPill(),
                        ],
                      ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent so far',
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(
                            budget.spent,
                            currencyCode: budget.currencyCode,
                          ),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monthly cap',
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(
                          budget.monthlyLimit,
                          currencyCode: budget.currencyCode,
                        ),
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: textTheme.bodyLarge?.copyWith(
                      color: healthColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    budget.isOverBudget ? 'Over pace' : 'On pace',
                    style: textTheme.labelMedium?.copyWith(
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
      ),
    );
  }
}

class _FamilyBudgetPill extends StatelessWidget {
  const _FamilyBudgetPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.familySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcons.icon(
            AppIconKey.people,
            color: colors.family,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Family budget',
            style: textTheme.labelSmall?.copyWith(
              color: colors.family,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
