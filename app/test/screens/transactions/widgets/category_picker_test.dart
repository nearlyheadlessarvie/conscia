import 'package:conscia_app/models/managed_category.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/category_picker.dart';
import 'package:conscia_app/widgets/conscia_glyph.dart';
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
  bool isDefault = false,
  String? iconKey,
  String? colorKey,
}) {
  return ManagedCategory(
    id: id,
    name: name,
    normalizedName: name.toLowerCase(),
    type: type,
    scope: 'Personal',
    iconKey: iconKey,
    colorKey: colorKey,
    isArchived: isArchived,
    isDefault: isDefault,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required bool isExpense,
  required List<ManagedCategory> categories,
  String? selected,
  ValueChanged<String?>? onSelected,
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
            selected: selected,
            isExpense: isExpense,
            maxVisible: 20,
            onSelected: onSelected ?? (_) {},
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

  testWidgets('selected category is first and tapping again unselects',
      (tester) async {
    String? selected = 'Gift';
    await _pumpPicker(
      tester,
      selected: selected,
      isExpense: true,
      categories: [
        _category(id: 'dining', name: 'Dining', type: 'Expense'),
        _category(id: 'gift', name: 'Gift', type: 'Expense'),
        _category(id: 'bills', name: 'Bills', type: 'Expense'),
      ],
      onSelected: (value) => selected = value,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Gift')).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Dining')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Gift')).dx,
      lessThan(tester.getTopLeft(find.text('Dining')).dx),
    );

    await tester.tap(find.text('Gift'));
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });

  testWidgets('uses stored category color metadata for managed chips',
      (tester) async {
    await _pumpPicker(
      tester,
      isExpense: true,
      categories: [
        _category(
          id: 'pet',
          name: 'Pet care',
          type: 'Expense',
          iconKey: 'other',
          colorKey: 'pink',
        ),
      ],
    );
    await tester.pumpAndSettle();

    final glyph = tester.widget<ConsciaGlyph>(find.byType(ConsciaGlyph));

    expect(glyph.kind, ConsciaGlyphKind.more);
    expect(glyph.color, const Color(0xFFEC407A));
  });

  testWidgets('default managed categories ignore stale stored blue metadata',
      (tester) async {
    await _pumpPicker(
      tester,
      isExpense: true,
      categories: [
        _category(
          id: 'dining',
          name: 'Dining',
          type: 'Expense',
          isDefault: true,
          iconKey: 'dining',
          colorKey: 'blue',
        ),
      ],
    );
    await tester.pumpAndSettle();

    final glyph = tester.widget<ConsciaGlyph>(find.byType(ConsciaGlyph));

    expect(glyph.kind, ConsciaGlyphKind.dining);
    expect(glyph.color, const Color(0xFF43A047));
  });
}
