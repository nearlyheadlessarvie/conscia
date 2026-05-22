import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';
import '../core/routing/app_router.dart';

class SpeedDialFab extends StatelessWidget {
  const SpeedDialFab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SpeedDial(
      child: AppIcons.icon(
        AppIconKey.add,
        color: colors.onSecondary,
        size: 24,
      ),
      activeChild: AppIcons.icon(
        AppIconKey.close,
        color: colors.onSecondary,
        size: 24,
      ),
      backgroundColor: colors.secondary,
      foregroundColor: colors.onSecondary,
      children: [
        SpeedDialChild(
          child: AppIcons.icon(
            AppIconKey.camera,
            color: colors.onSurface,
            size: 20,
          ),
          label: 'Scan Receipt',
          onTap: () => context.push(AppRoutes.scan),
        ),
        SpeedDialChild(
          child: AppIcons.icon(
            AppIconKey.ai,
            color: colors.onSurface,
            size: 20,
          ),
          label: 'Ask Conscia',
          onTap: () => context.push(AppRoutes.assistant),
        ),
        SpeedDialChild(
          child: AppIcons.icon(
            AppIconKey.payments,
            color: colors.onSurface,
            size: 20,
          ),
          label: 'Add Expense',
          onTap: () => context.push(AppRoutes.addTransaction),
        ),
      ],
    );
  }
}
