import 'package:conscia_app/widgets/conscia_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

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
        matching: find.byType(HugeIcon),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('income categories resolve to distinct Conscia glyphs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          textDirection: TextDirection.ltr,
          children: [
            ConsciaGlyph.category('Salary', color: Colors.teal),
            ConsciaGlyph.category('Freelance', color: Colors.orange),
            ConsciaGlyph.category('Business', color: Colors.purple),
            ConsciaGlyph.category('Investment', color: Colors.green),
            ConsciaGlyph.category('Rental Income', color: Colors.cyan),
            ConsciaGlyph.category('Bonus', color: Colors.amber),
          ],
        ),
      ),
    );

    expect(
      tester
          .widgetList<ConsciaGlyph>(find.byType(ConsciaGlyph))
          .map((glyph) => glyph.kind),
      [
        ConsciaGlyphKind.salary,
        ConsciaGlyphKind.freelance,
        ConsciaGlyphKind.business,
        ConsciaGlyphKind.investment,
        ConsciaGlyphKind.rentalIncome,
        ConsciaGlyphKind.bonus,
      ],
    );
  });

  testWidgets('gaming and entertainment use distinct Conscia glyphs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          textDirection: TextDirection.ltr,
          children: [
            ConsciaGlyph.category('Entertainment', color: Colors.purple),
            ConsciaGlyph.category('Gaming', color: Colors.purple),
            ConsciaGlyph.category('Other', color: Colors.cyan),
          ],
        ),
      ),
    );

    expect(
      tester
          .widgetList<ConsciaGlyph>(find.byType(ConsciaGlyph))
          .map((glyph) => glyph.kind),
      [
        ConsciaGlyphKind.entertainment,
        ConsciaGlyphKind.gaming,
        ConsciaGlyphKind.more,
      ],
    );
  });
}
