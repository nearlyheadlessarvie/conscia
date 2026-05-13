import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

class FloatingDockNav extends StatelessWidget {
  const FloatingDockNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _scanIndex = 2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Container(
          key: const ValueKey('floating-dock-nav'),
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F18245C),
                blurRadius: 36,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DockIconButton(
                index: 0,
                currentIndex: currentIndex,
                icon: AppIcons.home,
                activeIcon: AppIcons.homeActive,
                onTap: onDestinationSelected,
              ),
              _DockIconButton(
                index: 1,
                currentIndex: currentIndex,
                icon: AppIcons.transactions,
                activeIcon: AppIcons.transactionsActive,
                onTap: onDestinationSelected,
              ),
              _ScanDockButton(
                isSelected: currentIndex == _scanIndex,
                onTap: () => onDestinationSelected(_scanIndex),
              ),
              _DockIconButton(
                index: 3,
                currentIndex: currentIndex,
                icon: AppIcons.assistant,
                activeIcon: AppIcons.assistantActive,
                onTap: onDestinationSelected,
              ),
              _DockIconButton(
                index: 4,
                currentIndex: currentIndex,
                icon: AppIcons.settings,
                activeIcon: AppIcons.settingsActive,
                onTap: onDestinationSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final selected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('floating-dock-item-$index'),
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? colors.navySoft : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected ? colors.deepNavy : colors.softInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanDockButton extends StatelessWidget {
  const _ScanDockButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('floating-dock-scan-action'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.deepNavy,
            boxShadow: [
              BoxShadow(
                color:
                    colors.deepNavy.withValues(alpha: isSelected ? 0.28 : 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            AppIcons.scan,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
