import 'package:flutter/material.dart';

import '../conscia_glyph_kind.dart';
import 'glyph_painter_primitives.dart';

bool paintMoneyGlyph(
  Canvas canvas,
  GlyphPainterPrimitives g,
  ConsciaGlyphKind kind,
  Paint stroke,
  Paint fill,
) {
  switch (kind) {
    case ConsciaGlyphKind.income:
      _income(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.salary:
      _salary(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.freelance:
    case ConsciaGlyphKind.work:
      _briefcase(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.business:
      _storefront(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.investment:
      _investment(canvas, g, stroke, fill);
      return true;
    case ConsciaGlyphKind.rentalIncome:
      _rentalIncome(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.bonus:
      _bonus(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.wallet:
      _wallet(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.card:
      _card(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.cash:
      _cash(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.bank:
      _bank(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.transfer:
      _transfer(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.refund:
      _refund(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.fee:
      _fee(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.debt:
      _debt(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.savings:
      _savings(canvas, g, stroke);
      return true;
    default:
      return false;
  }
}

void _income(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawLine(g.point(.50, .18), g.point(.50, .80), p);
  canvas.drawArc(g.rect(.34, .20, .28, .24), -1.57, 4.71, false, p);
  canvas.drawArc(g.rect(.38, .54, .28, .24), 1.57, 4.71, false, p);
}

void _salary(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawRRect(g.rrect(.20, .34, .60, .42, .07), p);
  canvas.drawCircle(g.point(.50, .55), size.width * .11, p);
  canvas.drawLine(g.point(.30, .22), g.point(.70, .22), p);
  canvas.drawLine(g.point(.36, .22), g.point(.36, .34), p);
  canvas.drawLine(g.point(.64, .22), g.point(.64, .34), p);
}

void _briefcase(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawRRect(g.rrect(.18, .34, .64, .42, .08), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .38, size.height * .34)
      ..lineTo(size.width * .38, size.height * .24)
      ..lineTo(size.width * .62, size.height * .24)
      ..lineTo(size.width * .62, size.height * .34),
    p,
  );
  canvas.drawLine(g.point(.20, .50), g.point(.80, .50), p);
}

void _storefront(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawRRect(g.rrect(.22, .42, .56, .34, .06), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .22, size.height * .42)
      ..lineTo(size.width * .30, size.height * .24)
      ..lineTo(size.width * .70, size.height * .24)
      ..lineTo(size.width * .78, size.height * .42),
    p,
  );
  for (final x in const [.36, .50, .64]) {
    canvas.drawLine(g.point(x, .26), g.point(x, .42), p);
  }
  canvas.drawLine(g.point(.34, .76), g.point(.34, .58), p);
}

void _investment(
  Canvas canvas,
  GlyphPainterPrimitives g,
  Paint p,
  Paint f,
) {
  final size = g.size;
  canvas.drawLine(g.point(.22, .76), g.point(.22, .60), p);
  canvas.drawLine(g.point(.40, .76), g.point(.40, .52), p);
  canvas.drawLine(g.point(.58, .76), g.point(.58, .42), p);
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .20, size.height * .50)
      ..lineTo(size.width * .40, size.height * .42)
      ..lineTo(size.width * .56, size.height * .48)
      ..lineTo(size.width * .78, size.height * .24),
    p,
  );
  canvas.drawCircle(g.point(.78, .24), size.width * .04, f);
}

void _rentalIncome(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  _homeShape(canvas, g, p);
  canvas.drawCircle(g.point(.66, .56), g.size.width * .055, p);
  canvas.drawLine(g.point(.70, .60), g.point(.82, .72), p);
  canvas.drawLine(g.point(.77, .67), g.point(.72, .72), p);
}

void _bonus(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .50, size.height * .18)
      ..lineTo(size.width * .58, size.height * .40)
      ..lineTo(size.width * .80, size.height * .42)
      ..lineTo(size.width * .62, size.height * .56)
      ..lineTo(size.width * .68, size.height * .78)
      ..lineTo(size.width * .50, size.height * .66)
      ..lineTo(size.width * .32, size.height * .78)
      ..lineTo(size.width * .38, size.height * .56)
      ..lineTo(size.width * .20, size.height * .42)
      ..lineTo(size.width * .42, size.height * .40)
      ..close(),
    p,
  );
}

void _wallet(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.16, .30, .64, .44, .08), p);
  canvas.drawRRect(g.rrect(.52, .40, .28, .18, .05), p);
  canvas.drawCircle(g.point(.66, .49), g.size.width * .02, p);
}

void _card(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.16, .28, .68, .44, .07), p);
  canvas.drawLine(g.point(.18, .42), g.point(.82, .42), p);
  canvas.drawLine(g.point(.28, .58), g.point(.44, .58), p);
  canvas.drawLine(g.point(.56, .58), g.point(.72, .58), p);
}

void _cash(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawRRect(g.rrect(.16, .30, .68, .40, .07), p);
  canvas.drawCircle(g.point(.50, .50), g.size.width * .11, p);
  canvas.drawArc(g.rect(.18, .32, .14, .14), 0, 1.57, false, p);
  canvas.drawArc(g.rect(.68, .54, .14, .14), 3.14, 1.57, false, p);
}

void _bank(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .16, size.height * .36)
      ..lineTo(size.width * .50, size.height * .20)
      ..lineTo(size.width * .84, size.height * .36)
      ..close(),
    p,
  );
  canvas.drawLine(g.point(.22, .78), g.point(.78, .78), p);
  for (final x in const [.28, .50, .72]) {
    canvas.drawLine(g.point(x, .40), g.point(x, .70), p);
  }
}

void _transfer(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .20, size.height * .34)
      ..lineTo(size.width * .72, size.height * .34)
      ..lineTo(size.width * .60, size.height * .22),
    p,
  );
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .80, size.height * .66)
      ..lineTo(size.width * .28, size.height * .66)
      ..lineTo(size.width * .40, size.height * .78),
    p,
  );
}

