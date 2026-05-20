import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../widgets/conscience_mark.dart';

class ConsciaSvgLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const ConsciaSvgLogo({
    super.key,
    required this.size,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalHeight = showText ? size + 32 : size;
    return SizedBox(
      width: size,
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF091A38).withValues(alpha: 0.08),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.04),
                ),
              ],
            ),
            child: ConscienceMark(
              size: size,
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 8),
            Text(
              'Conscia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: size * 0.14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A237E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ImpulseFaceIcon extends StatelessWidget {
  final double size;

  const ImpulseFaceIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ImpulseFacePainter(),
    );
  }
}

class _ImpulseFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Orange-red gradient circle
    final gradient = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFB300), Color(0xFFE65100)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradient);

    // Horn silhouette
    final hornPaint = Paint()..color = const Color(0xFFBF360C);
    final hornPath = Path()
      ..moveTo(center.dx - radius * 0.25, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 1.25)
      ..lineTo(center.dx + radius * 0.05, center.dy - radius * 0.8)
      ..close();
    canvas.drawPath(hornPath, hornPaint);

    // Second horn
    final horn2Path = Path()
      ..moveTo(center.dx + radius * 0.05, center.dy - radius * 0.8)
      ..lineTo(center.dx + radius * 0.2, center.dy - radius * 1.25)
      ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.8)
      ..close();
    canvas.drawPath(horn2Path, hornPaint);

    // Simple face - eyes
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
      radius * 0.12,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
      radius * 0.12,
      eyePaint,
    );

    // Smirk
    final smirkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;
    final smirkPath = Path()
      ..moveTo(center.dx - radius * 0.2, center.dy + radius * 0.3)
      ..quadraticBezierTo(
        center.dx + radius * 0.1,
        center.dy + radius * 0.55,
        center.dx + radius * 0.3,
        center.dy + radius * 0.2,
      );
    canvas.drawPath(smirkPath, smirkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReasonFaceIcon extends StatelessWidget {
  final double size;

  const ReasonFaceIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ReasonFacePainter(),
    );
  }
}

class _ReasonFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Teal gradient circle
    final gradient = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradient);

    // Halo arc
    final haloPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    final haloRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius * 1.05),
      width: radius * 0.9,
      height: radius * 0.35,
    );
    canvas.drawArc(haloRect, math.pi, math.pi, false, haloPaint);

    // Simple face - eyes
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
      radius * 0.12,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
      radius * 0.12,
      eyePaint,
    );

    // Gentle smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(center.dx - radius * 0.25, center.dy + radius * 0.25)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.5,
        center.dx + radius * 0.25,
        center.dy + radius * 0.25,
      );
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
