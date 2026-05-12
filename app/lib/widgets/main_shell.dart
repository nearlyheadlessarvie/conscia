import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';
import 'floating_dock_nav.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  String? _lastLocation;

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

  static const _mobileScanIndex = 2;

  int _selectedIndex(String location) {
    if (location.startsWith('/scan')) return _mobileScanIndex;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/assistant')) return 3;
    if (location.startsWith('/transactions')) return 1;
    return 0;
  }

  bool _showSharedAddFab(String location) {
    return !location.startsWith('/transactions') &&
        !location.startsWith('/assistant') &&
        !location.startsWith('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (_lastLocation != null && _lastLocation != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route is! PopupRoute);
      });
    }
    _lastLocation = location;
    final currentIndex = _selectedIndex(location);
    final isWide = MediaQuery.sizeOf(context).width > 840;
    final showSharedAddFab = _showSharedAddFab(location);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              labelType: NavigationRailLabelType.all,
              leading: showSharedAddFab
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FloatingActionButton(
                        onPressed: () => context.push('/transactions/add'),
                        child: Icon(AppIcons.add),
                      ),
                    )
                  : null,
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
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: FloatingDockNav(
        currentIndex: currentIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
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
