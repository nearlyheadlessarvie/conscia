import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../conscia_glyph_kind.dart';
import 'glyph_painter_primitives.dart';

bool paintJourneyGlyph(
  Canvas canvas,
  GlyphPainterPrimitives g,
  ConsciaGlyphKind kind,
  Paint stroke,
  Paint fill,
) {
  switch (kind) {
    case ConsciaGlyphKind.trail:
      _trail(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.reflect:
      _reflect(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.pause:
      _pause(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.insight:
      _insight(canvas, g, stroke, fill);
      return true;
    case ConsciaGlyphKind.signal:
      _signal(canvas, g, stroke, fill);
      return true;
    case ConsciaGlyphKind.shield:
      _shield(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.family:
      _family(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.recurring:
      _recurring(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.trophy:
      _trophy(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.lock:
      _lock(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.sprout:
      _sprout(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.compass:
      _compass(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.crown:
      _crown(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.monk:
      _monk(canvas, g, stroke);
      return true;
    default:
      return false;
  }
}

void _trail(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.26, .18, .48, .64, .06), p);
  canvas.drawCircle(g.point(.38, .36), g.size.width * .025, p);
  canvas.drawCircle(g.point(.50, .50), g.size.width * .025, p);
  canvas.drawCircle(g.point(.62, .64), g.size.width * .025, p);
}

void _reflect(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawRRect(g.rrect(.22, .22, .50, .50, .08), p);
  canvas.drawLine(g.point(.34, .38), g.point(.60, .38), p);
  canvas.drawLine(g.point(.34, .52), g.point(.52, .52), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .70, size.height * .64)
      ..lineTo(size.width * .82, size.height * .78)
      ..lineTo(size.width * .56, size.height * .78),
    p,
  );
}

void _pause(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.50, .50), g.size.width * .30, p);
  canvas.drawLine(g.point(.42, .36), g.point(.42, .64), p);
  canvas.drawLine(g.point(.58, .36), g.point(.58, .64), p);
}

void _insight(Canvas canvas, GlyphPainterPrimitives g, Paint p, Paint f) {
  for (final item in const [(.34, .62), (.50, .48), (.66, .34)]) {
    canvas.drawLine(g.point(item.$1, .76), g.point(item.$1, item.$2), p);
  }
  canvas.drawCircle(g.point(.50, .22), g.size.width * .045, f);
}

void _signal(Canvas canvas, GlyphPainterPrimitives g, Paint p, Paint f) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .18, size.height * .70)
      ..cubicTo(size.width * .32, size.height * .50, size.width * .42,
          size.height * .76, size.width * .56, size.height * .50)
      ..cubicTo(size.width * .66, size.height * .32, size.width * .76,
          size.height * .34, size.width * .84, size.height * .26),
    p,
  );
  canvas.drawCircle(g.point(.84, .26), size.width * .045, f);
}

void _shield(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .50, size.height * .16)
      ..lineTo(size.width * .76, size.height * .26)
      ..lineTo(size.width * .72, size.height * .56)
      ..quadraticBezierTo(size.width * .66, size.height * .72,
          size.width * .50, size.height * .84)
      ..quadraticBezierTo(size.width * .34, size.height * .72,
          size.width * .28, size.height * .56)
      ..lineTo(size.width * .24, size.height * .26)
      ..close(),
    p,
  );
}

void _family(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.42, .34), g.size.width * .08, p);
  canvas.drawCircle(g.point(.65, .40), g.size.width * .07, p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .24, g.size.height * .76)
      ..quadraticBezierTo(
          g.size.width * .42, g.size.height * .54, g.size.width * .60, g.size.height * .76),
    p,
  );
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .50, g.size.height * .78)
      ..quadraticBezierTo(
          g.size.width * .65, g.size.height * .60, g.size.width * .82, g.size.height * .78),
    p,
  );
}

void _recurring(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawArc(g.rect(.20, .22, .58, .56), .2, math.pi * 1.45, false, p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .73, g.size.height * .22)
      ..lineTo(g.size.width * .82, g.size.height * .36)
      ..lineTo(g.size.width * .65, g.size.height * .36),
    p,
  );
}

void _trophy(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .34, size.height * .22)
      ..lineTo(size.width * .66, size.height * .22)
      ..lineTo(size.width * .62, size.height * .52)
      ..quadraticBezierTo(size.width * .50, size.height * .64,
          size.width * .38, size.height * .52)
      ..close(),
    p,
  );
  canvas.drawLine(g.point(.50, .64), g.point(.50, .78), p);
  canvas.drawLine(g.point(.34, .80), g.point(.66, .80), p);
  canvas.drawArc(g.rect(.18, .26, .20, .24), -math.pi / 2, math.pi, false, p);
  canvas.drawArc(g.rect(.62, .26, .20, .24), math.pi / 2, math.pi, false, p);
}

void _lock(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.24, .42, .52, .34, .08), p);
  canvas.drawArc(g.rect(.34, .20, .32, .36), math.pi, math.pi, false, p);
}

void _sprout(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawLine(g.point(.50, .80), g.point(.50, .38), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .50, size.height * .52)
      ..quadraticBezierTo(size.width * .28, size.height * .42,
          size.width * .26, size.height * .24)
      ..quadraticBezierTo(size.width * .44, size.height * .24,
          size.width * .50, size.height * .52),
    p,
  );
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .50, size.height * .48)
      ..quadraticBezierTo(size.width * .70, size.height * .36,
          size.width * .76, size.height * .20)
      ..quadraticBezierTo(size.width * .58, size.height * .22,
          size.width * .50, size.height * .48),
    p,
  );
}

void _compass(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawCircle(g.point(.50, .50), size.width * .32, p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .60, size.height * .28)
      ..lineTo(size.width * .52, size.height * .58)
      ..lineTo(size.width * .34, size.height * .70)
      ..lineTo(size.width * .42, size.height * .40)
      ..close(),
    p,
  );
}

void _crown(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .22, size.height * .68)
      ..lineTo(size.width * .28, size.height * .34)
      ..lineTo(size.width * .44, size.height * .52)
      ..lineTo(size.width * .50, size.height * .28)
      ..lineTo(size.width * .56, size.height * .52)
      ..lineTo(size.width * .72, size.height * .34)
      ..lineTo(size.width * .78, size.height * .68)
      ..close(),
    p,
  );
}

void _monk(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.50, .34), g.size.width * .16, p);
  canvas.drawArc(g.rect(.24, .46, .52, .38), math.pi, math.pi, false, p);
  canvas.drawLine(g.point(.34, .70), g.point(.66, .70), p);
}
