import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum InlineNoticeTone { neutral, info, error }

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.icon,
    this.tone = InlineNoticeTone.neutral,
  });

  final String message;
  final Widget? icon;
  final InlineNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedIcon =
        icon ?? const Text('🔒', style: TextStyle(fontSize: 15));

    final (backgroundColor, foregroundColor) = switch (tone) {
      InlineNoticeTone.error => (colors.expenseSoft, colors.expense),
      InlineNoticeTone.info => (colors.angelSoft, colors.angelAccent),
      InlineNoticeTone.neutral => (colors.navySoft, colors.deepNavy),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor),
            child: IconTheme(
              data: IconThemeData(color: foregroundColor, size: 15),
              child: resolvedIcon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
