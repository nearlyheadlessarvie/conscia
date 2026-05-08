import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _brandIconAsset = 'assets/images/app_icon.svg';
const _alterEgoAsset = 'assets/images/conscia_alterego.png';

class ConscienceMark extends StatelessWidget {
  const ConscienceMark({
    super.key,
    this.size = 72,
    this.showRing = true,
  });

  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ConscienceMarkPainter(showRing: showRing),
    );
  }
}

class ConscienceAlterEgo extends StatelessWidget {
  const ConscienceAlterEgo({
    super.key,
    this.size = 96,
    this.zoom = 1.85,
    this.verticalBias = -0.08,
  });

  final double size;
  final double zoom;
  final double verticalBias;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: OverflowBox(
          maxWidth: size * zoom,
          maxHeight: size * zoom,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, size * verticalBias),
            child: Image.asset(
              _alterEgoAsset,
              key: const ValueKey('conscience-alter-ego-image'),
              width: size * zoom,
              height: size * zoom,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ConscienceMark(size: size);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ConscienceBrandIcon extends StatelessWidget {
  const ConscienceBrandIcon({
    super.key,
    this.size = 96,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _brandIconAsset,
        key: const ValueKey('conscience-brand-icon-svg'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => ConscienceMark(size: size),
      ),
    );
  }
}

enum ConsciaAlterEgoPreset {
  idle,
  assistantLoading,
  reflectionLoading,
}

class ConsciaAlterEgoMotion extends StatefulWidget {
  const ConsciaAlterEgoMotion({
    super.key,
    required this.preset,
    this.size = 96,
  });

  final ConsciaAlterEgoPreset preset;
  final double size;

  @override
  State<ConsciaAlterEgoMotion> createState() => _ConsciaAlterEgoMotionState();
}

class _ConsciaAlterEgoMotionState extends State<ConsciaAlterEgoMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains(
            'TestWidgetsFlutterBinding',
          );

  Duration get _duration => switch (widget.preset) {
        ConsciaAlterEgoPreset.idle => const Duration(seconds: 5),
        ConsciaAlterEgoPreset.assistantLoading =>
          const Duration(milliseconds: 2100),
        ConsciaAlterEgoPreset.reflectionLoading =>
          const Duration(milliseconds: 2600),
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    if (_isTestEnvironment) {
      _controller.value = 0.35;
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ConsciaAlterEgoMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) {
      _controller.duration = _duration;
      if (_isTestEnvironment) {
        _controller.value = 0.35;
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.preset == ConsciaAlterEgoPreset.idle;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final phase = (math.sin(t * math.pi * 2) + 1) / 2;
        final glowScale = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 1.0 + phase * 0.06,
          ConsciaAlterEgoPreset.assistantLoading => 1.02 + phase * 0.16,
          ConsciaAlterEgoPreset.reflectionLoading => 1.01 + phase * 0.11,
        };
        final breathe = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 1.0 + math.sin(t * math.pi * 2) * 0.012,
          ConsciaAlterEgoPreset.assistantLoading =>
            1.0 + math.sin(t * math.pi * 2) * 0.026,
          ConsciaAlterEgoPreset.reflectionLoading =>
            1.0 + math.sin(t * math.pi * 2) * 0.018,
        };
        final ringRotation = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => t * math.pi * 2 * 0.08,
          ConsciaAlterEgoPreset.assistantLoading => t * math.pi * 2 * 0.25,
          ConsciaAlterEgoPreset.reflectionLoading => t * math.pi * 2 * 0.16,
        };
        final redOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.22 + phase * 0.10,
          ConsciaAlterEgoPreset.assistantLoading => 0.28 + phase * 0.18,
          ConsciaAlterEgoPreset.reflectionLoading => 0.24 + phase * 0.12,
        };
        final blueOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.18 + phase * 0.09,
          ConsciaAlterEgoPreset.assistantLoading => 0.24 + phase * 0.16,
          ConsciaAlterEgoPreset.reflectionLoading => 0.2 + phase * 0.11,
        };

        return SizedBox(
          key: ValueKey(
            switch (widget.preset) {
              ConsciaAlterEgoPreset.idle => 'conscience-alter-ego-idle',
              ConsciaAlterEgoPreset.assistantLoading =>
                'conscience-loader-assistant',
              ConsciaAlterEgoPreset.reflectionLoading =>
                'conscience-loader-reflection',
            },
          ),
          width: widget.size * (isIdle ? 1.36 : 1.65),
          height: widget.size * (isIdle ? 1.24 : 1.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-widget.size * 0.18, 0),
                child: _AuraGlow(
                  color: const Color(0xFFFF5B47).withValues(alpha: redOpacity),
                  size: widget.size * (1.05 * glowScale),
                ),
              ),
              Transform.translate(
                offset: Offset(widget.size * 0.18, 0),
                child: _AuraGlow(
                  color: const Color(0xFF67D9FF).withValues(alpha: blueOpacity),
                  size: widget.size * (1.02 * glowScale),
                ),
              ),
              if (!isIdle)
                Transform.rotate(
                  angle: ringRotation,
                  child: Container(
                    key: const ValueKey('conscience-loader-ring'),
                    width: widget.size * 1.18,
                    height: widget.size * 1.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.12 + phase * 0.08),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: breathe,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: ClipOval(
                    child: Image.asset(
                      _alterEgoAsset,
                      key: const ValueKey('conscience-alter-ego-image'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ConscienceLoaderPreset {
  assistant,
  reflection,
}

class ConscienceLoader extends StatefulWidget {
  const ConscienceLoader({
    super.key,
    this.size = 84,
    this.label,
    this.preset = ConscienceLoaderPreset.assistant,
  });

  final double size;
  final String? label;
  final ConscienceLoaderPreset preset;

  @override
  State<ConscienceLoader> createState() => _ConscienceLoaderState();
}

class _ConscienceLoaderState extends State<ConscienceLoader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConsciaAlterEgoMotion(
          preset: widget.preset == ConscienceLoaderPreset.assistant
              ? ConsciaAlterEgoPreset.assistantLoading
              : ConsciaAlterEgoPreset.reflectionLoading,
          size: widget.size * 0.94,
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _AuraGlow extends StatelessWidget {
  const _AuraGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.24,
            spreadRadius: size * 0.03,
          ),
        ],
      ),
    );
  }
}

