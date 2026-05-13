import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class FormLabel extends StatelessWidget {
  const FormLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
    );
  }
}
