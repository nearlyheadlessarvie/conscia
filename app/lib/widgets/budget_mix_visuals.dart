import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/category_icons.dart';
import '../core/theme/app_colors.dart';

class BudgetMixPalette {
  const BudgetMixPalette._();

  static final _colors =
      CategoryIcons.colorOptions.map((option) => option.accent).toList();

  static Color staticColorFor(int index) => _colors[index % _colors.length];

  static Color staticColorForCategory(
    String category, {
    String? type,
    String? colorKey,
  }) =>
      CategoryIcons.accentFor(category, type: type, colorKey: colorKey);

  static Color colorFor(int index, BuildContext context) {
    final color = staticColorFor(index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color.lerp(color, Colors.white, 0.18)! : color;
  }

  static Color colorForCategory(
    String category,
    BuildContext context, {
    String? type,
    String? colorKey,
  }) {
    final color =
        staticColorForCategory(category, type: type, colorKey: colorKey);
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
    const full = math.pi * 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, full, false, track);
    if (segments.isEmpty) return;

    for (final arc in _layoutArcs(size)) {
      final paint = Paint()
        ..color = arc.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = segmentStrokeWidth
        ..strokeCap = arc.strokeCap;

      if (arc.isDot) {
        final center = Offset(
          size.width / 2 + math.cos(arc.centerAngle) * radius,
          size.height / 2 + math.sin(arc.centerAngle) * radius,
        );
        canvas.drawCircle(
            center, arc.dotRadius, paint..style = PaintingStyle.fill);
      } else {
        canvas.drawArc(arcRect, arc.startAngle, arc.sweepAngle, false, paint);
      }
    }
  }

  @visibleForTesting
  List<double> debugBoundaryGapPx(Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(trackStrokeWidth / 2);
    final radius = arcRect.width / 2;
    final arcs = _layoutArcs(size);
    if (arcs.length < 2) return const [];

    final gaps = <double>[];
    for (var index = 0; index < arcs.length; index++) {
      final current = arcs[index];
      final next = arcs[(index + 1) % arcs.length];
      final rawGap = index == arcs.length - 1
          ? next.visualStartAngle + math.pi * 2 - current.visualEndAngle
          : next.visualStartAngle - current.visualEndAngle;
      gaps.add(rawGap * radius);
    }
    return gaps;
  }

  @visibleForTesting
  List<double> debugDotRadii(Size size) => _layoutArcs(size)
      .where((arc) => arc.isDot)
      .map((arc) => arc.dotRadius)
      .toList(growable: false);

  List<_BudgetMixDonutArc> _layoutArcs(Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(trackStrokeWidth / 2);
    final radius = arcRect.width / 2;
    final visibleGapAngle = visibleGapPx / radius;
    final capExtensionAngle = (segmentStrokeWidth / 2) / radius;
    const start = -math.pi / 2;
    const full = math.pi * 2;
    const minimumRoundedSweep = 0.02;

    var cursor = start;
    final arcs = <_BudgetMixDonutArc>[];
    final positiveSegments =
        segments.where((segment) => segment.share > 0).toList(growable: false);

    for (final segment in positiveSegments) {
      final rawSweep = full * segment.share.clamp(0.0, 1.0);
      if (rawSweep <= 0) continue;

      final canUseRoundCaps = positiveSegments.length == 1 ||
          rawSweep >=
              visibleGapAngle + (capExtensionAngle * 2) + minimumRoundedSweep;

      if (!canUseRoundCaps && positiveSegments.length > 1) {
        final maxDotRadius =
            math.max(2.0, ((rawSweep - visibleGapAngle) * radius) / 2);
        final dotRadius = math.min(segmentStrokeWidth / 2, maxDotRadius);
        arcs.add(
          _BudgetMixDonutArc.dot(
            color: segment.color,
            centerAngle: cursor + rawSweep / 2,
            dotRadius: dotRadius,
            dotArcRadius: radius,
          ),
        );
      } else {
        final gap = positiveSegments.length == 1
            ? 0.0
            : visibleGapAngle + capExtensionAngle * 2;
        final sweep = math.max(0.0, rawSweep - gap);
        arcs.add(
          _BudgetMixDonutArc(
            color: segment.color,
            startAngle: cursor + gap / 2,
            sweepAngle: sweep,
            strokeCap: StrokeCap.round,
            capExtensionAngle: capExtensionAngle,
          ),
        );
      }
      cursor += rawSweep;
    }

    return arcs;
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

class _BudgetMixDonutArc {
  const _BudgetMixDonutArc({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.strokeCap,
    required this.capExtensionAngle,
  })  : isDot = false,
        centerAngle = 0,
        dotRadius = 0,
        dotArcRadius = 0;

  const _BudgetMixDonutArc.dot({
    required this.color,
    required this.centerAngle,
    required this.dotRadius,
    required this.dotArcRadius,
  })  : startAngle = centerAngle,
        sweepAngle = 0,
        strokeCap = StrokeCap.round,
        capExtensionAngle = 0,
        isDot = true;

  final Color color;
  final double startAngle;
  final double sweepAngle;
  final StrokeCap strokeCap;
  final double capExtensionAngle;
  final bool isDot;
  final double centerAngle;
  final double dotRadius;
  final double dotArcRadius;

  double get visualStartAngle => isDot
      ? centerAngle - (dotRadius / dotArcRadius)
      : startAngle - capExtensionAngle;
  double get visualEndAngle => isDot
      ? centerAngle + (dotRadius / dotArcRadius)
      : startAngle + sweepAngle + capExtensionAngle;
}

class BudgetMixPill extends StatefulWidget {
  const BudgetMixPill({
    super.key,
    required this.index,
    required this.category,
    required this.share,
    this.type,
    this.active = false,
    this.shakeSerial = 0,
  });

  final int index;
  final String category;
  final double share;
  final String? type;
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
    final accent = BudgetMixPalette.colorForCategory(
      widget.category,
      context,
      type: widget.type,
    );
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
