import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double percentage;

  const BudgetProgressBar({super.key, required this.percentage});

  Color _colorForPercentage(double pct) {
    if (pct >= 1.0) return const Color(0xFFE53935);
    if (pct >= 0.8) return const Color(0xFFFF9800);
    if (pct >= 0.5) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForPercentage(percentage);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percentage.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        );
      },
    );
  }
}
