import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../conscia_glyph_kind.dart';
import 'glyph_painter_primitives.dart';

bool paintUtilityGlyph(
  Canvas canvas,
  GlyphPainterPrimitives g,
  ConsciaGlyphKind kind,
  Paint stroke,
  Paint fill,
) {
  switch (kind) {
    case ConsciaGlyphKind.receipt:
    case ConsciaGlyphKind.bills:
      _receipt(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.home:
      _home(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.gift:
      _gift(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.calendar:
      _calendar(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.alert:
      _alert(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.check:
      _check(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.more:
      _more(canvas, g, fill);
      return true;
    default:
      return false;
  }
}

void _receipt(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.28, .16, .44, .68, .05), p);
  canvas.drawLine(g.point(.38, .34), g.point(.62, .34), p);
  canvas.drawLine(g.point(.38, .50), g.point(.58, .50), p);
  canvas.drawLine(g.point(.38, .66), g.point(.52, .66), p);
}

void _home(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .18, size.height * .48)
      ..lineTo(size.width * .50, size.height * .20)
      ..lineTo(size.width * .82, size.height * .48)
      ..lineTo(size.width * .74, size.height * .48)
      ..lineTo(size.width * .74, size.height * .80)
      ..lineTo(size.width * .26, size.height * .80)
      ..lineTo(size.width * .26, size.height * .48)
      ..close(),
    p,
  );
}

void _gift(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.20, .36, .60, .42, .05), p);
  canvas.drawLine(g.point(.50, .28), g.point(.50, .78), p);
  canvas.drawLine(g.point(.20, .48), g.point(.80, .48), p);
  canvas.drawArc(g.rect(.28, .20, .22, .18), 0, math.pi * 1.8, false, p);
  canvas.drawArc(g.rect(.50, .20, .22, .18), math.pi, math.pi * 1.8, false, p);
}

void _calendar(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.22, .24, .56, .56, .08), p);
  canvas.drawLine(g.point(.22, .40), g.point(.78, .40), p);
  canvas.drawLine(g.point(.34, .18), g.point(.34, .32), p);
  canvas.drawLine(g.point(.66, .18), g.point(.66, .32), p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .36, g.size.height * .60)
      ..lineTo(g.size.width * .46, g.size.height * .70)
      ..lineTo(g.size.width * .64, g.size.height * .52),
    p,
  );
}

void _alert(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.50, .50), g.size.width * .30, p);
  canvas.drawLine(g.point(.50, .34), g.point(.50, .56), p);
  canvas.drawLine(g.point(.50, .66), g.point(.50, .68), p);
}

void _check(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.50, .50), g.size.width * .30, p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .34, g.size.height * .52)
      ..lineTo(g.size.width * .46, g.size.height * .64)
      ..lineTo(g.size.width * .68, g.size.height * .42),
    p,
  );
}

void _more(Canvas canvas, GlyphPainterPrimitives g, Paint f) {
  for (final x in const [.32, .50, .68]) {
    canvas.drawCircle(g.point(x, .50), g.size.width * .07, f);
  }
}
