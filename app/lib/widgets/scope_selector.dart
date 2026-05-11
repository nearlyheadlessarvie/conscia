import 'package:flutter/material.dart';

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
      segments: const [
        ButtonSegment(
          value: 'personal',
          label: Text('Personal'),
          icon: Icon(Icons.person_outline),
        ),
        ButtonSegment(
          value: 'family',
          label: Text('Family'),
          icon: Icon(Icons.diversity_3_outlined),
        ),
      ],
      selected: {familyEnabled ? value : 'personal'},
      onSelectionChanged:
          familyEnabled ? (selection) => onChanged(selection.first) : null,
    );
  }
}
