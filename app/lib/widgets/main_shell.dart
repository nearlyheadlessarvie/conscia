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

  static const _mobileScanIndex = 2;

  int _selectedIndex(String location) {
    if (location.startsWith('/scan')) return _mobileScanIndex;
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
      bottomNavigationBar: SizedBox(
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 20,
              child: NavigationBar(
                height: 80,
                selectedIndex: currentIndex == _mobileScanIndex ? 0 : currentIndex,
                onDestinationSelected: (i) {
                  final mappedIndex = i >= _mobileScanIndex ? i + 1 : i;
                  _onDestinationSelected(context, mappedIndex);
                },
                destinations: _tabs
                    .where((t) => t.label != 'Scan')
                    .map(
                      (t) => NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.activeIcon),
                        label: t.label,
                      ),
                    )
                    .toList(),
              ),
            ),
            Positioned(
              top: 0,
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
          padding: const EdgeInsets.only(top: 2),
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
              const SizedBox(height: 4),
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
