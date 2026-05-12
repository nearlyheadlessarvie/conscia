import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../models/managed_category.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/category_recents_provider.dart';

class QuickPresetChips extends ConsumerWidget {
  final String? selectedCategory;
  final bool isExpense;
  final bool isPremium;
  final ValueChanged<String> onCategorySelected;

  const QuickPresetChips({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    this.isPremium = true,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentCategories = ref.watch(recentCategoryProvider);
    final managedCategories =
        ref.watch(managedCategoriesProvider(const CategoryQuery())).maybeWhen(
              data: _managedCategoryNames,
              orElse: () => const <String>[],
            );
    final categories = managedCategories.isNotEmpty
        ? orderCategoriesByRecency(
            categories: managedCategories,
            recents: recentCategories,
          ).take(5).toList()
        : isExpense
            ? _expenseQuickCategories(recentCategories)
            : orderCategoriesByRecency(
                categories: incomeCategories,
                recents: recentCategories,
              ).take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: CategoryIcons.badge(
                cat,
                size: 14,
                selected: selectedCategory == cat,
              ),
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => onCategorySelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _expenseQuickCategories(List<String> recentCategories) {
    final allowedCategories = visibleBudgetCategories(
      isPremium: isPremium,
      categories: expenseCategories,
    );
    return orderCategoriesByRecency(
      categories: allowedCategories,
      recents: recentCategories,
    ).take(5).toList();
  }

  List<String> _managedCategoryNames(List<ManagedCategory> categories) {
    return categories
        .where((category) => !category.isArchived)
        .where((category) => isExpense ? category.isExpense : category.isIncome)
        .map((category) => category.name)
        .toList(growable: false);
  }
}
