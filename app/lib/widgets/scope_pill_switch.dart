import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'segmented_switch.dart';

class ScopePillSwitch extends StatelessWidget {
  const ScopePillSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.familyEnabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool familyEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return SegmentedSwitch(
      items: const ['Personal', 'Family'],
      selectedItem: value,
      selectedColor: colors.deepNavy,
      onChanged: familyEnabled ? onChanged : (String s) => {},
    );
  }
}
