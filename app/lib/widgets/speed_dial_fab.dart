import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_router.dart';

class SpeedDialFab extends StatelessWidget {
  const SpeedDialFab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: colors.secondary,
      foregroundColor: colors.onSecondary,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.photo_camera_outlined),
          label: 'Scan Receipt',
          onTap: () => context.push(AppRoutes.scan),
        ),
        SpeedDialChild(
          child: const Icon(Icons.auto_awesome_outlined),
          label: 'Ask Conscia',
          onTap: () => context.push(AppRoutes.assistant),
        ),
        SpeedDialChild(
          child: const Icon(Icons.payments_outlined),
          label: 'Add Expense',
          onTap: () => context.push(AppRoutes.addTransaction),
        ),
      ],
    );
  }
}
