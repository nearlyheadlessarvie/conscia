import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ConsciaGlyphKind {
  trail,
  receipt,
  reflect,
  pause,
  insight,
  signal,
  shield,
  family,
  recurring,
  income,
  dining,
  groceries,
  transport,
  entertainment,
  shopping,
  health,
  bills,
  education,
  travel,
  coffee,
  subscription,
  work,
  home,
  gift,
  trophy,
  lock,
  sprout,
  compass,
  crown,
  monk,
  more,
}

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
  }) : kind = _categoryKind(category);

  ConsciaGlyph.quest(
    String questKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = _questKind(questKey);

  ConsciaGlyph.milestone(
    String badgeKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
    bool unlocked = true,
  }) : kind = unlocked ? _milestoneKind(badgeKey) : ConsciaGlyphKind.lock;

  ConsciaGlyph.level(
    String levelKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = _levelKind(levelKey);

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

  static ConsciaGlyphKind _categoryKind(String category) {
    final normalized = _normalize(category);
    return switch (normalized) {
      'dining' => ConsciaGlyphKind.dining,
      'groceries' => ConsciaGlyphKind.groceries,
      'transport' || 'fuel' || 'parking' => ConsciaGlyphKind.transport,
      'entertainment' || 'gaming' || 'events' => ConsciaGlyphKind.entertainment,
      'shopping' || 'clothing' || 'beauty' => ConsciaGlyphKind.shopping,
      'health' || 'pharmacy' || 'fitness' => ConsciaGlyphKind.health,
      'bills' ||
      'taxes' ||
      'utilities' ||
      'phone' ||
      'internet' =>
        ConsciaGlyphKind.bills,
      'education' || 'books' => ConsciaGlyphKind.education,
      'travel' => ConsciaGlyphKind.travel,
      'coffee' => ConsciaGlyphKind.coffee,
      'subscriptions' => ConsciaGlyphKind.subscription,
      'salary' ||
      'freelance' ||
      'business' ||
      'investment' ||
      'rental-income' ||
      'bonus' =>
        ConsciaGlyphKind.income,
      'home' || 'repairs' => ConsciaGlyphKind.home,
      'gift' || 'charity' || 'pets' || 'childcare' => ConsciaGlyphKind.gift,
      'insurance' => ConsciaGlyphKind.shield,
      _ => ConsciaGlyphKind.more,
    };
  }

  static ConsciaGlyphKind _questKind(String key) {
    return switch (_normalize(key)) {
      'reflect-three-purchases' => ConsciaGlyphKind.reflect,
      'check-before-purchase' => ConsciaGlyphKind.pause,
      'review-regret-pattern' => ConsciaGlyphKind.recurring,
      'read-two-insights' => ConsciaGlyphKind.insight,
      'create-budget-guardrail' => ConsciaGlyphKind.shield,
      'send-family-invite' => ConsciaGlyphKind.family,
      'add-family-expense' => ConsciaGlyphKind.receipt,
      _ => ConsciaGlyphKind.trail,
    };
  }

  static ConsciaGlyphKind _milestoneKind(String key) {
    return switch (_normalize(key)) {
      'first-reflection' => ConsciaGlyphKind.reflect,
      'pause-before-purchase' || 'pre-purchase-habit' => ConsciaGlyphKind.pause,
      'budget-rescuer' => ConsciaGlyphKind.shield,
      'regret-pattern-spotted' ||
      'reflection-streak' =>
        ConsciaGlyphKind.signal,
      'worth-it-week' => ConsciaGlyphKind.trophy,
      'family-founder' || 'family-planner' => ConsciaGlyphKind.family,
      'insight-reader' || 'deep-thinker' => ConsciaGlyphKind.insight,
      _ => ConsciaGlyphKind.trophy,
    };
  }

  static ConsciaGlyphKind _levelKind(String key) {
    return switch (_normalize(key)) {
      'awakening' => ConsciaGlyphKind.sprout,
      'impulse-spotter' => ConsciaGlyphKind.signal,
      'budget-guardian' => ConsciaGlyphKind.shield,
      'conscience-captain' => ConsciaGlyphKind.compass,
      'money-monk' => ConsciaGlyphKind.monk,
      _ => ConsciaGlyphKind.crown,
    };
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
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

    switch (kind) {
      case ConsciaGlyphKind.dining:
        _dining(canvas, size, stroke);
      case ConsciaGlyphKind.groceries:
        _bag(canvas, size, stroke);
      case ConsciaGlyphKind.transport:
        _car(canvas, size, stroke);
      case ConsciaGlyphKind.entertainment:
        _ticket(canvas, size, stroke);
      case ConsciaGlyphKind.shopping:
        _shopping(canvas, size, stroke);
      case ConsciaGlyphKind.health:
        _heart(canvas, size, fill);
      case ConsciaGlyphKind.bills:
        _receipt(canvas, size, stroke);
      case ConsciaGlyphKind.education:
        _book(canvas, size, stroke);
      case ConsciaGlyphKind.travel:
        _plane(canvas, size, stroke);
      case ConsciaGlyphKind.coffee:
        _cup(canvas, size, stroke);
      case ConsciaGlyphKind.subscription:
      case ConsciaGlyphKind.recurring:
        _loop(canvas, size, stroke);
      case ConsciaGlyphKind.income:
      case ConsciaGlyphKind.work:
        _income(canvas, size, stroke);
      case ConsciaGlyphKind.home:
        _home(canvas, size, stroke);
      case ConsciaGlyphKind.gift:
        _gift(canvas, size, stroke);
      case ConsciaGlyphKind.reflect:
        _reflect(canvas, size, stroke);
      case ConsciaGlyphKind.pause:
        _pause(canvas, size, stroke);
      case ConsciaGlyphKind.insight:
        _insight(canvas, size, stroke, fill);
      case ConsciaGlyphKind.signal:
        _signal(canvas, size, stroke, fill);
      case ConsciaGlyphKind.shield:
        _shield(canvas, size, stroke);
      case ConsciaGlyphKind.family:
        _family(canvas, size, stroke, fill);
      case ConsciaGlyphKind.receipt:
      case ConsciaGlyphKind.trail:
        _trail(canvas, size, stroke);
      case ConsciaGlyphKind.trophy:
        _trophy(canvas, size, stroke);
      case ConsciaGlyphKind.lock:
        _lock(canvas, size, stroke);
      case ConsciaGlyphKind.sprout:
        _sprout(canvas, size, stroke);
      case ConsciaGlyphKind.compass:
        _compass(canvas, size, stroke, fill);
      case ConsciaGlyphKind.crown:
        _crown(canvas, size, stroke);
      case ConsciaGlyphKind.monk:
        _monk(canvas, size, stroke);
      case ConsciaGlyphKind.more:
        _more(canvas, size, fill);
    }
  }

  void _dining(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(_o(s, .32, .18), _o(s, .32, .82), p);
    canvas.drawLine(_o(s, .22, .2), _o(s, .22, .42), p);
    canvas.drawLine(_o(s, .32, .2), _o(s, .32, .42), p);
    canvas.drawLine(_o(s, .42, .2), _o(s, .42, .42), p);
    canvas.drawLine(_o(s, .62, .18), _o(s, .62, .82), p);
    canvas.drawArc(_r(s, .55, .16, .22, .38), -math.pi / 2, math.pi, false, p);
  }

  void _bag(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .22, .34, .56, .44, .08), p);
    canvas.drawArc(_r(s, .34, .18, .32, .34), math.pi, math.pi, false, p);
  }

  void _car(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .18, .42, .64, .24, .08), p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .3, s.height * .42)
          ..lineTo(s.width * .4, s.height * .28)
          ..lineTo(s.width * .62, s.height * .28)
          ..lineTo(s.width * .72, s.height * .42),
        p);
    canvas.drawCircle(_o(s, .32, .72), s.width * .045, p);
    canvas.drawCircle(_o(s, .68, .72), s.width * .045, p);
  }

  void _ticket(Canvas canvas, Size s, Paint p) {
    canvas.save();
    canvas.translate(s.width * .5, s.height * .5);
    canvas.rotate(-0.16);
    canvas.translate(-s.width * .5, -s.height * .5);
    canvas.drawRRect(_rr(s, .18, .3, .64, .4, .08), p);
    canvas.drawLine(_o(s, .48, .34), _o(s, .48, .66), p);
    canvas.restore();
  }

  void _shopping(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .24, .3, .52, .5, .08), p);
    canvas.drawArc(_r(s, .36, .18, .28, .28), math.pi, math.pi, false, p);
  }

  void _heart(Canvas canvas, Size s, Paint f) {
    final path = Path()
      ..moveTo(s.width * .5, s.height * .78)
      ..cubicTo(s.width * .15, s.height * .5, s.width * .18, s.height * .22,
          s.width * .38, s.height * .25)
      ..cubicTo(s.width * .46, s.height * .26, s.width * .5, s.height * .34,
          s.width * .5, s.height * .34)
      ..cubicTo(s.width * .5, s.height * .34, s.width * .56, s.height * .24,
          s.width * .67, s.height * .25)
      ..cubicTo(s.width * .87, s.height * .28, s.width * .84, s.height * .55,
          s.width * .5, s.height * .78);
    canvas.drawPath(path, f);
  }

  void _receipt(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .28, .16, .44, .68, .05), p);
    canvas.drawLine(_o(s, .38, .34), _o(s, .62, .34), p);
    canvas.drawLine(_o(s, .38, .5), _o(s, .58, .5), p);
    canvas.drawLine(_o(s, .38, .66), _o(s, .52, .66), p);
  }

  void _book(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .2, s.height * .25)
          ..quadraticBezierTo(
              s.width * .36, s.height * .18, s.width * .5, s.height * .32)
          ..quadraticBezierTo(
              s.width * .64, s.height * .18, s.width * .8, s.height * .25)
          ..lineTo(s.width * .8, s.height * .74)
          ..quadraticBezierTo(
              s.width * .64, s.height * .68, s.width * .5, s.height * .8)
          ..quadraticBezierTo(
              s.width * .36, s.height * .68, s.width * .2, s.height * .74)
          ..close(),
        p);
    canvas.drawLine(_o(s, .5, .32), _o(s, .5, .8), p);
  }

  void _plane(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .16, s.height * .54)
          ..lineTo(s.width * .84, s.height * .26)
          ..lineTo(s.width * .62, s.height * .78)
          ..lineTo(s.width * .5, s.height * .58)
          ..lineTo(s.width * .32, s.height * .68)
          ..close(),
        p);
  }

  void _cup(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .24, .36, .44, .34, .08), p);
    canvas.drawArc(_r(s, .58, .42, .22, .22), -math.pi / 2, math.pi, false, p);
    canvas.drawLine(_o(s, .22, .78), _o(s, .72, .78), p);
  }

  void _loop(Canvas canvas, Size s, Paint p) {
    canvas.drawArc(_r(s, .2, .22, .58, .56), .2, math.pi * 1.45, false, p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .73, s.height * .22)
          ..lineTo(s.width * .82, s.height * .36)
          ..lineTo(s.width * .65, s.height * .36),
        p);
  }

  void _income(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(_o(s, .5, .18), _o(s, .5, .8), p);
    canvas.drawArc(
        _r(s, .34, .2, .28, .24), -math.pi / 2, math.pi * 1.5, false, p);
    canvas.drawArc(
        _r(s, .38, .54, .28, .24), math.pi / 2, math.pi * 1.5, false, p);
  }

  void _home(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .18, s.height * .48)
          ..lineTo(s.width * .5, s.height * .2)
          ..lineTo(s.width * .82, s.height * .48)
          ..lineTo(s.width * .74, s.height * .48)
          ..lineTo(s.width * .74, s.height * .8)
          ..lineTo(s.width * .26, s.height * .8)
          ..lineTo(s.width * .26, s.height * .48)
          ..close(),
        p);
  }

  void _gift(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .2, .36, .6, .42, .05), p);
    canvas.drawLine(_o(s, .5, .28), _o(s, .5, .78), p);
    canvas.drawLine(_o(s, .2, .48), _o(s, .8, .48), p);
    canvas.drawArc(_r(s, .28, .2, .22, .18), 0, math.pi * 1.8, false, p);
    canvas.drawArc(_r(s, .5, .2, .22, .18), math.pi, math.pi * 1.8, false, p);
  }

  void _reflect(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .22, .22, .5, .5, .08), p);
    canvas.drawLine(_o(s, .34, .38), _o(s, .6, .38), p);
    canvas.drawLine(_o(s, .34, .52), _o(s, .52, .52), p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .7, s.height * .64)
          ..lineTo(s.width * .82, s.height * .78)
          ..lineTo(s.width * .56, s.height * .78),
        p);
  }

  void _pause(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(_o(s, .5, .5), s.width * .3, p);
    canvas.drawLine(_o(s, .42, .36), _o(s, .42, .64), p);
    canvas.drawLine(_o(s, .58, .36), _o(s, .58, .64), p);
  }

  void _insight(Canvas canvas, Size s, Paint p, Paint f) {
    for (final item in const [(.34, .62), (.5, .48), (.66, .34)]) {
      canvas.drawLine(_o(s, item.$1, .76), _o(s, item.$1, item.$2), p);
    }
    canvas.drawCircle(_o(s, .5, .22), s.width * .045, f);
  }

  void _signal(Canvas canvas, Size s, Paint p, Paint f) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .18, s.height * .7)
          ..cubicTo(s.width * .32, s.height * .5, s.width * .42, s.height * .76,
              s.width * .56, s.height * .5)
          ..cubicTo(s.width * .66, s.height * .32, s.width * .76,
              s.height * .34, s.width * .84, s.height * .26),
        p);
    canvas.drawCircle(_o(s, .84, .26), s.width * .045, f);
  }

  void _shield(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .5, s.height * .16)
          ..lineTo(s.width * .76, s.height * .26)
          ..lineTo(s.width * .72, s.height * .56)
          ..quadraticBezierTo(
              s.width * .66, s.height * .72, s.width * .5, s.height * .84)
          ..quadraticBezierTo(
              s.width * .34, s.height * .72, s.width * .28, s.height * .56)
          ..lineTo(s.width * .24, s.height * .26)
          ..close(),
        p);
  }

  void _family(Canvas canvas, Size s, Paint p, Paint f) {
    canvas.drawCircle(_o(s, .42, .34), s.width * .08, p);
    canvas.drawCircle(_o(s, .65, .4), s.width * .07, p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .24, s.height * .76)
          ..quadraticBezierTo(
              s.width * .42, s.height * .54, s.width * .6, s.height * .76),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .5, s.height * .78)
          ..quadraticBezierTo(
              s.width * .65, s.height * .6, s.width * .82, s.height * .78),
        p);
  }

  void _trail(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .26, .18, .48, .64, .06), p);
    canvas.drawCircle(_o(s, .38, .36), s.width * .025, p);
    canvas.drawCircle(_o(s, .5, .5), s.width * .025, p);
    canvas.drawCircle(_o(s, .62, .64), s.width * .025, p);
  }

  void _trophy(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .34, s.height * .22)
          ..lineTo(s.width * .66, s.height * .22)
          ..lineTo(s.width * .62, s.height * .52)
          ..quadraticBezierTo(
              s.width * .5, s.height * .64, s.width * .38, s.height * .52)
          ..close(),
        p);
    canvas.drawLine(_o(s, .5, .64), _o(s, .5, .78), p);
    canvas.drawLine(_o(s, .34, .8), _o(s, .66, .8), p);
    canvas.drawArc(_r(s, .18, .26, .2, .24), -math.pi / 2, math.pi, false, p);
    canvas.drawArc(_r(s, .62, .26, .2, .24), math.pi / 2, math.pi, false, p);
  }

  void _lock(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(_rr(s, .24, .42, .52, .34, .08), p);
    canvas.drawArc(_r(s, .34, .2, .32, .36), math.pi, math.pi, false, p);
  }

  void _sprout(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(_o(s, .5, .8), _o(s, .5, .38), p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .5, s.height * .52)
          ..quadraticBezierTo(
              s.width * .28, s.height * .42, s.width * .26, s.height * .24)
          ..quadraticBezierTo(
              s.width * .44, s.height * .24, s.width * .5, s.height * .52),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .5, s.height * .48)
          ..quadraticBezierTo(
              s.width * .7, s.height * .36, s.width * .76, s.height * .2)
          ..quadraticBezierTo(
              s.width * .58, s.height * .22, s.width * .5, s.height * .48),
        p);
  }

  void _compass(Canvas canvas, Size s, Paint p, Paint f) {
    canvas.drawCircle(_o(s, .5, .5), s.width * .32, p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .6, s.height * .28)
          ..lineTo(s.width * .52, s.height * .58)
          ..lineTo(s.width * .34, s.height * .7)
          ..lineTo(s.width * .42, s.height * .4)
          ..close(),
        p);
  }

  void _crown(Canvas canvas, Size s, Paint p) {
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .22, s.height * .68)
          ..lineTo(s.width * .28, s.height * .34)
          ..lineTo(s.width * .44, s.height * .52)
          ..lineTo(s.width * .5, s.height * .28)
          ..lineTo(s.width * .56, s.height * .52)
          ..lineTo(s.width * .72, s.height * .34)
          ..lineTo(s.width * .78, s.height * .68)
          ..close(),
        p);
  }

  void _monk(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(_o(s, .5, .34), s.width * .16, p);
    canvas.drawArc(_r(s, .24, .46, .52, .38), math.pi, math.pi, false, p);
    canvas.drawLine(_o(s, .34, .7), _o(s, .66, .7), p);
  }

  void _more(Canvas canvas, Size s, Paint f) {
    for (final x in const [.32, .5, .68]) {
      canvas.drawCircle(_o(s, x, .5), s.width * .045, f);
    }
  }

  Offset _o(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  Rect _r(Size size, double x, double y, double w, double h) => Rect.fromLTWH(
        size.width * x,
        size.height * y,
        size.width * w,
        size.height * h,
      );

  RRect _rr(Size size, double x, double y, double w, double h, double radius) =>
      RRect.fromRectAndRadius(
        _r(size, x, y, w, h),
        Radius.circular(size.width * radius),
      );

  @override
  bool shouldRepaint(covariant _ConsciaGlyphPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
