import 'dart:math' as math;

import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/widgets/conscience_loader_tracks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _brandIconAsset = 'assets/images/app_icon.svg';
const _alterEgoAsset = 'assets/images/conscia_alterego.png';

const _devilPoseFrames = <DevilBattlePose, String>{
  DevilBattlePose.neutral: '1_neutral.png',
  DevilBattlePose.push: '2_push.png',
  DevilBattlePose.block: '3_block.png',
  DevilBattlePose.lose: '4_lose.png',
  DevilBattlePose.win: '5_win.png',
  DevilBattlePose.force: '6_force.png',
  DevilBattlePose.tug: '7_tug.png',
  DevilBattlePose.whisper: '8_whisper.png',
  DevilBattlePose.coin: '9_coin.png',
  DevilBattlePose.receiptHook: '10_receipthook.png',
  DevilBattlePose.sneak: '11_sneak.png',
  DevilBattlePose.ragePush: '12_ragepush.png',
  DevilBattlePose.slip: '13_slip.png',
  DevilBattlePose.frustrated: '14_frustrated.png',
};

const _angelPoseFrames = <AngelBattlePose, String>{
  AngelBattlePose.neutral: '1_neutral.png',
  AngelBattlePose.block: '2_block.png',
  AngelBattlePose.push: '3_push.png',
  AngelBattlePose.win: '4_win.png',
  AngelBattlePose.lose: '5_lose.png',
  AngelBattlePose.force: '6_force.png',
  AngelBattlePose.tug: '7_tug.png',
  AngelBattlePose.shield: '8_shield.png',
  AngelBattlePose.coinShield: '9_coinshield.png',
  AngelBattlePose.intercept: '10_intercept.png',
  AngelBattlePose.focusPray: '11_focuspray.png',
  AngelBattlePose.holyBurst: '12_holyburst.png',
  AngelBattlePose.lastStand: '13_laststand.png',
  AngelBattlePose.wingBlock: '14_wingblock.png',
  AngelBattlePose.numberOne: '15_numberone.png',
};

const _moneyPoseFrames = <MoneyBattlePose, String>{
  MoneyBattlePose.neutral: '1_neutral.png',
  MoneyBattlePose.right: '2_right.png',
  MoneyBattlePose.left: '3_left.png',
  MoneyBattlePose.save: '4_save.png',
  MoneyBattlePose.afraid: '5_afraid.png',
  MoneyBattlePose.squish: '6_squish.png',
  MoneyBattlePose.burst: '7_burst.png',
  MoneyBattlePose.folded: '8_folded.png',
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
    this.forcedOutcome,
  });

  final ConsciaAlterEgoPreset preset;
  final double size;
  final ConscienceBattleOutcome? forcedOutcome;

  @override
  State<ConsciaAlterEgoMotion> createState() => _ConsciaAlterEgoMotionState();
}

