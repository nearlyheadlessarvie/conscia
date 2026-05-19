import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated particle cloud — many small dots drifting independently inside
/// and around a soft sphere, coloured with the devil/angel/conscia palette.
///
/// Each particle has a deterministic base position (spherical distribution,
/// biased toward centre), independent drift frequency and phase, and a colour
/// drawn from the app's three-character palette.  The result resembles the
/// iOS ambient particle animations but with our colour signature and higher
/// entropy.
class ThinkingCloudWidget extends StatefulWidget {
  const ThinkingCloudWidget({
    super.key,
    this.size = 220,
    this.animate = true,
    @visibleForTesting this.initialPhase,
  });

  final double size;
  final bool animate;
  final double? initialPhase;

  @override
  State<ThinkingCloudWidget> createState() => _ThinkingCloudWidgetState();
}

class _ThinkingCloudWidgetState extends State<ThinkingCloudWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double? _phaseOffset;

  double get _effectivePhaseOffset {
    return _phaseOffset ??=
        widget.initialPhase ?? math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void initState() {
    super.initState();
    _phaseOffset =
        widget.initialPhase ?? math.Random().nextDouble() * math.pi * 2;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ThinkingCloudWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _ThinkingCloudPainter(
            t: _controller.value * math.pi * 2 + _effectivePhaseOffset,
          ),
        ),
      ),
    );
  }
}

// ── Particle generation ───────────────────────────────────────────────────

class _Particle {
  const _Particle({
    required this.bx,
    required this.by,
    required this.ax,
    required this.ay,
    required this.sx,
    required this.sy,
    required this.phase,
    required this.color,
    required this.opacity,
    required this.radius,
  });

  // base position as fraction of canvas (0–1)
  final double bx, by;
  // drift amplitude as fraction of canvas
  final double ax, ay;
  // drift angular frequency (radians per full animation cycle)
  final double sx, sy;
  // phase offset so particles don't move in unison
  final double phase;
  final Color color;
  // base opacity (0–1)
  final double opacity;
  // dot radius in logical pixels
  final double radius;
}

/// Devil/angel/conscia colour palette — angel blue is dominant, devil and
/// conscia are accents, and a quiet ink range adds neutral reasoning noise.
const _palette = [
  // Angel — cyan / blue (dominant)
  Color(0xFF67D9FF),
  Color(0xFF4FC3F7),
  Color(0xFF50A0F0),
  Color(0xFF7EC8E3),
  // Devil — warm red / orange
  Color(0xFFFF5A4A),
  Color(0xFFFF7A6A),
  Color(0xFFE64020),
  // Conscia — amber / gold
  Color(0xFFFFD45E),
  Color(0xFFFFB432),
  // Neutral — soft lavender-white (blends all three)
  Color(0xFFE8ECFF),
  Color(0xFFDCE1FF),
  // Ink — black/grey neutral thought particles
  Color(0xFF141414),
  Color(0xFF5C5C5C),
  Color(0xFF9A9A9A),
];

@visibleForTesting
const debugThinkingCloudPalette = _palette;

// Cumulative probability breakpoints matching the palette above.
// Angel: 34 %, Devil: 15 %, Conscia: 14 %, Neutral: 14 %, Ink: 23 %
const _paletteWeights = [
  0.09, 0.09, 0.08, 0.08, // angel  (34 %)
  0.05, 0.05, 0.05, // devil  (15 %)
  0.07, 0.07, // conscia(14 %)
  0.07, 0.07, // neutral(14 %)
  0.07, 0.08, 0.08, // ink    (23 %)
];

