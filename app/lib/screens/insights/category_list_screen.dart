import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(insightsCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load categories.')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No category data yet.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryStat category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratePercent = (category.regretRate * 100).toStringAsFixed(0);
    final color = category.regretRate >= 0.6
        ? colors.error
        : category.regretRate >= 0.4
            ? colors.tertiary
            : colors.primary;

    return ListTile(
      title: Text(category.category),
      subtitle: Text('£${category.regrettedSpend.toStringAsFixed(0)} regretted · ${category.transactionCount} purchases'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$ratePercent%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('regret', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
      onTap: () => context.push('/insights/categories/${Uri.encodeComponent(category.category)}'),
    );
  }
}
