import 'dart:math' as math;
import 'package:flutter/material.dart';

class NoTransactionsIllustration extends StatelessWidget {
  final double size;

  const NoTransactionsIllustration({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NoTransactionsPainter(),
      ),
    );
  }
}

class _NoTransactionsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // Receipt body
    final receiptWidth = unit * 4.5;
    final receiptHeight = unit * 6.0;
    final receiptRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: receiptWidth, height: receiptHeight),
      Radius.circular(unit * 0.3),
    );
    final receiptPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.08);
    canvas.drawRRect(receiptRect, receiptPaint);

    // Receipt border
    final borderPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(receiptRect, borderPaint);

    // Receipt lines
    final linePaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.15)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.2;
    for (var i = 0; i < 4; i++) {
      final y = center.dy - receiptHeight * 0.25 + i * unit * 1.0;
      final lineWidth = (i % 2 == 0) ? receiptWidth * 0.6 : receiptWidth * 0.4;
      canvas.drawLine(
        Offset(center.dx - receiptWidth * 0.3, y),
        Offset(center.dx - receiptWidth * 0.3 + lineWidth, y),
        linePaint,
      );
    }

    // Plus overlay circle
    final plusCenter = Offset(center.dx + unit * 2.0, center.dy + unit * 2.0);
    final plusRadius = unit * 1.3;
    final plusBgPaint = Paint()..color = const Color(0xFF00BCD4);
    canvas.drawCircle(plusCenter, plusRadius, plusBgPaint);

    // Plus sign
    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = unit * 0.25
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(plusCenter.dx - plusRadius * 0.45, plusCenter.dy),
      Offset(plusCenter.dx + plusRadius * 0.45, plusCenter.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(plusCenter.dx, plusCenter.dy - plusRadius * 0.45),
      Offset(plusCenter.dx, plusCenter.dy + plusRadius * 0.45),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NoBudgetsIllustration extends StatelessWidget {
  final double size;

  const NoBudgetsIllustration({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NoBudgetsPainter(),
      ),
    );
  }
}

class _NoBudgetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;

    // Outer circle (dotted)
    final dashPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const dashCount = 24;
    const dashLength = 0.18;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweepAngle = dashLength;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        dashPaint,
      );
    }

    // Pie segments (outlines only)
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final segments = [
      (0.0, 2.2, const Color(0xFFE65100).withValues(alpha: 0.4)),
      (2.2, 1.8, const Color(0xFF00BCD4).withValues(alpha: 0.4)),
      (4.0, 2.28, const Color(0xFF1A237E).withValues(alpha: 0.3)),
    ];

    for (final (start, sweep, color) in segments) {
      segmentPaint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.75),
        start,
        sweep,
        false,
        segmentPaint,
      );
    }

    // Divider lines from center
    final dividerPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    const angles = [0.0, 2.2, 4.0];
    for (final angle in angles) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * radius * 0.75,
          center.dy + math.sin(angle) * radius * 0.75,
        ),
        dividerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NoMessagesIllustration extends StatelessWidget {
  final double size;

  const NoMessagesIllustration({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NoMessagesPainter(),
      ),
    );
  }
}

class _NoMessagesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final unit = size.width / 10;

    // Chat bubble
    final bubbleWidth = unit * 6.0;
    final bubbleHeight = unit * 4.0;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: bubbleWidth, height: bubbleHeight),
      Radius.circular(unit * 0.8),
    );
    final bubblePaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.08);
    canvas.drawRRect(bubbleRect, bubblePaint);

    // Bubble border
    final borderPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Bubble tail
    final tailPath = Path()
      ..moveTo(center.dx - unit * 0.8, center.dy + bubbleHeight / 2 - 1)
      ..lineTo(
          center.dx - unit * 1.2, center.dy + bubbleHeight / 2 + unit * 1.0)
      ..lineTo(center.dx - unit * 0.1, center.dy + bubbleHeight / 2 - 1)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFF1A237E).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Three dots "..."
    final dotPaint = Paint()
      ..color = const Color(0xFF1A237E).withValues(alpha: 0.3);
    final dotRadius = unit * 0.35;
    final dotSpacing = unit * 1.2;
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(center.dx + i * dotSpacing, center.dy),
        dotRadius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
