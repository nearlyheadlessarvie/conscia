import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';

void main() {
  testWidgets('renders all 5 chip labels', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
            ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: null,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('☕ Coffee'), findsOneWidget);
    expect(find.text('🍽️ Dining'), findsOneWidget);
    expect(find.text('✈️ Travel'), findsOneWidget);
  });

  testWidgets('highlights selected chip', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: 'Coffee',
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ));

    final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, '☕ Coffee'));
    expect(chip.selected, isTrue);
  });

  testWidgets('calls onCategorySelected when tapped', (tester) async {
    String? selected;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickPresetChips(
            selectedCategory: null,
            onCategorySelected: (cat) => selected = cat,
          ),
        ),
      ),
    ));

    await tester.tap(find.text('🍽️ Dining'));
    expect(selected, 'Dining');
  });
}
