import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/editorial_hero_chip.dart';

class InsightListEditorialHero extends StatelessWidget {
  const InsightListEditorialHero({
    super.key,
    required this.leading,
    required this.label,
    required this.primary,
    required this.body,
    required this.chips,
    this.topPadding = 44,
    this.bleed = false,
  });

  final Widget leading;
  final String label;
  final String primary;
  final String body;
  final List<String> chips;
  final double topPadding;
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceRaised,
            colors.navySoft,
            colors.amberSoft,
          ],
        ),
        borderRadius: bleed
            ? const BorderRadius.vertical(bottom: Radius.circular(28))
            : BorderRadius.circular(28),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topPadding, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.deepNavy,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        primary,
                        style: textTheme.displaySmall?.copyWith(
                          color: colors.deepNavy,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips)
                  EditorialHeroChip(
                    label: chip,
                    horizontalPadding: 10,
                    verticalPadding: 7,
                    letterSpacing: 0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
