import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LevelUpConfetti extends StatefulWidget {
  const LevelUpConfetti({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  State<LevelUpConfetti> createState() => _LevelUpConfettiState();
}

class _LevelUpConfettiState extends State<LevelUpConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox.expand(
            key: const ValueKey('journey-level-up-confetti'),
            child: CustomPaint(
              painter: _LevelUpConfettiPainter(
                progress: _controller.value,
                colors: _confettiColors(Theme.of(context).appColors),
                compact: widget.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ConfettiShape { paper, streamer }

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.seed,
    required this.lane,
    required this.size,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.delay,
    required this.opacity,
    required this.shape,
    required this.colorIndex,
  });

  final double seed;
  final double lane;
  final double size;
  final double speed;
  final double drift;
  final double rotation;
  final double delay;
  final double opacity;
  final _ConfettiShape shape;
  final int colorIndex;
}

List<Color> _confettiColors(AppColors colors) {
  return [
    colors.amber,
    colors.family,
    colors.deepNavy.withValues(alpha: 0.82),
    colors.income,
    const Color(0xFF6D7CF7),
    const Color(0xFF57A8E6),
  ];
}

List<_ConfettiParticle> _particlesFor(bool compact) {
  final count = compact ? 22 : 34;
  return List<_ConfettiParticle>.generate(count, (index) {
    final base = index + 1;
    final seed = ((base * 37) % 100) / 100;
    final lane = ((base * 19) % 100) / 100;
    return _ConfettiParticle(
      seed: seed,
      lane: lane,
      size: compact
          ? 8 + ((base * 5) % 7).toDouble()
          : 9 + ((base * 7) % 9).toDouble(),
      speed: 0.82 + (((base * 11) % 17) / 100),
      drift: compact
          ? 8 + ((base * 13) % 18).toDouble()
          : 12 + ((base * 17) % 22).toDouble(),
      rotation: 0.5 + (((base * 23) % 18) / 10),
      delay: ((base * 29) % 100) / 100,
      opacity: 0.34 + (((base * 31) % 32) / 100),
      shape: base.isEven ? _ConfettiShape.paper : _ConfettiShape.streamer,
      colorIndex: base % 6,
    );
  });
}

class _LevelUpConfettiPainter extends CustomPainter {
  const _LevelUpConfettiPainter({
    required this.progress,
    required this.colors,
    required this.compact,
  });

  final double progress;
  final List<Color> colors;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final clipHeight = size.height * 0.56;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));

    for (final particle in _particlesFor(compact)) {
      final local = (progress + particle.delay) % 1.0;
      final fallProgress = math.min(local * particle.speed, 1.0);
      final y = ui.lerpDouble(-42, clipHeight + 40, fallProgress)!;
      final x = size.width * (0.1 + particle.lane * 0.8) +
          math.sin((local + particle.seed) * math.pi * 2) * particle.drift;
      final angle = (local * particle.rotation * math.pi * 2) + particle.seed;
      final fade = (1 - (fallProgress * 0.55)).clamp(0.18, 1.0);
      final color =
          colors[particle.colorIndex].withValues(alpha: particle.opacity * fade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      if (particle.shape == _ConfettiShape.paper) {
        final paperPaint = Paint()..color = color;
        final width = particle.size;
        final height = particle.size * 0.68;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: height,
            ),
            Radius.circular(height * 0.28),
          ),
          paperPaint,
        );
      } else {
        final streamerPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = compact ? 1.8 : 2.1
          ..strokeCap = StrokeCap.round;
        final length = particle.size * 1.8;
        final path = Path()
          ..moveTo(-length * 0.5, -particle.size * 0.16)
          ..quadraticBezierTo(
            -length * 0.08,
            particle.size * 0.5,
            length * 0.18,
            -particle.size * 0.08,
          )
          ..quadraticBezierTo(
            length * 0.4,
            -particle.size * 0.45,
            length * 0.5,
            particle.size * 0.18,
          );
        canvas.drawPath(path, streamerPaint);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LevelUpConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.compact != compact ||
        oldDelegate.colors != colors;
  }
}
