import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
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
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.appBarClearHeroTop(context),
        AppLayout.screenPadding,
        28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft.withValues(alpha: 0.74),
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.82),
          ],
          stops: const [0, 0.5, 1],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.78)),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: 2,
            child: _HeroOrb(
              size: 108,
              color: colors.amberSoft.withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: 52,
            bottom: -32,
            child: _HeroOrb(
              size: 122,
              color: colors.navySoft.withValues(alpha: 0.8),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.58),
                  ),
                ),
                child: Icon(icon, color: colors.deepNavy, size: 23),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineLarge?.copyWith(
                        color: colors.deepNavy,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.34),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
