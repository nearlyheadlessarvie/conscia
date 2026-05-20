import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves default category visual keys from category name and type', () {
    final dining = CategoryIcons.visualFor(
      'Dining',
      type: 'Expense',
    );
    final salary = CategoryIcons.visualFor(
      'Salary',
      type: 'Income',
    );

    expect(dining.iconKey, 'dining');
    expect(dining.colorKey, 'green');
    expect(salary.iconKey, 'salary');
    expect(salary.colorKey, 'teal');
  });

  test('uses stored category metadata ahead of name defaults', () {
    final visual = CategoryIcons.visualFor(
      'Dining',
      type: 'Expense',
      iconKey: 'gift',
      colorKey: 'pink',
    );

    expect(visual.iconKey, 'gift');
    expect(visual.colorKey, 'pink');
    expect(visual.accent, const Color(0xFFEC407A));
  });

  test('assigns custom categories a curated deterministic visual identity', () {
    final visual = CategoryIcons.visualFor(
      'Pet care',
      type: 'Expense',
    );

    expect(visual.iconKey, 'other');
    expect(visual.colorKey, isNot('blue'));
    expect(CategoryIcons.defaultColorKeyFor('Pet care', type: 'Expense'),
        visual.colorKey);
  });

  test('offers a broad curated category color palette', () {
    expect(CategoryIcons.colorOptions.length, greaterThanOrEqualTo(20));
  });

  test('iconOptions is reduced to the curated font-trial set', () {
    final keys = CategoryIcons.iconOptions.map((option) => option.key).toList();

    expect(keys.length, 20);
    expect(
      keys,
      containsAll(<String>[
        'groceries',
        'dining',
        'transport',
        'shopping',
        'health',
        'bills',
        'education',
        'travel',
        'coffee',
        'subscriptions',
        'salary',
        'freelance',
        'business',
        'investment',
        'gift',
        'home',
        'utilities',
        'phone',
        'pets',
        'other',
      ]),
    );
    expect(keys, isNot(contains('gaming')));
    expect(keys, isNot(contains('beauty')));
    expect(keys, isNot(contains('parking')));
  });

  test('every curated icon option resolves to its own visual key', () {
    for (final option in CategoryIcons.iconOptions) {
      final visual = CategoryIcons.visualFor(
        option.label,
        iconKey: option.key,
      );

      expect(
        visual.iconKey,
        option.key,
        reason: '${option.label} should not fall back to Other',
      );
    }
  });
}
