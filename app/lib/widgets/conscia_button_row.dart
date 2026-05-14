import 'package:flutter/material.dart';

class ConsciaButtonRow extends StatelessWidget {
  const ConsciaButtonRow({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.gap = 12,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondaryPressed,
            child: Text(secondaryLabel),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: FilledButton(
            onPressed: onPrimaryPressed,
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
