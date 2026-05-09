import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _brandIconAsset = 'assets/images/app_icon.svg';
const _alterEgoAsset = 'assets/images/conscia_alterego.png';
const _angelAssetDirectory = 'assets/images/angel';
const _devilAssetDirectory = 'assets/images/devil';
const _moneyAssetDirectory = 'assets/images/money';

enum _CharacterPose { neutral, push, block }

enum _MoneyPose { neutral, left, right, shake }

String _characterPoseAsset(String directory, _CharacterPose pose) =>
    '$directory/${pose.name}.png';

String _moneyPoseAsset(_MoneyPose pose) =>
    '$_moneyAssetDirectory/${pose.name}.png';

class _BattleFrame {
  const _BattleFrame({
    required this.devilPose,
    required this.angelPose,
    required this.moneyPose,
  });

  final _CharacterPose devilPose;
  final _CharacterPose angelPose;
  final _MoneyPose moneyPose;
}

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

  _BattleFrame _frameForPreset(ConsciaAlterEgoPreset preset, double t) {
    return switch (preset) {
      ConsciaAlterEgoPreset.idle => const _BattleFrame(
          devilPose: _CharacterPose.neutral,
          angelPose: _CharacterPose.neutral,
          moneyPose: _MoneyPose.neutral,
        ),
      ConsciaAlterEgoPreset.assistantLoading => t < 0.28
          ? const _BattleFrame(
              devilPose: _CharacterPose.push,
              angelPose: _CharacterPose.block,
              moneyPose: _MoneyPose.left,
            )
          : t < 0.58
              ? const _BattleFrame(
                  devilPose: _CharacterPose.push,
                  angelPose: _CharacterPose.push,
                  moneyPose: _MoneyPose.shake,
                )
              : t < 0.82
                  ? const _BattleFrame(
                      devilPose: _CharacterPose.block,
                      angelPose: _CharacterPose.push,
                      moneyPose: _MoneyPose.right,
                    )
                  : const _BattleFrame(
                      devilPose: _CharacterPose.neutral,
                      angelPose: _CharacterPose.neutral,
                      moneyPose: _MoneyPose.neutral,
                    ),
      ConsciaAlterEgoPreset.reflectionLoading => t < 0.42
          ? const _BattleFrame(
              devilPose: _CharacterPose.neutral,
              angelPose: _CharacterPose.block,
              moneyPose: _MoneyPose.neutral,
            )
          : t < 0.72
              ? const _BattleFrame(
                  devilPose: _CharacterPose.block,
                  angelPose: _CharacterPose.push,
                  moneyPose: _MoneyPose.shake,
                )
              : const _BattleFrame(
                  devilPose: _CharacterPose.neutral,
                  angelPose: _CharacterPose.neutral,
                  moneyPose: _MoneyPose.neutral,
                ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.preset == ConsciaAlterEgoPreset.idle;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final frame = _frameForPreset(widget.preset, t);
        final phase = (math.sin(t * math.pi * 2) + 1) / 2;
        final glowScale = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 1.0 + phase * 0.05,
          ConsciaAlterEgoPreset.assistantLoading => 1.04 + phase * 0.2,
          ConsciaAlterEgoPreset.reflectionLoading => 1.02 + phase * 0.12,
        };
        final breathe = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 1.0 + math.sin(t * math.pi * 2) * 0.01,
          ConsciaAlterEgoPreset.assistantLoading =>
            1.0 + math.sin(t * math.pi * 2) * 0.03,
          ConsciaAlterEgoPreset.reflectionLoading =>
            1.0 + math.sin(t * math.pi * 2) * 0.018,
        };
        final ringRotation = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.0,
          ConsciaAlterEgoPreset.assistantLoading => t * math.pi * 2 * 0.16,
          ConsciaAlterEgoPreset.reflectionLoading => t * math.pi * 2 * 0.08,
        };
        final shimmerRotation = math.sin(t * math.pi * 2) * 0.03;
        final redOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.22 + phase * 0.08,
          ConsciaAlterEgoPreset.assistantLoading => 0.28 + phase * 0.16,
          ConsciaAlterEgoPreset.reflectionLoading => 0.23 + phase * 0.1,
        };
        final blueOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.2 + phase * 0.07,
          ConsciaAlterEgoPreset.assistantLoading => 0.25 + phase * 0.14,
          ConsciaAlterEgoPreset.reflectionLoading => 0.21 + phase * 0.09,
        };
        final goldOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.18 + phase * 0.06,
          ConsciaAlterEgoPreset.assistantLoading => 0.24 + phase * 0.1,
          ConsciaAlterEgoPreset.reflectionLoading => 0.2 + phase * 0.07,
        };
        final devilOffset = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle =>
            Offset(-widget.size * 0.23, -widget.size * 0.02),
          ConsciaAlterEgoPreset.assistantLoading => Offset(
              -widget.size * (0.24 + phase * 0.04),
              -widget.size * (0.02 + phase * 0.012),
            ),
          ConsciaAlterEgoPreset.reflectionLoading => Offset(
              -widget.size * (0.21 + phase * 0.026),
              -widget.size * (0.018 + phase * 0.008),
            ),
        };
        final angelOffset = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle =>
            Offset(widget.size * 0.25, -widget.size * 0.085),
          ConsciaAlterEgoPreset.assistantLoading => Offset(
              widget.size * (0.255 + phase * 0.04),
              -widget.size * (0.085 + phase * 0.015),
            ),
          ConsciaAlterEgoPreset.reflectionLoading => Offset(
              widget.size * (0.225 + phase * 0.026),
              -widget.size * (0.08 + phase * 0.01),
            ),
        };
        final moneyOffset = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => Offset(0, widget.size * 0.17),
          ConsciaAlterEgoPreset.assistantLoading =>
            Offset(0, widget.size * (0.175 - phase * 0.022)),
          ConsciaAlterEgoPreset.reflectionLoading =>
            Offset(0, widget.size * (0.17 - phase * 0.014)),
        } +
            (frame.moneyPose == _MoneyPose.shake
                ? Offset(math.sin(t * math.pi * 24) * widget.size * 0.012, 0)
                : Offset.zero);

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
          width: widget.size * (isIdle ? 1.96 : 2.18),
          height: widget.size * (isIdle ? 1.34 : 1.62),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(
                  widget.size * (isIdle ? 1.36 : 1.56) * glowScale,
                  widget.size * (isIdle ? 1.14 : 1.34) * glowScale,
                ),
                painter: _GalaxyBackgroundPainter(
                  redOpacity: redOpacity,
                  blueOpacity: blueOpacity,
                  goldOpacity: goldOpacity,
                  pulse: phase,
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
                  width: widget.size * 1.62,
                  height: widget.size * 1.18,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset: devilOffset,
                        child: Transform.rotate(
                          angle: isIdle ? 0 : -shimmerRotation,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _LayeredAssetImage(
                              assetPath: _characterPoseAsset(
                                _devilAssetDirectory,
                                frame.devilPose,
                              ),
                              keyValue:
                                  'conscience-devil-${frame.devilPose.name}',
                              width: widget.size * 0.39,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: angelOffset,
                        child: Transform.rotate(
                          angle: isIdle ? 0 : shimmerRotation,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _LayeredAssetImage(
                              assetPath: _characterPoseAsset(
                                _angelAssetDirectory,
                                frame.angelPose,
                              ),
                              keyValue:
                                  'conscience-angel-${frame.angelPose.name}',
                              width: widget.size * 0.43,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: moneyOffset,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _LayeredAssetImage(
                            assetPath: _moneyPoseAsset(frame.moneyPose),
                            keyValue: 'conscience-money-${frame.moneyPose.name}',
                          width: widget.size * 0.58,
                          ),
                        ),
                      ),
                    ],
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

class _LayeredAssetImage extends StatelessWidget {
  const _LayeredAssetImage({
    required this.assetPath,
    required this.keyValue,
    required this.width,
  });

  final String assetPath;
  final String keyValue;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: ValueKey(keyValue),
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _GalaxyBackgroundPainter extends CustomPainter {
  const _GalaxyBackgroundPainter({
    required this.redOpacity,
    required this.blueOpacity,
    required this.goldOpacity,
    required this.pulse,
  });

  final double redOpacity;
  final double blueOpacity;
  final double goldOpacity;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    void drawGlow({
      required Offset offset,
      required Color color,
      required double radius,
      required double blurSigma,
    }) {
      canvas.drawCircle(
        offset,
        radius,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
      );
    }

    drawGlow(
      offset: Offset(size.width * 0.28, center.dy * 0.95),
      color: const Color(0xFFFF5A4A).withValues(alpha: redOpacity),
      radius: size.width * (0.18 + pulse * 0.03),
      blurSigma: size.width * 0.09,
    );
    drawGlow(
      offset: Offset(size.width * 0.74, center.dy * 0.98),
      color: const Color(0xFF67D9FF).withValues(alpha: blueOpacity),
      radius: size.width * (0.19 + pulse * 0.025),
      blurSigma: size.width * 0.09,
    );
    drawGlow(
      offset: Offset(size.width * 0.54, size.height * 0.18),
      color: const Color(0xFFFFD45E).withValues(alpha: goldOpacity),
      radius: size.width * (0.13 + pulse * 0.02),
      blurSigma: size.width * 0.075,
    );
    drawGlow(
      offset: Offset(size.width * 0.5, center.dy),
      color: Colors.white.withValues(alpha: 0.1 + pulse * 0.04),
      radius: size.width * 0.12,
      blurSigma: size.width * 0.05,
    );
  }

  @override
  bool shouldRepaint(covariant _GalaxyBackgroundPainter oldDelegate) {
    return oldDelegate.redOpacity != redOpacity ||
        oldDelegate.blueOpacity != blueOpacity ||
        oldDelegate.goldOpacity != goldOpacity ||
        oldDelegate.pulse != pulse;
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