List<_Particle> _buildParticles() {
  final rng = math.Random(0xC0A5C1A); // fixed seed → deterministic layout
  const count = 168;
  const maxR = 0.44; // sphere radius as fraction of widget dimension

  final particles = <_Particle>[];
  for (var i = 0; i < count; i++) {
    // Uniform spherical-disc distribution, biased toward centre via pow.
    final angle = rng.nextDouble() * math.pi * 2;
    final coreRadial = math.pow(rng.nextDouble(), 0.55).toDouble();
    final isSpill = rng.nextDouble() < 0.16;
    final radial = isSpill
        ? 1.02 + rng.nextDouble() * 0.22
        : coreRadial; // 0=centre, >1=outside sphere
    final r = maxR * radial;

    final bx = 0.5 + r * math.cos(angle);
    final by = 0.5 + r * math.sin(angle);

    // Drift: edge particles wander more than core particles.
    final driftScale = 0.008 + radial * 0.026;
    final ax = driftScale * (0.55 + rng.nextDouble() * 1.25);
    final ay = driftScale * (0.55 + rng.nextDouble() * 1.25);

    // Integer frequencies make the cycle seamless: the end frame is a
    // natural continuation of the first, while phases keep motion varied.
    final sx = (1 + rng.nextInt(3)).toDouble();
    final sy = (1 + rng.nextInt(4)).toDouble();
    final phase = rng.nextDouble() * math.pi * 2;

    // Size: centre dots slightly larger for a soft-core feel.
    final radius = isSpill
        ? 0.9 + rng.nextDouble() * 1.25
        : 1.2 + (1 - radial) * 2.3 + rng.nextDouble() * 1.35;

    // Opacity: core more opaque; edge particles are wisps.
    final opacity = (isSpill
            ? 0.18 + rng.nextDouble() * 0.22
            : 0.28 + (1 - radial) * 0.40 + rng.nextDouble() * 0.15)
        .clamp(0.14, 0.90);

    // Colour from weighted palette.
    var roll = rng.nextDouble();
    var colorIdx = _palette.length - 1;
    for (var c = 0; c < _paletteWeights.length; c++) {
      roll -= _paletteWeights[c];
      if (roll <= 0) {
        colorIdx = c;
        break;
      }
    }

    particles.add(_Particle(
      bx: bx,
      by: by,
      ax: ax,
      ay: ay,
      sx: sx,
      sy: sy,
      phase: phase,
      color: _palette[colorIdx],
      opacity: opacity,
      radius: radius,
    ));
  }
  return particles;
}

// Generated once and reused; fixed seed makes this deterministic.
final _particles = _buildParticles();

@visibleForTesting
double get debugThinkingCloudNeutralWeight =>
    _paletteWeights.skip(9).fold(0, (sum, weight) => sum + weight);

@visibleForTesting
double? debugThinkingCloudPainterPhase(CustomPainter? painter) {
  if (painter is _ThinkingCloudPainter) {
    return painter.t;
  }
  return null;
}

// ── Painter ───────────────────────────────────────────────────────────────

class _ThinkingCloudPainter extends CustomPainter {
  const _ThinkingCloudPainter({required this.t});
  final double t; // 0 → 2π, repeating

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final sphereRadius = size.width * 0.39;

    // Soft background glow — a single large translucent blob anchored at
    // centre so the particle cloud reads as a cohesive sphere.
    canvas.drawCircle(
      center,
      sphereRadius,
      Paint()
        ..color = const Color(0xFF67D9FF).withValues(alpha: 0.06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.22),
    );

    canvas.drawCircle(
      center,
      sphereRadius * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012
        ..color = const Color(0xFF18245C).withValues(alpha: 0.055)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.018),
    );

    canvas.drawCircle(
      center,
      sphereRadius * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.045)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.012),
    );

    final paint = Paint();

    for (final p in _particles) {
      final x = (p.bx + math.sin(t * p.sx + p.phase) * p.ax) * size.width;
      final y =
          (p.by + math.cos(t * p.sy + p.phase * 1.3) * p.ay) * size.height;

      // Opacity pulses gently on a slow independent phase.
      final op =
          (p.opacity + math.sin(t + p.phase * 0.6) * 0.11).clamp(0.0, 1.0);

      paint
        ..color = p.color.withValues(alpha: op)
        // Very subtle per-dot softness — keeps dots legible as individuals.
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.35);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingCloudPainter old) => old.t != t;
}
