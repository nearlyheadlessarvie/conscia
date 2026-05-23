import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_style_category_selector.dart';
import 'package:conscia_app/widgets/horizontal_edge_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpSelector(
  WidgetTester tester, {
  required bool isPremium,
  bool isExpense = true,
  bool allowAllCategories = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        managedCategoriesProvider(const CategoryQuery())
            .overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TransactionStyleCategorySelector(
            selectedCategory: null,
            isExpense: isExpense,
            isPremium: isPremium,
            allowAllCategories: allowAllCategories,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('free transaction selector shows premium categories affordance',
      (tester) async {
    await _pumpSelector(tester, isPremium: false);
    await tester.pumpAndSettle();

    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Premium categories'), findsOneWidget);
    expect(find.text('Travel'), findsNothing);
  });

  testWidgets('budget mode keeps all categories available for free users',
      (tester) async {
    await _pumpSelector(
      tester,
      isPremium: false,
      allowAllCategories: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium categories'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('free income selector does not show a more affordance',
      (tester) async {
    await _pumpSelector(
      tester,
      isPremium: false,
      isExpense: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(find.text('Premium categories'), findsNothing);
  });

  testWidgets('transaction category selector uses a fading edge hint',
      (tester) async {
    await _pumpSelector(tester, isPremium: true);
    await tester.pumpAndSettle();

    expect(find.byType(HorizontalEdgeFade), findsOneWidget);
  });
}
