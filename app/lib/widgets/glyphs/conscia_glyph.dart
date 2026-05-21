import 'package:flutter/material.dart';

import 'conscia_glyph_kind.dart';
import 'conscia_glyph_mapper.dart';
import 'painters/category_glyph_painter.dart';
import 'painters/glyph_painter_primitives.dart';
import 'painters/journey_glyph_painter.dart';
import 'painters/money_glyph_painter.dart';
import 'painters/utility_glyph_painter.dart';

class ConsciaGlyph extends StatelessWidget {
  const ConsciaGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  });

  ConsciaGlyph.category(
    String category, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = ConsciaGlyphMapper.category(category);

  ConsciaGlyph.quest(
    String questKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = ConsciaGlyphMapper.quest(questKey);

  ConsciaGlyph.milestone(
    String badgeKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
    bool unlocked = true,
  }) : kind = unlocked
            ? ConsciaGlyphMapper.milestone(badgeKey)
            : ConsciaGlyphKind.lock;

  ConsciaGlyph.level(
    String levelKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = ConsciaGlyphMapper.level(levelKey);

  final ConsciaGlyphKind kind;
  final Color color;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ConsciaGlyphPainter(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth ?? (size * 0.1).clamp(1.6, 2.4),
        ),
      ),
    );
  }
}

class _ConsciaGlyphPainter extends CustomPainter {
  const _ConsciaGlyphPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  final ConsciaGlyphKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final g = GlyphPainterPrimitives(size);

    final painted =
        paintJourneyGlyph(canvas, g, kind, stroke, fill) ||
        paintMoneyGlyph(canvas, g, kind, stroke, fill) ||
        paintCategoryGlyph(canvas, g, kind, stroke, fill) ||
        paintUtilityGlyph(canvas, g, kind, stroke, fill);

    if (!painted) {
      paintUtilityGlyph(canvas, g, ConsciaGlyphKind.more, stroke, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _ConsciaGlyphPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
