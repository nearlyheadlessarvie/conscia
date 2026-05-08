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

class ConscienceLoader extends StatefulWidget {
  const ConscienceLoader({
    super.key,
    this.size = 84,
    this.label,
  });

  final double size;
  final String? label;

  @override
  State<ConscienceLoader> createState() => _ConscienceLoaderState();
}

class _ConscienceLoaderState extends State<ConscienceLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final pulse = (math.sin(t * math.pi * 2) + 1) / 2;
        final breathe = 1 + math.sin(t * math.pi * 2) * 0.025;
        final ringRotation = t * math.pi * 2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size * 1.82,
              height: widget.size * 1.58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(-widget.size * 0.16, 0),
                    child: _AuraGlow(
                      color: const Color(0x66FF4B3A),
                      size: widget.size * (1.34 + pulse * 0.10),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(widget.size * 0.16, 0),
                    child: _AuraGlow(
                      color: const Color(0x6656D6FF),
                      size: widget.size * (1.34 + pulse * 0.10),
                    ),
                  ),
                  Transform.rotate(
                    angle: ringRotation * 0.22,
                    child: Container(
                      key: const ValueKey('conscience-loader-ring'),
                      width: widget.size * 1.2,
                      height: widget.size * 1.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.outlineVariant.withValues(
                            alpha: 0.14 + pulse * 0.10,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: breathe,
                    child: ConscienceBrandIcon(
                      size: widget.size * 0.8,
                    ),
                  ),
                ],
              ),
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
      },
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
