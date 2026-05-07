import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingIllustration1 extends StatelessWidget {
  final double size;

  const OnboardingIllustration1({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/images/app_icon.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class OnboardingIllustration2 extends StatelessWidget {
  final double size;

  const OnboardingIllustration2({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BudgetTrackingPainter(),
      ),
    );
  }
}

class _BudgetTrackingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 10;
    final baseY = size.height * 0.75;
    final barWidth = unit * 1.0;
    final gap = unit * 0.6;

    final heights = [0.3, 0.55, 0.4, 0.7, 0.5];
    final colors = [
      const Color(0xFF00838F),
      const Color(0xFF00BCD4),
      const Color(0xFF00838F),
      const Color(0xFF00BCD4),
      const Color(0xFF00838F),
    ];

    final totalWidth = heights.length * barWidth + (heights.length - 1) * gap;
    final startX = (size.width - totalWidth) / 2;

    for (var i = 0; i < heights.length; i++) {
      final barHeight = size.height * 0.5 * heights[i];
      final x = startX + i * (barWidth + gap);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - barHeight, barWidth, barHeight),
        Radius.circular(unit * 0.2),
      );
      final barPaint = Paint()..color = colors[i];
      canvas.drawRRect(barRect, barPaint);
    }

    // Baseline
    final linePaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(startX - unit * 0.5, baseY),
      Offset(startX + totalWidth + unit * 0.5, baseY),
      linePaint,
    );

    // Checkmark circle
    final checkCenter = Offset(size.width * 0.72, size.height * 0.25);
    final checkRadius = unit * 1.2;
    final checkBgPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(checkCenter, checkRadius, checkBgPaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(checkCenter.dx - checkRadius * 0.35, checkCenter.dy)
      ..lineTo(checkCenter.dx - checkRadius * 0.05,
          checkCenter.dy + checkRadius * 0.3)
      ..lineTo(checkCenter.dx + checkRadius * 0.4,
          checkCenter.dy - checkRadius * 0.3);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingIllustration3 extends StatelessWidget {
  final double size;

  const OnboardingIllustration3({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _AiInsightsPainter(),
      ),
    );
  }
}

class _AiInsightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // Brain outline
    final brainRadius = unit * 2.5;
    final brainGradient = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF7C4DFF), Color(0xFF1A237E)],
      ).createShader(Rect.fromCircle(center: center, radius: brainRadius));
    canvas.drawCircle(center, brainRadius, brainGradient);

    // Brain line detail
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.12
      ..strokeCap = StrokeCap.round;

    final brainLine = Path()
      ..moveTo(center.dx, center.dy - brainRadius * 0.7)
      ..quadraticBezierTo(
        center.dx + brainRadius * 0.3,
        center.dy - brainRadius * 0.2,
        center.dx,
        center.dy + brainRadius * 0.1,
      )
      ..quadraticBezierTo(
        center.dx - brainRadius * 0.3,
        center.dy + brainRadius * 0.4,
        center.dx,
        center.dy + brainRadius * 0.7,
      );
    canvas.drawPath(brainLine, linePaint);

    // Sparkles/stars around the brain
    final sparklePaint = Paint()..color = const Color(0xFFFFD54F);
    final sparklePositions = [
      Offset(center.dx + brainRadius * 1.3, center.dy - brainRadius * 0.8),
      Offset(center.dx - brainRadius * 1.4, center.dy - brainRadius * 0.5),
      Offset(center.dx + brainRadius * 1.1, center.dy + brainRadius * 0.9),
      Offset(center.dx - brainRadius * 1.2, center.dy + brainRadius * 0.7),
      Offset(center.dx + brainRadius * 0.3, center.dy - brainRadius * 1.4),
      Offset(center.dx - brainRadius * 0.5, center.dy - brainRadius * 1.3),
    ];

    for (var i = 0; i < sparklePositions.length; i++) {
      final sparkleSize = unit * (0.2 + (i % 3) * 0.1);
      _drawSparkle(canvas, sparklePositions[i], sparkleSize, sparklePaint);
    }

    // Connection dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha: 0.6);
    final dotPositions = [
      Offset(center.dx - brainRadius * 1.0, center.dy),
      Offset(center.dx + brainRadius * 1.0, center.dy + brainRadius * 0.2),
      Offset(center.dx, center.dy + brainRadius * 1.3),
    ];
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, unit * 0.2, dotPaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerX = center.dx + math.cos(angle) * size;
      final outerY = center.dy + math.sin(angle) * size;
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * size * 0.3;
      final innerY = center.dy + math.sin(innerAngle) * size * 0.3;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
