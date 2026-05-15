import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/category_icons.dart';
import '../core/theme/app_colors.dart';

class BudgetMixPalette {
  const BudgetMixPalette._();

  static const _colors = [
    Color(0xFF43A047),
    Color(0xFFFF9800),
    Color(0xFFEC407A),
    Color(0xFF2563EB),
    Color(0xFF00ACC1),
    Color(0xFF7E57C2),
  ];

  static Color staticColorFor(int index) => _colors[index % _colors.length];

  static Color colorFor(int index, BuildContext context) {
    final color = staticColorFor(index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color.lerp(color, Colors.white, 0.18)! : color;
  }
}

class BudgetMixDonutSegment {
  const BudgetMixDonutSegment({
    required this.share,
    required this.color,
  });

  final double share;
  final Color color;
}

class BudgetMixDonut extends StatelessWidget {
  const BudgetMixDonut({
    super.key,
    required this.segments,
    required this.center,
    this.size = 124,
    this.trackColor,
    this.trackOpacity = 0.2,
    this.trackStrokeWidth = 22,
    this.segmentStrokeWidth = 16,
    this.visibleGapPx = 1.5,
    this.onSegmentTap,
  });

  final List<BudgetMixDonutSegment> segments;
  final Widget center;
  final double size;
  final Color? trackColor;
  final double trackOpacity;
  final double trackStrokeWidth;
  final double segmentStrokeWidth;
  final double visibleGapPx;
  final ValueChanged<int>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final segmentIndex = _segmentIndexAt(details.localPosition);
        if (segmentIndex != null) onSegmentTap?.call(segmentIndex);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: BudgetMixDonutPainter(
                segments: segments,
                trackColor:
                    trackColor ?? colors.ink.withValues(alpha: trackOpacity),
                trackOpacity: trackOpacity,
                trackStrokeWidth: trackStrokeWidth,
                segmentStrokeWidth: segmentStrokeWidth,
                visibleGapPx: visibleGapPx,
              ),
            ),
            center,
          ],
        ),
      ),
    );
  }

  int? _segmentIndexAt(Offset localPosition) {
    if (segments.isEmpty) return null;

    final center = Offset(size / 2, size / 2);
    final vector = localPosition - center;
    final distance = vector.distance;
    final arcRadius = (size - trackStrokeWidth) / 2;
    final hitSlop = trackStrokeWidth / 2 + 8;
    if (distance < arcRadius - hitSlop || distance > arcRadius + hitSlop) {
      return null;
    }

    const start = -math.pi / 2;
    const full = math.pi * 2;
    final angle = (math.atan2(vector.dy, vector.dx) - start) % full;
    var cursor = 0.0;
    for (final entry in segments.indexed) {
      final sweep = full * entry.$2.share.clamp(0.0, 1.0);
      if (angle >= cursor && angle <= cursor + sweep) return entry.$1;
      cursor += sweep;
    }
    return null;
  }
}

class BudgetMixDonutPainter extends CustomPainter {
  const BudgetMixDonutPainter({
    required this.segments,
    required this.trackColor,
    required this.trackOpacity,
    required this.trackStrokeWidth,
    required this.segmentStrokeWidth,
    required this.visibleGapPx,
  });

  final List<BudgetMixDonutSegment> segments;
  final Color trackColor;
  final double trackOpacity;
  final double trackStrokeWidth;
  final double segmentStrokeWidth;
  final double visibleGapPx;

  bool get usesCapAwareGaps => true;

  List<Color> get segmentColors =>
      segments.map((segment) => segment.color).toList(growable: false);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(trackStrokeWidth / 2);
    final radius = arcRect.width / 2;
    final capAwareGap = (segmentStrokeWidth + visibleGapPx) / radius;
    const start = -math.pi / 2;
    const full = math.pi * 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, full, false, track);
    if (segments.isEmpty) return;

    var cursor = start;
    for (final segment in segments) {
      final rawSweep = full * segment.share.clamp(0.0, 1.0);
      if (rawSweep <= 0) continue;
      final gap = math.min(capAwareGap, rawSweep * 0.45);
      final sweep = math.max(0.02, rawSweep - gap);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = segmentStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, cursor + gap / 2, sweep, false, paint);
      cursor += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant BudgetMixDonutPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        trackColor != oldDelegate.trackColor ||
        trackOpacity != oldDelegate.trackOpacity ||
        trackStrokeWidth != oldDelegate.trackStrokeWidth ||
        segmentStrokeWidth != oldDelegate.segmentStrokeWidth ||
        visibleGapPx != oldDelegate.visibleGapPx;
  }
}

class BudgetMixPill extends StatefulWidget {
  const BudgetMixPill({
    super.key,
    required this.index,
    required this.category,
    required this.share,
    this.active = false,
    this.shakeSerial = 0,
  });

  final int index;
  final String category;
  final double share;
  final bool active;
  final int shakeSerial;

  @override
  State<BudgetMixPill> createState() => _BudgetMixPillState();
}

class _BudgetMixPillState extends State<BudgetMixPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant BudgetMixPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && widget.shakeSerial != oldWidget.shakeSerial) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = BudgetMixPalette.colorFor(widget.index, context);
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final offset = math.sin(t * math.pi * 6) * (1 - t) * 4;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: KeyedSubtree(
        key: widget.active
            ? ValueKey('budget-mix-chip-${widget.index}-active')
            : ValueKey('budget-mix-chip-${widget.index}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: const SizedBox(width: 8, height: 8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.category} ${(widget.share * 100).round()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetCategoryGlyph extends StatelessWidget {
  const BudgetCategoryGlyph({
    super.key,
    required this.category,
    required this.color,
    this.iconKey,
  });

  final String category;
  final Color color;
  final Key? iconKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          CategoryIcons.forCategory(category),
          key: iconKey,
          size: 30,
          color: color,
        ),
      ),
    );
  }
}
