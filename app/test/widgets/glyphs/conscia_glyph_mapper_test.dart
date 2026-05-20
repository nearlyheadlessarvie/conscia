import 'package:conscia_app/widgets/glyphs/conscia_glyph_kind.dart';
import 'package:conscia_app/widgets/glyphs/conscia_glyph_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsciaGlyphMapper.category', () {
    test('maps curated category glyphs', () {
      expect(ConsciaGlyphMapper.category('Dining'), ConsciaGlyphKind.dining);
      expect(ConsciaGlyphMapper.category('Coffee'), ConsciaGlyphKind.coffee);
      expect(
        ConsciaGlyphMapper.category('Groceries'),
        ConsciaGlyphKind.groceries,
      );
      expect(ConsciaGlyphMapper.category('Travel'), ConsciaGlyphKind.travel);
      expect(
        ConsciaGlyphMapper.category('Subscriptions'),
        ConsciaGlyphKind.subscription,
      );
    });

    test('uses semantic fallbacks for unknown categories', () {
      expect(ConsciaGlyphMapper.category('Bank fees'), ConsciaGlyphKind.wallet);
      expect(
        ConsciaGlyphMapper.category('Paper trail item'),
        ConsciaGlyphKind.receipt,
      );
      expect(ConsciaGlyphMapper.category('Unmapped thing'), ConsciaGlyphKind.more);
    });
  });

  group('ConsciaGlyphMapper.quest and milestone', () {
    test('maps known quest, milestone, and level keys', () {
      expect(
        ConsciaGlyphMapper.quest('reflect-three-purchases'),
        ConsciaGlyphKind.reflect,
      );
      expect(
        ConsciaGlyphMapper.milestone('family-founder'),
        ConsciaGlyphKind.family,
      );
      expect(
        ConsciaGlyphMapper.level('money-monk'),
        ConsciaGlyphKind.monk,
      );
    });
  });
}
