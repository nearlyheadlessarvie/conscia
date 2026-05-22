import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

enum FeelingChoiceButtonSize { large, compact }

class FeelingPresentation {
  const FeelingPresentation({
    required this.label,
    required this.iconKey,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final AppIconKey iconKey;
  final Color color;
  final Color backgroundColor;
}

class FeelingChoiceButton extends StatelessWidget {
  const FeelingChoiceButton.worthIt({
    super.key,
    this.onPressed,
    this.size = FeelingChoiceButtonSize.large,
  }) : level = 0;

  const FeelingChoiceButton.notSure({
    super.key,
    this.onPressed,
    this.size = FeelingChoiceButtonSize.large,
  }) : level = 1;

  const FeelingChoiceButton.regret({
    super.key,
    this.onPressed,
    this.size = FeelingChoiceButtonSize.large,
  }) : level = 2;

  final int level;
  final FeelingChoiceButtonSize size;
  final VoidCallback? onPressed;

  static FeelingPresentation presentationForLevel(
    int level,
    AppColors colors,
  ) {
    if (level == 0) {
      return FeelingPresentation(
        label: 'Worth It',
        iconKey: AppIconKey.thumbsUp,
        color: colors.income,
        backgroundColor: colors.incomeSoft,
      );
    }
    if (level == 1) {
      return FeelingPresentation(
        label: 'Not Sure',
        iconKey: AppIconKey.help,
        color: colors.amber,
        backgroundColor: colors.amberSoft,
      );
    }
    return FeelingPresentation(
      label: 'Regret',
      iconKey: AppIconKey.thumbsDown,
      color: colors.expense,
      backgroundColor: colors.expenseSoft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final presentation = presentationForLevel(level, colors);
    final isLarge = size == FeelingChoiceButtonSize.large;

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, isLarge ? 72 : 34),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 8 : 12,
          vertical: isLarge ? 10 : 6,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: presentation.backgroundColor,
        foregroundColor: presentation.color,
        shape: isLarge
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            : const StadiumBorder(),
        textStyle: textTheme.labelSmall?.copyWith(
          fontSize: isLarge ? 12 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      child: isLarge
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.icon(
                  presentation.iconKey,
                  color: presentation.color,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    presentation.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.icon(
                  presentation.iconKey,
                  color: presentation.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    presentation.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
    );
  }
}
