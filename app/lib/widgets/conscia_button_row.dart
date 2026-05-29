import 'package:flutter/material.dart';

class ConsciaButtonRow extends StatelessWidget {
  const ConsciaButtonRow({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.gap = 12,
    this.height,
    this.textStyle,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final double gap;
  final double? height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondaryPressed,
            style: _outlinedStyle(),
            child: Text(secondaryLabel),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: FilledButton(
            onPressed: onPrimaryPressed,
            style: _filledStyle(),
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }

  ButtonStyle? _outlinedStyle() {
    if (height == null && textStyle == null) return null;
    return OutlinedButton.styleFrom(
      minimumSize: height == null ? null : Size(0, height!),
      padding:
          height == null ? null : const EdgeInsets.symmetric(horizontal: 16),
      tapTargetSize: height == null ? null : MaterialTapTargetSize.shrinkWrap,
      textStyle: textStyle,
    );
  }

  ButtonStyle? _filledStyle() {
    if (height == null && textStyle == null) return null;
    return FilledButton.styleFrom(
      minimumSize: height == null ? null : Size(0, height!),
      padding:
          height == null ? null : const EdgeInsets.symmetric(horizontal: 16),
      tapTargetSize: height == null ? null : MaterialTapTargetSize.shrinkWrap,
      textStyle: textStyle,
    );
  }
}
