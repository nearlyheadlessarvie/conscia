import 'package:flutter/material.dart';

import '../../../services/subscription_service.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionStatus status;
  final VoidCallback? onUpgrade;
  final VoidCallback? onManage;

  const SubscriptionCard({
    super.key,
    required this.status,
    this.onUpgrade,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: status.isPremium ? _buildPremium(textTheme, theme) : _buildFree(textTheme, theme),
    );
  }

  Widget _buildFree(TextTheme textTheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Free Plan', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '${status.transactionCount}/${status.transactionLimit} transactions • '
          '${status.budgetCount}/${status.budgetLimit} budgets',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onUpgrade,
            child: const Text('Upgrade to Premium'),
          ),
        ),
      ],
    );
  }

  Widget _buildPremium(TextTheme textTheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text('Premium', style: textTheme.titleMedium),
          ],
        ),
        if (status.expiresAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Expires ${_formatDate(status.expiresAt!)}',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onManage,
            child: const Text('Manage'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
