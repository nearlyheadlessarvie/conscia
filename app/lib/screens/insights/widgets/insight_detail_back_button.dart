import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class InsightDetailBackButton extends StatelessWidget {
  const InsightDetailBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: AppIcons.icon(
        AppIconKey.chevronLeft,
        color: colors.deepNavy,
        size: 28,
      ),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
