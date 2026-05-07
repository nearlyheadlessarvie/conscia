import 'package:flutter/material.dart';

import '../../../core/constants/category_icons.dart';
import 'category_picker.dart';
import 'quick_preset_chips.dart';

class TransactionStyleCategorySelector extends StatelessWidget {
  const TransactionStyleCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    required this.onCategorySelected,
    this.labelStyle,
    this.moreCategoriesIcon = Icons.add,
  });

  final String? selectedCategory;
  final bool isExpense;
  final ValueChanged<String?> onCategorySelected;
  final TextStyle? labelStyle;
  final IconData moreCategoriesIcon;

  Future<void> _showCategoryPickerSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: CategoryPicker(
              selected: selectedCategory,
              isExpense: isExpense,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Category', style: labelStyle ?? Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCategoryPickerSheet(context),
              icon: Icon(moreCategoriesIcon, size: 16),
              label: const Text('More categories'),
            ),
          ],
        ),
        if (selectedCategory != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: Icon(
                CategoryIcons.forCategory(selectedCategory!),
                size: 18,
              ),
              label: Text(selectedCategory!),
              onDeleted: () => onCategorySelected(null),
            ),
          ),
        ] else ...[
          QuickPresetChips(
            selectedCategory: selectedCategory,
            isExpense: isExpense,
            onCategorySelected: onCategorySelected,
          ),
        ],
      ],
    );
  }
}
