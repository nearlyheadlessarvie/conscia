import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../models/managed_category.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/category_recents_provider.dart';
import 'category_picker.dart';

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
              data: _managedCategoryData,
              orElse: () => const <CategoryData>[],
            );
    final categories = managedCategories.isNotEmpty
        ? [
            for (final name in orderCategoriesByRecency(
              categories:
                  managedCategories.map((category) => category.name).toList(),
              recents: recentCategories,
            ).take(5))
              managedCategories.firstWhere((category) => category.name == name),
          ]
        : isExpense
            ? _expenseQuickCategories(recentCategories)
                .map((name) => CategoryData(name, type: 'Expense'))
                .toList()
            : orderCategoriesByRecency(
                categories: incomeCategories,
                recents: recentCategories,
              )
                .take(5)
                .map((name) => CategoryData(name, type: 'Income'))
                .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: CategoryIcons.badge(
                cat.name,
                size: 14,
                type: cat.type,
                iconKey: cat.iconKey,
                colorKey: cat.colorKey,
                selected: selectedCategory == cat.name,
              ),
              label: Text(cat.name),
              selected: selectedCategory == cat.name,
              onSelected: (_) => onCategorySelected(cat.name),
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

  List<CategoryData> _managedCategoryData(List<ManagedCategory> categories) {
    return categories
        .where((category) => !category.isArchived)
        .where((category) => isExpense ? category.isExpense : category.isIncome)
        .map(CategoryData.fromManaged)
        .toList(growable: false);
  }
}