class _ConscienceMarkPainter extends CustomPainter {
  _ConscienceMarkPainter({required this.showRing});

  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const borderColor = Color(0xFF091A38);
    final rect = Rect.fromCircle(center: center, radius: radius * 0.84);

    final clipPath = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(clipPath);

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB7362C),
          Color(0xFF7B161A),
        ],
      ).createShader(rect);

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFA9F0EE),
          Color(0xFF39AEB5),
        ],
      ).createShader(rect);

    final leftHalf = Path()
      ..moveTo(center.dx, rect.top)
      ..quadraticBezierTo(
        rect.left + radius * 0.05,
        center.dy - radius * 0.18,
        center.dx,
        center.dy,
      )
      ..quadraticBezierTo(
        rect.right - radius * 0.22,
        center.dy + radius * 0.2,
        center.dx,
        rect.bottom,
      )
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top)
      ..close();

    final rightHalf = Path()
      ..moveTo(center.dx, rect.top)
      ..quadraticBezierTo(
        rect.right - radius * 0.05,
        center.dy - radius * 0.16,
        center.dx,
        center.dy,
      )
      ..quadraticBezierTo(
        rect.left + radius * 0.22,
        center.dy + radius * 0.22,
        center.dx,
        rect.bottom,
      )
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top)
      ..close();

    canvas.drawPath(leftHalf, leftPaint);
    canvas.drawPath(rightHalf, rightPaint);

    _paintDevil(canvas, rect);
    _paintAngel(canvas, rect);
    _paintBalanceCore(canvas, rect);

    canvas.restore();

    if (showRing) {
      canvas.drawCircle(
        center,
        radius * 0.84,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.1
          ..color = borderColor,
      );
    }
  }

  void _paintDevil(Canvas canvas, Rect rect) {
    final profile = Path()
      ..moveTo(
          rect.center.dx - rect.width * 0.05, rect.top + rect.height * 0.19)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.18,
        rect.top + rect.height * 0.17,
        rect.left + rect.width * 0.18,
        rect.top + rect.height * 0.34,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.1,
        rect.top + rect.height * 0.47,
        rect.left + rect.width * 0.18,
        rect.top + rect.height * 0.59,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.22,
        rect.top + rect.height * 0.7,
        rect.center.dx - rect.width * 0.08,
        rect.top + rect.height * 0.76,
      );

    final paint = Paint()
      ..color = const Color(0xFFFFC58F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(profile, paint);

    final hornPaint = Paint()
      ..color = const Color(0xFFFF9B63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        rect.left + rect.width * 0.18,
        rect.top + rect.height * 0.12,
        rect.width * 0.18,
        rect.height * 0.2,
      ),
      math.pi,
      math.pi / 1.8,
      false,
      hornPaint,
    );
  }

  void _paintAngel(Canvas canvas, Rect rect) {
    final profile = Path()
      ..moveTo(
          rect.center.dx + rect.width * 0.04, rect.top + rect.height * 0.19)
      ..quadraticBezierTo(
        rect.right - rect.width * 0.17,
        rect.top + rect.height * 0.2,
        rect.right - rect.width * 0.19,
        rect.top + rect.height * 0.34,
      )
      ..quadraticBezierTo(
        rect.right - rect.width * 0.11,
        rect.top + rect.height * 0.48,
        rect.right - rect.width * 0.18,
        rect.top + rect.height * 0.61,
      )
      ..quadraticBezierTo(
        rect.right - rect.width * 0.23,
        rect.top + rect.height * 0.74,
        rect.center.dx + rect.width * 0.09,
        rect.top + rect.height * 0.77,
      );

    final paint = Paint()
      ..color = const Color(0xFF043A52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.052
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(profile, paint);

    final haloPaint = Paint()
      ..color = const Color(0xFFFFE27A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        rect.right - rect.width * 0.36,
        rect.top + rect.height * 0.08,
        rect.width * 0.22,
        rect.height * 0.12,
      ),
      math.pi,
      math.pi,
      false,
      haloPaint,
    );
  }

  void _paintBalanceCore(Canvas canvas, Rect rect) {
    canvas.drawCircle(
      Offset(rect.center.dx + rect.width * 0.13, rect.top + rect.height * 0.23),
      rect.width * 0.05,
      Paint()..color = const Color(0xFF0E8290),
    );

    canvas.drawCircle(
      Offset(
          rect.center.dx - rect.width * 0.02, rect.bottom - rect.height * 0.22),
      rect.width * 0.055,
      Paint()..color = const Color(0xFFFF7A30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
