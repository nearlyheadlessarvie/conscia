import 'package:conscia_app/models/managed_category.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conscia_app/providers/usage_provider.dart';

ManagedCategory _category({
  required String id,
  required String name,
  required String type,
  bool isArchived = false,
}) {
  return ManagedCategory(
    id: id,
    name: name,
    normalizedName: name.toLowerCase(),
    type: type,
    scope: 'Personal',
    iconKey: null,
    colorKey: null,
    isArchived: isArchived,
    isDefault: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required bool isExpense,
  required List<ManagedCategory> categories,
}) async {
  SharedPreferences.setMockInitialValues({
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        managedCategoriesProvider(const CategoryQuery())
            .overrideWith((ref) async => categories),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CategoryPicker(
            isExpense: isExpense,
            maxVisible: 20,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses active managed expense categories', (tester) async {
    await _pumpPicker(
      tester,
      isExpense: true,
      categories: [
        _category(id: 'pet', name: 'Pet care', type: 'Expense'),
        _category(id: 'salary', name: 'Salary', type: 'Income'),
        _category(
          id: 'archived',
          name: 'Old hobby',
          type: 'Expense',
          isArchived: true,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Pet care'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
    expect(find.text('Old hobby'), findsNothing);
  });

  testWidgets('uses active managed income categories', (tester) async {
    await _pumpPicker(
      tester,
      isExpense: false,
      categories: [
        _category(id: 'pet', name: 'Pet care', type: 'Expense'),
        _category(id: 'salary', name: 'Salary', type: 'Income'),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Pet care'), findsNothing);
  });
}
