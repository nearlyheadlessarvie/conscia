import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static final _tabs = [
    (
      path: '/',
      label: 'Home',
      icon: AppIcons.home,
      activeIcon: AppIcons.homeActive,
    ),
    (
      path: '/transactions',
      label: 'Transactions',
      icon: AppIcons.transactions,
      activeIcon: AppIcons.transactionsActive,
    ),
    (
      path: '/scan',
      label: 'Scan',
      icon: AppIcons.scan,
      activeIcon: AppIcons.scan,
    ),
    (
      path: '/assistant',
      label: 'Assistant',
      icon: AppIcons.assistant,
      activeIcon: AppIcons.assistantActive,
    ),
    (
      path: '/settings',
      label: 'Settings',
      icon: AppIcons.settings,
      activeIcon: AppIcons.settingsActive,
    ),
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/assistant')) return 3;
    if (location.startsWith('/transactions')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _selectedIndex(location);
    final isWide = MediaQuery.sizeOf(context).width > 840;
    final colorScheme = Theme.of(context).colorScheme;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FloatingActionButton(
                  onPressed: () => context.push('/transactions/add'),
                  child: Icon(AppIcons.add),
                ),
              ),
              destinations: _tabs
                  .map(
                    (t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    ),
                  )
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: Icon(AppIcons.add),
      ),
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: _tabs
            .map(
              (t) => t.label == 'Scan'
                  ? NavigationDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t.icon,
                          size: 22,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t.activeIcon,
                          size: 22,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      label: t.label,
                    )
                  : NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: t.label,
                    ),
            )
            .toList(),
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 2) {
      context.push('/scan');
      return;
    }
    context.go(_tabs[index].path);
  }
}
