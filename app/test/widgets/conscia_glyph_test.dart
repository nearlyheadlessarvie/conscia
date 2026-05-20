import 'package:conscia_app/widgets/conscia_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'ConsciaGlyph renders category, quest, milestone, and level glyphs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          textDirection: TextDirection.ltr,
          children: [
            ConsciaGlyph.category('Dining', size: 24, color: Colors.green),
            ConsciaGlyph.quest(
              'reflect_three_purchases',
              size: 24,
              color: Colors.blue,
            ),
            ConsciaGlyph.milestone(
              'first_reflection',
              size: 24,
              color: Colors.orange,
            ),
            ConsciaGlyph.level(
              'budget_guardian',
              size: 24,
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(ConsciaGlyph), findsNWidgets(4));
    expect(
      find.descendant(
        of: find.byType(ConsciaGlyph),
        matching: find.byType(CustomPaint),
      ),
      findsNWidgets(4),
    );
  });
}
