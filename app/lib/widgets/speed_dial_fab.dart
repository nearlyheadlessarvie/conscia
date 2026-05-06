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
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming in a future update')),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.auto_awesome_outlined),
          label: 'Ask Conscia',
          onTap: () {
            try {
              context.push(AppRoutes.assistant);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            }
          },
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
