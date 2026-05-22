import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';

class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.familyEnabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool familyEnabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(
          value: 'personal',
          label: const Text('Personal'),
          icon: AppIcons.icon(
            AppIconKey.person,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
        ),
        ButtonSegment(
          value: 'family',
          label: const Text('Family'),
          icon: AppIcons.icon(
            AppIconKey.family,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
        ),
      ],
      selected: {familyEnabled ? value : 'personal'},
      onSelectionChanged:
          familyEnabled ? (selection) => onChanged(selection.first) : null,
    );
  }
}
