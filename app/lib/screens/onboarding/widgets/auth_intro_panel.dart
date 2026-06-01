import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_colors.dart';

class AuthIntroPanel extends StatelessWidget {
  const AuthIntroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final AppIconKey icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
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
          Positioned.fill(
            child: CustomPaint(
              painter: _AuthHeroAtmospherePainter(
                warm: colors.amberSoft,
                cool: colors.navySoft,
              ),
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
                child: Center(
                  child: AppIcons.icon(
                    icon,
                    color: colors.deepNavy,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    if (action != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: action!,
                      ),
                    ],
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

class _AuthHeroAtmospherePainter extends CustomPainter {
  const _AuthHeroAtmospherePainter({
    required this.warm,
    required this.cool,
  });

  final Color warm;
  final Color cool;

  @override
  void paint(Canvas canvas, Size size) {
    final warmPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          warm.withValues(alpha: 0.48),
          warm.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.86, size.height * 0.18),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.18),
      size.width * 0.42,
      warmPaint,
    );

    final coolPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          cool.withValues(alpha: 0.28),
          cool.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.68),
          radius: size.width * 0.32,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.68),
      size.width * 0.32,
      coolPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthHeroAtmospherePainter oldDelegate) {
    return oldDelegate.warm != warm || oldDelegate.cool != cool;
  }
}
