import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';

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
      floatingActionButton: showSharedAddFab
          ? FloatingActionButton(
              onPressed: () => context.push('/transactions/add'),
              child: Icon(AppIcons.add),
            )
          : null,
      bottomNavigationBar: SizedBox(
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 10,
              child: NavigationBar(
                height: 80,
                selectedIndex: currentIndex,
                onDestinationSelected: (i) {
                  if (i == _mobileScanIndex) return;
                  _onDestinationSelected(context, i);
                },
                destinations: _tabs
                    .map(
                      (t) => t.label == 'Scan'
                          ? const NavigationDestination(
                              icon: SizedBox.shrink(),
                              selectedIcon: SizedBox.shrink(),
                              label: '',
                            )
                          : NavigationDestination(
                              icon: Icon(t.icon),
                              selectedIcon: Icon(t.activeIcon),
                              label: t.label,
                            ),
                    )
                    .toList(),
              ),
            ),
            Positioned(
              top: -8,
              child: _RaisedScanButton(
                key: const ValueKey('main-shell-scan-button'),
                isSelected: currentIndex == _mobileScanIndex,
                onTap: () => _onDestinationSelected(context, _mobileScanIndex),
              ),
            ),
          ],
        ),
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

class _RaisedScanButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RaisedScanButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 4,
                  ),
                ),
                child: Icon(
                  AppIcons.scan,
                  size: 28,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Scan',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