void _refund(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .38, g.size.height * .28)
      ..lineTo(g.size.width * .22, g.size.height * .28)
      ..lineTo(g.size.width * .22, g.size.height * .14),
    p,
  );
  canvas.drawArc(g.rect(.22, .24, .54, .54), 3.14, 4.24, false, p);
  canvas.drawCircle(g.point(.60, .60), g.size.width * .12, p);
}

void _fee(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawCircle(g.point(.50, .50), g.size.width * .30, p);
  canvas.drawLine(g.point(.32, .68), g.point(.68, .32), p);
  canvas.drawCircle(g.point(.38, .38), g.size.width * .05, p);
  canvas.drawCircle(g.point(.62, .62), g.size.width * .05, p);
}

void _debt(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  canvas.drawArc(g.rect(.22, .22, .56, .56), -0.63, 4.55, false, p);
  canvas.drawPath(
    Path()
      ..moveTo(g.size.width * .24, g.size.height * .66)
      ..lineTo(g.size.width * .22, g.size.height * .50)
      ..lineTo(g.size.width * .38, g.size.height * .52),
    p,
  );
  canvas.drawLine(g.point(.50, .34), g.point(.50, .60), p);
  canvas.drawLine(g.point(.38, .50), g.point(.50, .60), p);
  canvas.drawLine(g.point(.62, .50), g.point(.50, .60), p);
}

void _savings(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
  final size = g.size;
  canvas.drawPath(
    Path()
      ..moveTo(size.width * .26, size.height * .56)
      ..cubicTo(size.width * .26, size.height * .38, size.width * .42,
          size.height * .28, size.width * .58, size.height * .30)
      ..lineTo(size.width * .74, size.height * .30)
      ..lineTo(size.width * .70, size.height * .40)
      ..cubicTo(size.width * .78, size.height * .44, size.width * .82,
          size.height * .52, size.width * .82, size.height * .60)
      ..cubicTo(size.width * .82, size.height * .74, size.width * .68,
          size.height * .82, size.width * .50, size.height * .82)
      ..cubicTo(size.width * .34, size.height * .82, size.width * .26,
          size.height * .72, size.width * .26, size.height * .56)
      ..close(),
    p,
  );
  canvas.drawLine(g.point(.40, .22), g.point(.58, .22), p);
}

void _homeShape(Canvas canvas, GlyphPainterPrimitives g, Paint p) {
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
