import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../conscia_glyph_kind.dart';
import 'glyph_painter_primitives.dart';

bool paintCategoryGlyph(
  Canvas canvas,
  GlyphPainterPrimitives g,
  ConsciaGlyphKind kind,
  Paint stroke,
  Paint fill,
) {
  switch (kind) {
    case ConsciaGlyphKind.dining:
      _dining(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.groceries:
      _groceries(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.transport:
      _transport(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.entertainment:
      _ticket(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.gaming:
      _gaming(canvas, g, stroke, fill);
      return true;
    case ConsciaGlyphKind.shopping:
      _shopping(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.health:
      _health(canvas, g, fill);
      return true;
    case ConsciaGlyphKind.education:
      _education(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.travel:
      _travel(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.coffee:
      _coffee(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.subscription:
      _subscription(canvas, g, stroke);
      return true;
    default:
      return false;
  }
}

void _dining(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawLine(g.point(.32, .18), g.point(.32, .82), p);
  canvas.drawLine(g.point(.22, .20), g.point(.22, .42), p);
  canvas.drawLine(g.point(.32, .20), g.point(.32, .42), p);
  canvas.drawLine(g.point(.42, .20), g.point(.42, .42), p);
  canvas.drawLine(g.point(.62, .18), g.point(.62, .82), p);
  canvas.drawArc(g.rect(.55, .16, .22, .38), -math.pi / 2, math.pi, false, p);
}

void _groceries(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.22, .34, .56, .44, .08), p);
  canvas.drawArc(g.rect(.34, .18, .32, .34), math.pi, math.pi, false, p);
}

void _transport(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawRRect(g.rrect(.18, .42, .64, .24, .08), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .30, size.height * .42)
      ..lineTo(size.width * .40, size.height * .28)
      ..lineTo(size.width * .62, size.height * .28)
      ..lineTo(size.width * .72, size.height * .42),
    p,
  );
  canvas.drawCircle(g.point(.32, .72), size.width * .045, p);
  canvas.drawCircle(g.point(.68, .72), size.width * .045, p);
}

void _ticket(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.save();
  canvas.translate(g.size.width * .5, g.size.height * .5);
  canvas.rotate(-0.16);
  canvas.translate(-g.size.width * .5, -g.size.height * .5);
  canvas.drawRRect(g.rrect(.18, .30, .64, .40, .08), p);
  canvas.drawLine(g.point(.48, .34), g.point(.48, .66), p);
  canvas.restore();
}

void _gaming(
  Canvas canvas,
  GlyphPainterPrimitives g,
  Paint p,
  Paint f,
) {
  final size = g.size;
  final body = Path()
    ..moveTo(size.width * .26, size.height * .42)
    ..quadraticBezierTo(size.width * .30, size.height * .28,
        size.width * .44, size.height * .34)
    ..lineTo(size.width * .56, size.height * .34)
    ..quadraticBezierTo(size.width * .70, size.height * .28,
        size.width * .74, size.height * .42)
    ..lineTo(size.width * .82, size.height * .64)
    ..quadraticBezierTo(size.width * .86, size.height * .78,
        size.width * .72, size.height * .76)
    ..quadraticBezierTo(size.width * .62, size.height * .74,
        size.width * .58, size.height * .64)
    ..lineTo(size.width * .42, size.height * .64)
    ..quadraticBezierTo(size.width * .38, size.height * .74,
        size.width * .28, size.height * .76)
    ..quadraticBezierTo(size.width * .14, size.height * .78,
        size.width * .18, size.height * .64)
    ..close();
  canvas.drawPath(body, p);
  canvas.drawLine(g.point(.30, .52), g.point(.44, .52), p);
  canvas.drawLine(g.point(.37, .45), g.point(.37, .59), p);
  canvas.drawCircle(g.point(.62, .50), size.width * .035, f);
  canvas.drawCircle(g.point(.72, .56), size.width * .035, f);
}

void _shopping(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.24, .30, .52, .50, .08), p);
  canvas.drawArc(g.rect(.36, .18, .28, .28), math.pi, math.pi, false, p);
}

void _health(Canvas canvas, GlyphPainterPrimitives g, Paint f) {
  final size = g.size;
  final path = Path()
    ..moveTo(size.width * .50, size.height * .78)
    ..cubicTo(size.width * .15, size.height * .50, size.width * .18,
        size.height * .22, size.width * .38, size.height * .25)
    ..cubicTo(size.width * .46, size.height * .26, size.width * .50,
        size.height * .34, size.width * .50, size.height * .34)
    ..cubicTo(size.width * .50, size.height * .34, size.width * .56,
        size.height * .24, size.width * .67, size.height * .25)
    ..cubicTo(size.width * .87, size.height * .28, size.width * .84,
        size.height * .55, size.width * .50, size.height * .78);
  canvas.drawPath(path, f);
}

void _education(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .20, size.height * .25)
      ..quadraticBezierTo(size.width * .36, size.height * .18,
          size.width * .50, size.height * .32)
      ..quadraticBezierTo(size.width * .64, size.height * .18,
          size.width * .80, size.height * .25)
      ..lineTo(size.width * .80, size.height * .74)
      ..quadraticBezierTo(size.width * .64, size.height * .68,
          size.width * .50, size.height * .80)
      ..quadraticBezierTo(size.width * .36, size.height * .68,
          size.width * .20, size.height * .74)
      ..close(),
    p,
  );
  canvas.drawLine(g.point(.50, .32), g.point(.50, .80), p);
}

void _travel(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .16, size.height * .54)
      ..lineTo(size.width * .84, size.height * .26)
      ..lineTo(size.width * .62, size.height * .78)
      ..lineTo(size.width * .50, size.height * .58)
      ..lineTo(size.width * .32, size.height * .68)
      ..close(),
    p,
  );
}

void _coffee(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.24, .36, .44, .34, .08), p);
  canvas.drawArc(g.rect(.58, .42, .22, .22), -math.pi / 2, math.pi, false, p);
  canvas.drawLine(g.point(.22, .78), g.point(.72, .78), p);
}

void _subscription(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawArc(g.rect(.20, .22, .58, .56), .2, math.pi * 1.45, false, p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .73, g.size.height * .22)
      ..lineTo(g.size.width * .82, g.size.height * .36)
      ..lineTo(g.size.width * .65, g.size.height * .36),
    p,
  );
}
