import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/purchase_suggestions_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/purchase_suggestion_chips.dart';

void main() {
  final testSuggestion = PurchaseSuggestion(
    description: 'Starbucks',
    amount: 6.50,
    currencyCode: 'USD',
    category: 'Coffee',
    frequencyLabel: '3× this week',
  );

  testWidgets('renders suggestion rows when suggestions present', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => [testSuggestion]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (_, __, ___) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Starbucks'), findsOneWidget);
    expect(find.text('3× this week'), findsOneWidget);
  });

  testWidgets('renders nothing when suggestions list is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (_, __, ___) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Your usual'), findsNothing);
  });

  testWidgets('calls onSuggestionSelected when tapped', (tester) async {
    String? desc;
    double? amt;
    String? cat;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        purchaseSuggestionsProvider.overrideWith((_) async => [testSuggestion]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PurchaseSuggestionChips(
            onSuggestionSelected: (d, a, c) {
              desc = d; amt = a; cat = c;
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starbucks'));
    await tester.pump();

    expect(desc, 'Starbucks');
    expect(amt, 6.50);
    expect(cat, 'Coffee');
  });
}
