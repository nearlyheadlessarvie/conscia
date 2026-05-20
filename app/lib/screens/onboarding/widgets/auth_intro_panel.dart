import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthIntroPanel extends StatelessWidget {
  const AuthIntroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft.withValues(alpha: 0.68),
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.76),
          ],
          stops: const [0, 0.52, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border.withValues(alpha: 0.74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.surfaceRaised.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colors.deepNavy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.deepNavy,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
