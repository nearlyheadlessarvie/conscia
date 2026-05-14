import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated particle cloud — ~110 small dots drifting independently inside
/// a soft sphere, coloured with the devil/angel/conscia palette.
///
/// Each particle has a deterministic base position (spherical distribution,
/// biased toward centre), independent drift frequency and phase, and a colour
/// drawn from the app's three-character palette.  The result resembles the
/// iOS ambient particle animations but with our colour signature and higher
/// entropy.
class ThinkingCloudWidget extends StatefulWidget {
  const ThinkingCloudWidget({super.key, this.size = 220});
  final double size;

  @override
  State<ThinkingCloudWidget> createState() => _ThinkingCloudWidgetState();
}

class _ThinkingCloudWidgetState extends State<ThinkingCloudWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
            t: _controller.value * math.pi * 2,
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

/// Devil/angel/conscia colour palette — angel blue is dominant (~45 %)
/// to give the "thinking" feel; devil and conscia are accents.
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
];

// Cumulative probability breakpoints matching the palette above.
// Angel: 0.00–0.45, Devil: 0.45–0.65, Conscia: 0.65–0.83, Neutral: 0.83–1.00
const _paletteWeights = [
  0.12, 0.12, 0.12, 0.09, // angel  (45 %)
  0.08, 0.06, 0.06,       // devil  (20 %)
  0.10, 0.08,             // conscia(18 %)
  0.09, 0.08,             // neutral(17 %)
];

List<_Particle> _buildParticles() {
  final rng = math.Random(0xC0A5C1A); // fixed seed → deterministic layout
  const count = 110;
  const maxR = 0.44; // sphere radius as fraction of widget dimension

  final particles = <_Particle>[];
  for (var i = 0; i < count; i++) {
    // Uniform spherical-disc distribution, biased toward centre via pow.
    final angle = rng.nextDouble() * math.pi * 2;
    final radial = math.pow(rng.nextDouble(), 0.6).toDouble(); // 0=centre, 1=edge
    final r = maxR * radial;

    final bx = 0.5 + r * math.cos(angle);
    final by = 0.5 + r * math.sin(angle);

    // Drift: edge particles wander more than core particles.
    final driftScale = 0.007 + radial * 0.022;
    final ax = driftScale * (0.6 + rng.nextDouble());
    final ay = driftScale * (0.6 + rng.nextDouble());

    // Independent frequencies — wide range drives chaos.
    final sx = 0.25 + rng.nextDouble() * 1.6;
    final sy = 0.25 + rng.nextDouble() * 1.6;
    final phase = rng.nextDouble() * math.pi * 2;

    // Size: centre dots slightly larger for a soft-core feel.
    final radius = 1.4 + (1 - radial) * 2.2 + rng.nextDouble() * 1.4;

    // Opacity: core more opaque; edge particles are wisps.
    final opacity = (0.30 + (1 - radial) * 0.38 + rng.nextDouble() * 0.15)
        .clamp(0.18, 0.90);

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
      bx: bx, by: by,
      ax: ax, ay: ay,
      sx: sx, sy: sy,
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

// ── Painter ───────────────────────────────────────────────────────────────

class _ThinkingCloudPainter extends CustomPainter {
  const _ThinkingCloudPainter({required this.t});
  final double t; // 0 → 2π, repeating

  @override
  void paint(Canvas canvas, Size size) {
    // Soft background glow — a single large translucent blob anchored at
    // centre so the particle cloud reads as a cohesive sphere.
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.38,
      Paint()
        ..color = const Color(0xFF67D9FF).withValues(alpha: 0.06)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, size.width * 0.22),
    );

    final paint = Paint();

    for (final p in _particles) {
      final x = (p.bx + math.sin(t * p.sx + p.phase) * p.ax) * size.width;
      final y = (p.by + math.cos(t * p.sy + p.phase * 1.3) * p.ay) * size.height;

      // Opacity pulses gently on a slow independent phase.
      final op = (p.opacity + math.sin(t * 0.8 + p.phase * 0.6) * 0.11)
          .clamp(0.0, 1.0);

      paint
        ..color = p.color.withValues(alpha: op)
        // Very subtle per-dot softness — keeps dots legible as individuals.
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, p.radius * 0.35);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingCloudPainter old) => old.t != t;
}
