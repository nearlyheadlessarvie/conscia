import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An ambient "thinking" cloud animation — 7 soft blurred colour blobs
/// (red/devil, blue/angel, amber/conscia, white diffuse) drifting at
/// independent frequencies inside a gently morphing ellipse clip.
///
/// Inspired by _GalaxyBackgroundPainter in conscience_mark.dart.
/// No centre core, no rings, no orbiting particles.
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
      duration: const Duration(seconds: 6),
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

// ── Blob data ──────────────────────────────────────────────────────────────

class _Blob {
  const _Blob({
    required this.bx, required this.by,
    required this.ax, required this.ay,
    required this.sx, required this.sy,
    required this.phase,
    required this.color,
    required this.opacity,
    required this.radius,
  });
  final double bx, by, ax, ay, sx, sy, phase, opacity, radius;
  final Color color;
}

const _blobs = <_Blob>[
  // Devil — red / orange
  _Blob(bx:0.30, by:0.52, ax:0.13, ay:0.10, sx:0.55, sy:0.38, phase:0.00, color:Color(0xFFFF5A4A), opacity:0.62, radius:0.40),
  _Blob(bx:0.35, by:0.44, ax:0.09, ay:0.13, sx:0.82, sy:0.61, phase:1.40, color:Color(0xFFE64020), opacity:0.38, radius:0.28),
  // Angel — cyan / blue
  _Blob(bx:0.72, by:0.50, ax:0.14, ay:0.09, sx:0.48, sy:0.70, phase:2.10, color:Color(0xFF67D9FF), opacity:0.60, radius:0.40),
  _Blob(bx:0.65, by:0.58, ax:0.08, ay:0.14, sx:0.73, sy:0.44, phase:3.30, color:Color(0xFF50A0F0), opacity:0.35, radius:0.26),
  // Conscia — amber / gold
  _Blob(bx:0.52, by:0.22, ax:0.11, ay:0.08, sx:0.66, sy:0.52, phase:4.50, color:Color(0xFFFFD45E), opacity:0.55, radius:0.34),
  _Blob(bx:0.48, by:0.78, ax:0.10, ay:0.10, sx:0.44, sy:0.80, phase:0.85, color:Color(0xFFFFB432), opacity:0.30, radius:0.24),
  // Diffuse white — blends all three
  _Blob(bx:0.50, by:0.50, ax:0.06, ay:0.06, sx:0.30, sy:0.35, phase:1.90, color:Color(0xFFDCE1FF), opacity:0.22, radius:0.32),
];

// ── Painter ────────────────────────────────────────────────────────────────

class _ThinkingCloudPainter extends CustomPainter {
  const _ThinkingCloudPainter({required this.t});
  final double t; // 0 → 2π, repeating

  @override
  void paint(Canvas canvas, Size size) {
    // Morphing ellipse clip — irregular, slowly rotating
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final rx = size.width  * (0.44 + math.sin(t * 0.4)  * 0.015);
    final ry = size.height * (0.44 + math.cos(t * 0.35) * 0.012);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.sin(t * 0.15) * 0.12);
    canvas.translate(-cx, -cy);
    canvas.clipPath(
      Path()..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: rx * 2,
        height: ry * 2,
      )),
    );

    for (final b in _blobs) {
      final x = (b.bx + math.sin(t * b.sx + b.phase) * b.ax) * size.width;
      final y = (b.by + math.cos(t * b.sy + b.phase * 1.3) * b.ay) * size.height;
      final op = (b.opacity + math.sin(t * 1.1 + b.phase * 0.7) * 0.14)
          .clamp(0.0, 1.0);
      final radius = (b.radius + math.sin(t * 0.65 + b.phase) * 0.04) * size.width;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = b.color.withValues(alpha: op)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThinkingCloudPainter old) => old.t != t;
}
