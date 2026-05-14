import 'package:conscia_app/models/managed_category.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/screens/settings/category_management_screen.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingCategoryActions extends CategoryActions {
  String? createdName;
  String? createdType;
  String? archivedId;

  @override
  Future<ManagedCategory> create({
    required String name,
    required String type,
    String scope = 'Personal',
    String? familySpaceId,
    String? iconKey,
    String? colorKey,
  }) async {
    createdName = name;
    createdType = type;
    return _category(id: 'created', name: name, type: type);
  }

  @override
  Future<void> archive(String id) async {
    archivedId = id;
  }
}

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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _RecordingCategoryActions actions,
  List<ManagedCategory> categories = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        managedCategoriesProvider(const CategoryQuery(includeArchived: true))
            .overrideWith((ref) async => categories),
        categoryActionsProvider.overrideWithValue(actions),
      ],
      child: const MaterialApp(home: CategoryManagementScreen()),
    ),
  );
}

void main() {
  testWidgets('lists active and archived categories by type', (tester) async {
    await _pumpScreen(
      tester,
      actions: _RecordingCategoryActions(),
      categories: [
        _category(id: 'dining', name: 'Dining', type: 'Expense'),
        _category(id: 'salary', name: 'Salary', type: 'Income'),
        _category(
          id: 'old',
          name: 'Old Hobby',
          type: 'Expense',
          isArchived: true,
        ),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Expense'), findsWidgets);
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('ARCHIVED'), findsOneWidget);
    expect(find.text('Old Hobby'), findsOneWidget);
  });

  testWidgets('creates a custom category from settings', (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pet care');
    await tester.tap(find.text('Save category'));
    await tester.pumpAndSettle();

    expect(actions.createdName, 'Pet care');
    expect(actions.createdType, 'Expense');
  });

  testWidgets('category sheet uses Conscia v2 floating input', (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
      floatingFields.any((field) => field.label == 'Category name'),
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Category name',
      ),
      findsNothing,
    );
  });

  testWidgets('archives a custom category after confirmation', (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(
      tester,
      actions: actions,
      categories: [_category(id: 'coffee', name: 'Coffee', type: 'Expense')],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Archive Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(actions.archivedId, 'coffee');
  });
}
