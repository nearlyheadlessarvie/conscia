import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'speed_dial_fab.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/', label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    (path: '/transactions', label: 'Transactions', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
    (path: '/assistant', label: 'Assistant', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome),
    (path: '/settings', label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/assistant')) return 2;
    if (location.startsWith('/transactions')) return 1;
    return 0;
  }

  bool _showFab(int index) => index == 0 || index == 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _selectedIndex(location);
    final isWide = MediaQuery.sizeOf(context).width > 840;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => context.go(_tabs[i].path),
              labelType: NavigationRailLabelType.all,
              leading: _showFab(currentIndex) ? const SpeedDialFab() : null,
              destinations: _tabs
                  .map((t) => NavigationRailDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.activeIcon),
                        label: Text(t.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      floatingActionButton: _showFab(currentIndex) ? const SpeedDialFab() : null,
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
