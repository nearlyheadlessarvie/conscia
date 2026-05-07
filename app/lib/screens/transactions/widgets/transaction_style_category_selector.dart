import 'package:flutter/material.dart';

import '../../../core/constants/category_icons.dart';
import 'category_picker.dart';
import 'quick_preset_chips.dart';

class TransactionStyleCategorySelector extends StatelessWidget {
  const TransactionStyleCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    required this.isPremium,
    required this.onCategorySelected,
    this.labelStyle,
    this.moreCategoriesIcon = Icons.add,
    this.showHeader = true,
  });

  final String? selectedCategory;
  final bool isExpense;
  final bool isPremium;
  final ValueChanged<String?> onCategorySelected;
  final TextStyle? labelStyle;
  final IconData moreCategoriesIcon;
  final bool showHeader;

  Future<void> _showCategoryPickerSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: CategoryPicker(
              selected: selectedCategory,
              isExpense: isExpense,
              isPremium: isPremium,
              maxVisible: 100,
              onSelected: (category) {
                onCategorySelected(category);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesContent = selectedCategory != null
        ? Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: CategoryIcons.badge(
                selectedCategory!,
                size: 16,
                selected: true,
              ),
              label: Text(selectedCategory!),
              onDeleted: () => onCategorySelected(null),
            ),
          )
        : QuickPresetChips(
            selectedCategory: selectedCategory,
            isExpense: isExpense,
            isPremium: isPremium,
            onCategorySelected: onCategorySelected,
          );

    final action = Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _showCategoryPickerSheet(context),
        icon: Icon(moreCategoriesIcon, size: 16),
        label: const Text('All categories'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Row(
            children: [
              Text('Category',
                  style: labelStyle ?? Theme.of(context).textTheme.titleSmall),
            ],
          )
        else
          const SizedBox.shrink(),
        if (showHeader) const SizedBox(height: 8),
        categoriesContent,
        const SizedBox(height: 4),
        action,
      ],
    );
  }
}
