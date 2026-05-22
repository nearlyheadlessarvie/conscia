import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'floating_dock_nav.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  String? _lastLocation;
  bool _dockVisible = true;
  double _downwardScrollAccumulation = 0;
  double _upwardScrollAccumulation = 0;

  static const _hideDockThreshold = 32.0;
  static const _showDockThreshold = 12.0;
  static const _edgeHideThreshold = 8.0;

  static final _tabs = [
    (
      path: '/',
      label: 'Home',
    ),
    (
      path: '/transactions',
      label: 'Transactions',
    ),
    (
      path: '/scan',
      label: 'Scan',
    ),
    (
      path: '/assistant',
      label: 'Assistant',
    ),
    (
      path: '/settings',
      label: 'Settings',
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final dockShown = _dockVisible && !keyboardOpen;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: widget.child,
            ),
          ),
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
            child: IgnorePointer(
              ignoring: !dockShown,
              child: AnimatedSlide(
                key: const ValueKey('main-shell-dock-motion'),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: dockShown ? Offset.zero : const Offset(0, 1.35),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  opacity: dockShown ? 1 : 0,
                  child: FloatingDockNav(
                    currentIndex: currentIndex,
                    onDestinationSelected: (index) =>
                        _onDestinationSelected(context, index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels <= 0) {
      _setDockVisible(true);
      _resetScrollAccumulation();
      return false;
    }

    final delta = notification is ScrollUpdateNotification
        ? notification.scrollDelta ?? 0
        : 0.0;
    if (delta > 0) {
      _downwardScrollAccumulation += delta;
      _upwardScrollAccumulation = 0;
      final reachedLowerEdge =
          notification.metrics.extentAfter <= _edgeHideThreshold;
      if (_downwardScrollAccumulation >= _hideDockThreshold ||
          reachedLowerEdge) {
        _setDockVisible(false);
        _downwardScrollAccumulation = 0;
      }
    } else if (delta < 0) {
      _upwardScrollAccumulation += -delta;
      _downwardScrollAccumulation = 0;
      if (_upwardScrollAccumulation >= _showDockThreshold) {
        _setDockVisible(true);
        _upwardScrollAccumulation = 0;
      }
    }

    return false;
  }

  void _setDockVisible(bool visible) {
    if (_dockVisible == visible) return;
    setState(() => _dockVisible = visible);
  }

  void _resetScrollAccumulation() {
    _downwardScrollAccumulation = 0;
    _upwardScrollAccumulation = 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 2) {
      context.push('/scan');
      return;
    }
    context.go(_tabs[index].path);
  }
}
