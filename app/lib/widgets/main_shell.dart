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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  key: const ValueKey('main-shell-dock-overlay'),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingDockNav(
              currentIndex: currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
          ),
        ],
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
