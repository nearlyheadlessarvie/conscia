import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/insights_models.dart';

class CategoryTrendCard extends StatelessWidget {
  final CategoryStat category;

  const CategoryTrendCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const currency = '£';

    return Card(
      child: InkWell(
        onTap: () => context.push('/insights/categories'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📈 Category trend',
                      style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(category.category,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '$currency${category.regrettedSpend.toStringAsFixed(0)} regretted last 30 days',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '→ $currency${category.projectedAnnual.toStringAsFixed(0)}/year projected',
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
