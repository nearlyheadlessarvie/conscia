import 'package:flutter/material.dart';

class GlyphPainterPrimitives {
  const GlyphPainterPrimitives(this.size);

  final Size size;

  Offset point(double x, double y) => Offset(size.width * x, size.height * y);

  Rect rect(double x, double y, double w, double h) => Rect.fromLTWH(
        size.width * x,
        size.height * y,
        size.width * w,
        size.height * h,
      );

  RRect rrect(double x, double y, double w, double h, double radius) =>
      RRect.fromRectAndRadius(
        rect(x, y, w, h),
        Radius.circular(size.width * radius),
      );

  void dot(Canvas canvas, double x, double y, Paint fill, [double radius = 0.07]) {
    canvas.drawCircle(point(x, y), size.width * radius, fill);
  }
}
