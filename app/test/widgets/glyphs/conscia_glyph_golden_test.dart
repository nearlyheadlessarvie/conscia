import 'package:conscia_app/widgets/conscia_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConsciaGlyph representative set golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('conscia-glyph-golden-boundary'),
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ConsciaGlyph(
                        kind: ConsciaGlyphKind.family,
                        color: Color(0xFF1D2B6B),
                        size: 28,
                      ),
                      ConsciaGlyph(
                        kind: ConsciaGlyphKind.wallet,
                        color: Color(0xFF1D2B6B),
                        size: 28,
                      ),
                      ConsciaGlyph(
                        kind: ConsciaGlyphKind.calendar,
                        color: Color(0xFF1D2B6B),
                        size: 28,
                      ),
                      ConsciaGlyph(
                        kind: ConsciaGlyphKind.dining,
                        color: Color(0xFF1D2B6B),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('conscia-glyph-golden-boundary')),
      matchesGoldenFile('goldens/conscia_glyph_representative_set.png'),
    );
  });
}
