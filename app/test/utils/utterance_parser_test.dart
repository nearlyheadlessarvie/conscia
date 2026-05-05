import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/utils/utterance_parser.dart';

void main() {
  group('UtteranceParser', () {
    test('parses numeric amount with dollar sign', () {
      final r = UtteranceParser.parse('spent \$12.50 on lunch');
      expect(r.amount, 12.50);
    });

    test('parses numeric amount without dollar sign', () {
      final r = UtteranceParser.parse('coffee 5.50');
      expect(r.amount, 5.50);
    });

    test('parses spoken amount — two-word form', () {
      final r = UtteranceParser.parse('starbucks five fifty');
      expect(r.amount, 5.50);
    });

    test('parses spoken amount — single word', () {
      final r = UtteranceParser.parse('lunch twenty dollars');
      expect(r.amount, 20.0);
    });

    test('extracts category from keyword', () {
      final r = UtteranceParser.parse('starbucks latte');
      expect(r.category, 'Coffee');
    });

    test('extracts dining category', () {
      final r = UtteranceParser.parse('lunch at jollibee');
      expect(r.category, 'Dining');
    });

    test('returns null category when no keyword matches', () {
      final r = UtteranceParser.parse('xyz abc 10');
      expect(r.category, isNull);
    });

    test('returns null amount when none parseable', () {
      final r = UtteranceParser.parse('coffee at starbucks');
      expect(r.amount, isNull);
    });

    test('strips amount tokens from description', () {
      final r = UtteranceParser.parse('coffee 5.50');
      expect(r.description, isNot(contains('5.50')));
    });

    test('falls back to raw transcript when description would be empty', () {
      final r = UtteranceParser.parse('5.50');
      expect(r.description, '5.50');
    });

    test('handles empty string gracefully', () {
      final r = UtteranceParser.parse('');
      expect(r.amount, isNull);
      expect(r.category, isNull);
      expect(r.description, '');
    });
  });
}
