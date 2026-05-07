import 'package:conscia_app/core/constants/generated/app_constants.g.dart';
import 'package:conscia_app/core/utils/voice_input_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice parser extracts numeric amount, category, and counterparty', () {
    final result = VoiceInputParser.parse(
      'Spent 600 on Dining at Starbucks',
      categories: expenseCategories,
    );

    expect(result.amount, 600);
    expect(result.category, 'Dining');
    expect(result.counterparty, 'Starbucks');
  });

  test('voice parser extracts number words for amount', () {
    final result = VoiceInputParser.parse(
      'buy groceries at Robinsons for six hundred pesos',
      categories: expenseCategories,
    );

    expect(result.amount, 600);
    expect(result.category, 'Groceries');
    expect(result.counterparty, 'Robinsons');
  });

  test('voice parser keeps transcript context when only category is obvious', () {
    final result = VoiceInputParser.parse(
      'Coffee with friends later',
      categories: expenseCategories,
    );

    expect(result.transcript, 'Coffee with friends later');
    expect(result.amount, isNull);
    expect(result.category, 'Coffee');
    expect(result.counterparty, 'with friends later');
  });
}
