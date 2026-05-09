import 'dart:math' as math;

import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _brandIconAsset = 'assets/images/app_icon.svg';
const _alterEgoAsset = 'assets/images/conscia_alterego.png';

enum _CharacterPose { neutral, push, block }

enum _MoneyPose { neutral, left, right, shake }

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

double _segmentProgress(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

class _BattleMotionProfile {
  const _BattleMotionProfile({
    required this.devilPressure,
    required this.angelPressure,
    required this.clashStrength,
    required this.moneyBias,
    required this.settleStrength,
  });

  final double devilPressure;
  final double angelPressure;
  final double clashStrength;
  final double moneyBias;
  final double settleStrength;
}

const _devilPoseFrames = <_CharacterPose, String>{
  _CharacterPose.neutral: '1_neutral.png',
  _CharacterPose.push: '2_push.png',
  _CharacterPose.block: '3_block.png',
};

const _angelPoseFrames = <_CharacterPose, String>{
  _CharacterPose.neutral: '1_neutral.png',
  _CharacterPose.block: '2_block.png',
  _CharacterPose.push: '3_push.png',
};

const _moneyPoseFrames = <_MoneyPose, String>{
  _MoneyPose.neutral: '1_neutral.png',
  _MoneyPose.right: '2_right.png',
  _MoneyPose.left: '3_left.png',
  _MoneyPose.shake: '5_afraid.png',
};

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
      ConsciaAlterEgoPreset.assistantLoading => t < 0.2
          ? const _BattleFrame(
              devilPose: _CharacterPose.push,
              angelPose: _CharacterPose.neutral,
              moneyPose: _MoneyPose.left,
            )
          : t < 0.42
              ? const _BattleFrame(
                  devilPose: _CharacterPose.push,
                  angelPose: _CharacterPose.block,
                  moneyPose: _MoneyPose.left,
                )
              : t < 0.62
                  ? const _BattleFrame(
                      devilPose: _CharacterPose.push,
                      angelPose: _CharacterPose.push,
                      moneyPose: _MoneyPose.shake,
                    )
                  : t < 0.84
                      ? const _BattleFrame(
                          devilPose: _CharacterPose.block,
                          angelPose: _CharacterPose.push,
                          moneyPose: _MoneyPose.right,
                        )
                      : const _BattleFrame(
                          devilPose: _CharacterPose.neutral,
                          angelPose: _CharacterPose.block,
                          moneyPose: _MoneyPose.neutral,
                        ),
      ConsciaAlterEgoPreset.reflectionLoading => t < 0.46
          ? const _BattleFrame(
              devilPose: _CharacterPose.neutral,
              angelPose: _CharacterPose.block,
              moneyPose: _MoneyPose.neutral,
            )
          : t < 0.7
              ? const _BattleFrame(
                  devilPose: _CharacterPose.block,
                  angelPose: _CharacterPose.push,
                  moneyPose: _MoneyPose.shake,
                )
              : t < 0.88
                  ? const _BattleFrame(
                      devilPose: _CharacterPose.neutral,
                      angelPose: _CharacterPose.block,
                      moneyPose: _MoneyPose.right,
                    )
                  : const _BattleFrame(
                      devilPose: _CharacterPose.neutral,
                      angelPose: _CharacterPose.neutral,
                      moneyPose: _MoneyPose.neutral,
                    ),
    };
  }

  _BattleMotionProfile _motionForPreset(
      ConsciaAlterEgoPreset preset, double t) {
    return switch (preset) {
      ConsciaAlterEgoPreset.idle => const _BattleMotionProfile(
          devilPressure: 0,
          angelPressure: 0,
          clashStrength: 0,
          moneyBias: 0,
          settleStrength: 0,
        ),
      ConsciaAlterEgoPreset.assistantLoading => () {
          final devilPressure = _segmentProgress(t, 0.0, 0.36);
          final angelPressure = _segmentProgress(t, 0.38, 0.82);
          final clashIn = _segmentProgress(t, 0.38, 0.5);
          final clashOut = 1 - _segmentProgress(t, 0.5, 0.66);
          final clashStrength =
              math.max(0.0, math.min(clashIn, clashOut)).toDouble();
          final settleStrength = _segmentProgress(t, 0.82, 1.0);
          final moneyBias = (-devilPressure * 0.8) + (angelPressure * 0.9);
          return _BattleMotionProfile(
            devilPressure: devilPressure,
            angelPressure: angelPressure,
            clashStrength: clashStrength,
            moneyBias: moneyBias,
            settleStrength: settleStrength,
          );
        }(),
      ConsciaAlterEgoPreset.reflectionLoading => () {
          final devilPressure = _segmentProgress(t, 0.46, 0.66) * 0.45;
          final angelPressure = _segmentProgress(t, 0.24, 0.74) * 0.72;
          final clashIn = _segmentProgress(t, 0.48, 0.58);
          final clashOut = 1 - _segmentProgress(t, 0.58, 0.74);
          final clashStrength =
              math.max(0.0, math.min(clashIn, clashOut)).toDouble() * 0.65;
          final settleStrength = _segmentProgress(t, 0.74, 1.0);
          final moneyBias = (-devilPressure * 0.35) + (angelPressure * 0.48);
          return _BattleMotionProfile(
            devilPressure: devilPressure,
            angelPressure: angelPressure,
            clashStrength: clashStrength,
            moneyBias: moneyBias,
            settleStrength: settleStrength,
          );
        }(),
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
        final motion = _motionForPreset(widget.preset, t);
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
            Offset(-widget.size * 0.42, -widget.size * 0.045),
          ConsciaAlterEgoPreset.assistantLoading => Offset(
              -widget.size *
                  (0.42 +
                      motion.devilPressure * 0.12 -
                      motion.settleStrength * 0.04),
              -widget.size * (0.042 + motion.devilPressure * 0.03),
            ),
          ConsciaAlterEgoPreset.reflectionLoading => Offset(
              -widget.size *
                  (0.4 +
                      motion.devilPressure * 0.06 -
                      motion.settleStrength * 0.02),
              -widget.size * (0.038 + motion.devilPressure * 0.016),
            ),
        };
        final angelOffset = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle =>
            Offset(widget.size * 0.46, -widget.size * 0.16),
          ConsciaAlterEgoPreset.assistantLoading => Offset(
              widget.size *
                  (0.48 +
                      motion.angelPressure * 0.12 -
                      motion.settleStrength * 0.03),
              -widget.size * (0.16 + motion.angelPressure * 0.03),
            ),
          ConsciaAlterEgoPreset.reflectionLoading => Offset(
              widget.size *
                  (0.44 +
                      motion.angelPressure * 0.075 -
                      motion.settleStrength * 0.02),
              -widget.size * (0.145 + motion.angelPressure * 0.022),
            ),
        };
        final moneyOffset = switch (widget.preset) {
              ConsciaAlterEgoPreset.idle => Offset(0, widget.size * 0.17),
              ConsciaAlterEgoPreset.assistantLoading => Offset(
                  widget.size * motion.moneyBias * 0.14,
                  widget.size * (0.175 - motion.clashStrength * 0.03)),
              ConsciaAlterEgoPreset.reflectionLoading => Offset(
                  widget.size * motion.moneyBias * 0.09,
                  widget.size * (0.17 - motion.clashStrength * 0.02)),
            } +
            (frame.moneyPose == _MoneyPose.shake
                ? Offset(
                    math.sin(t * math.pi * 24) *
                        widget.size *
                        (0.008 + motion.clashStrength * 0.01),
                    0)
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
          width: widget.size * (isIdle ? 2.9 : 3.2),
          height: widget.size * (isIdle ? 1.9 : 2.15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(
                  widget.size * (isIdle ? 1.9 : 2.14) * glowScale,
                  widget.size * (isIdle ? 1.56 : 1.76) * glowScale,
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
                  width: widget.size * 2.55,
                  height: widget.size * 1.75,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset: devilOffset,
                        child: Transform.rotate(
                          angle: isIdle
                              ? 0
                              : (-0.03 * motion.devilPressure) +
                                  (0.018 * motion.clashStrength) -
                                  (0.012 * motion.settleStrength),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _PoseAssetImage(
                              atlas: devilMascotAtlas,
                              frameName: _devilPoseFrames[frame.devilPose]!,
                              keyValue:
                                  'conscience-devil-${frame.devilPose.name}',
                              width: widget.size * 0.98,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: angelOffset,
                        child: Transform.rotate(
                          angle: isIdle
                              ? 0
                              : (0.028 * motion.angelPressure) -
                                  (0.014 * motion.clashStrength),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _PoseAssetImage(
                              atlas: angelMascotAtlas,
                              frameName: _angelPoseFrames[frame.angelPose]!,
                              keyValue:
                                  'conscience-angel-${frame.angelPose.name}',
                              width: widget.size * 0.9,
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
                          child: _PoseAssetImage(
                            atlas: moneyMascotAtlas,
                            frameName: _moneyPoseFrames[frame.moneyPose]!,
                            keyValue:
                                'conscience-money-${frame.moneyPose.name}',
                            width: widget.size * 0.48,
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

class _PoseAssetImage extends StatelessWidget {
  const _PoseAssetImage({
    required this.atlas,
    required this.frameName,
    required this.keyValue,
    required this.width,
  });

  final MascotSpriteAtlas atlas;
  final String frameName;
  final String keyValue;
  final double width;

  @override
  Widget build(BuildContext context) {
    return MascotSpriteFrame(
      key: ValueKey(keyValue),
      atlas: atlas,
      frameName: frameName,
      width: width,
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