class _ConsciaAlterEgoMotionState extends State<ConsciaAlterEgoMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late ConscienceBattleOutcome _activeOutcome;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains(
            'TestWidgetsFlutterBinding',
          );

  Duration get _duration => switch (widget.preset) {
        ConsciaAlterEgoPreset.idle => const Duration(seconds: 5),
        ConsciaAlterEgoPreset.assistantLoading =>
          const Duration(milliseconds: 2800),
        ConsciaAlterEgoPreset.reflectionLoading =>
          const Duration(milliseconds: 2200),
      };

  ConscienceBattleOutcome _pickOutcome() {
    if (widget.forcedOutcome case final forced?) return forced;
    if (_isTestEnvironment) return ConscienceBattleOutcome.saved;
    return math.Random().nextBool()
        ? ConscienceBattleOutcome.saved
        : ConscienceBattleOutcome.spent;
  }

  double _testSampleValue() {
    return switch (widget.preset) {
      ConsciaAlterEgoPreset.idle => 0.0,
      ConsciaAlterEgoPreset.assistantLoading =>
        widget.forcedOutcome == ConscienceBattleOutcome.spent ? 0.96 : 0.9,
      ConsciaAlterEgoPreset.reflectionLoading => 0.72,
    };
  }

  void _startLoop() {
    _controller
      ..stop()
      ..forward(from: 0);
  }

  List<LoaderBattlePhase> _phasesForPreset(ConsciaAlterEgoPreset preset) {
    return switch (preset) {
      ConsciaAlterEgoPreset.idle => const [
          LoaderBattlePhase(
            start: 0,
            end: 1.01,
            devilPose: DevilBattlePose.neutral,
            angelPose: AngelBattlePose.neutral,
            moneyPose: MoneyBattlePose.neutral,
            moneyY: 0.17,
          ),
        ],
      ConsciaAlterEgoPreset.assistantLoading => [
          ...assistantCommonPhases,
          ...(_activeOutcome == ConscienceBattleOutcome.saved
              ? assistantSavedPhases
              : assistantSpentPhases),
        ],
      ConsciaAlterEgoPreset.reflectionLoading => reflectionPhases,
    };
  }

  LoaderBattlePhase _phaseForPreset(ConsciaAlterEgoPreset preset, double t) {
    final phases = _phasesForPreset(preset);
    return phases.firstWhere(
      (phase) => phase.contains(t),
      orElse: () => phases.last,
    );
  }

  @override
  void initState() {
    super.initState();
    _activeOutcome = _pickOutcome();
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isTestEnvironment) {
        _activeOutcome = _pickOutcome();
        _startLoop();
      }
    });
    if (_isTestEnvironment) {
      _controller.value = _testSampleValue();
    } else {
      _startLoop();
    }
  }

  @override
  void didUpdateWidget(covariant ConsciaAlterEgoMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset ||
        oldWidget.forcedOutcome != widget.forcedOutcome) {
      _controller.duration = _duration;
      _activeOutcome = _pickOutcome();
      if (_isTestEnvironment) {
        _controller.value = _testSampleValue();
      } else {
        _startLoop();
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
        final battlePhase = _phaseForPreset(widget.preset, t);
        final phase = (math.sin(t * math.pi * 2) + 1) / 2;
        final shieldGlowBoost = battlePhase.shieldPulse ? 0.12 : 0.0;
        final burstBoost = battlePhase.burstFlash ? 0.18 : 0.0;
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
              ConsciaAlterEgoPreset.assistantLoading =>
                0.25 + phase * 0.14 + shieldGlowBoost,
              ConsciaAlterEgoPreset.reflectionLoading =>
                0.21 + phase * 0.09 + shieldGlowBoost,
            } +
            burstBoost;
        final goldOpacity = switch (widget.preset) {
          ConsciaAlterEgoPreset.idle => 0.18 + phase * 0.06,
          ConsciaAlterEgoPreset.assistantLoading =>
            0.24 + phase * 0.1 + burstBoost,
          ConsciaAlterEgoPreset.reflectionLoading =>
            0.2 + phase * 0.07 + shieldGlowBoost,
        };
        final devilOffset = Offset(
          -widget.size * (0.42 - battlePhase.devilX),
          -widget.size * 0.05,
        );
        final angelOffset = Offset(
          widget.size * (0.46 + battlePhase.angelX),
          -widget.size * 0.15,
        );
        final moneyShake = switch (battlePhase.shake) {
          LoaderShakeMode.none => Offset.zero,
          LoaderShakeMode.light =>
            Offset(math.sin(t * math.pi * 12) * widget.size * 0.004, 0),
          LoaderShakeMode.impact =>
            Offset(math.sin(t * math.pi * 24) * widget.size * 0.007, 0),
          LoaderShakeMode.panic =>
            Offset(math.sin(t * math.pi * 30) * widget.size * 0.01, 0),
          LoaderShakeMode.tug =>
            Offset(math.sin(t * math.pi * 18) * widget.size * 0.012, 0),
        };
        final moneyOffset = Offset(
              widget.size * battlePhase.moneyX,
              widget.size * battlePhase.moneyY,
            ) +
            moneyShake;

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
                              : (-0.12 * battlePhase.devilX) +
                                  (battlePhase.shake == LoaderShakeMode.impact
                                      ? 0.02
                                      : 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _PoseAssetImage(
                              atlas: devilMascotAtlas,
                              frameName:
                                  _devilPoseFrames[battlePhase.devilPose]!,
                              keyValue:
                                  'conscience-devil-${battlePhase.devilPose.name}',
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
                              : (0.12 * battlePhase.angelX) -
                                  (battlePhase.shake == LoaderShakeMode.impact
                                      ? 0.014
                                      : 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _PoseAssetImage(
                              atlas: angelMascotAtlas,
                              frameName:
                                  _angelPoseFrames[battlePhase.angelPose]!,
                              keyValue:
                                  'conscience-angel-${battlePhase.angelPose.name}',
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
                            frameName: _moneyPoseFrames[battlePhase.moneyPose]!,
                            keyValue:
                                'conscience-money-${battlePhase.moneyPose.name}',
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
