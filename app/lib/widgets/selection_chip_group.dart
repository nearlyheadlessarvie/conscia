import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SelectionChipGroup extends StatelessWidget {
  const SelectionChipGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onSelected,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final selected = option == value;
        return AnimatedContainer(
          key: ValueKey(
            'selection-chip-$option-${selected ? 'selected' : 'idle'}',
          ),
          duration: const Duration(milliseconds: 160),
          child: ChoiceChip(
            label: Text(option),
            selected: selected,
            onSelected: (_) => onSelected(option),
            backgroundColor: colors.surfaceMuted,
            selectedColor: colors.heroTint,
            side: BorderSide(
              color: selected ? colors.sectionBorder : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }
}
