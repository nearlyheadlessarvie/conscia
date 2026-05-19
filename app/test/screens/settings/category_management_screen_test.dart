import 'package:conscia_app/models/managed_category.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/screens/settings/category_management_screen.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/widgets/feed_card.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:conscia_app/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingCategoryActions extends CategoryActions {
  String? createdName;
  String? createdType;
  String? createdIconKey;
  String? createdColorKey;
  String? archivedId;
  Object? createError;

  @override
  Future<ManagedCategory> create({
    required String name,
    required String type,
    String scope = 'Personal',
    String? familySpaceId,
    String? iconKey,
    String? colorKey,
  }) async {
    final error = createError;
    if (error != null) throw error;

    createdName = name;
    createdType = type;
    createdIconKey = iconKey;
    createdColorKey = colorKey;
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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _RecordingCategoryActions actions,
  List<ManagedCategory> categories = const [],
  bool isPremium = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        managedCategoriesProvider(const CategoryQuery(includeArchived: true))
            .overrideWith((ref) async => categories),
        categoryActionsProvider.overrideWithValue(actions),
        subscriptionProvider.overrideWith(
          (ref) async => SubscriptionStatus(
            tier: isPremium ? 'premium' : 'free',
            isPremium: isPremium,
          ),
        ),
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
    expect(find.text('EXPENSE'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('Expense'), findsNothing);
    expect(find.text('Income'), findsNothing);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('ARCHIVED'), findsOneWidget);
    expect(find.text('Old Hobby'), findsOneWidget);
    expect(find.byType(FeedCard), findsNothing);
  });

  testWidgets('creates a custom category from settings', (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions, isPremium: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pet care');
    await tester.ensureVisible(find.text('Save category'));
    await tester.tap(find.text('Save category'));
    await tester.pumpAndSettle();

    expect(actions.createdName, 'Pet care');
    expect(actions.createdType, 'Expense');
    expect(actions.createdIconKey, 'other');
    expect(actions.createdColorKey, isNot(isEmpty));
  });

  testWidgets('category sheet uses Conscia v2 floating input', (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions, isPremium: true);
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

  testWidgets('category sheet uses Conscia controls for type and visuals',
      (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions, isPremium: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byTooltip('Icon: More'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.byTooltip('Color: Red'), findsOneWidget);
    expect(find.byTooltip('Color: Indigo'), findsOneWidget);
    expect(find.byTooltip('Color: Lime'), findsOneWidget);
  });

  testWidgets('more icon choice opens the full icon picker sheet',
      (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions, isPremium: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Icon: Rental'), findsNothing);

    await tester.tap(find.byTooltip('Icon: More'));
    await tester.pumpAndSettle();

    expect(find.text('Choose icon'), findsOneWidget);
    expect(find.byTooltip('Icon: Rental'), findsOneWidget);
  });

  testWidgets('shows create errors inline inside the category sheet',
      (tester) async {
    final actions = _RecordingCategoryActions()
      ..createError = const ApiException(
        message: 'A category with that name already exists.',
        statusCode: 409,
      );
    await _pumpScreen(tester, actions: actions, isPremium: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dining');
    await tester.ensureVisible(find.text('Save category'));
    await tester.tap(find.text('Save category'));
    await tester.pumpAndSettle();

    expect(
      find.text('A category with that name already exists.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('New category'), findsOneWidget);
  });

  testWidgets('free users see a premium gate instead of the category sheet',
      (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(tester, actions: actions, isPremium: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.text('Premium Feature'), findsOneWidget);
    expect(
        find.text('Custom categories are a Premium feature.'), findsOneWidget);
    expect(find.text('New category'), findsNothing);
    expect(actions.createdName, isNull);
  });

  testWidgets('archives a custom category with a left swipe confirmation',
      (tester) async {
    final actions = _RecordingCategoryActions();
    await _pumpScreen(
      tester,
      actions: actions,
      categories: [_category(id: 'coffee', name: 'Coffee', type: 'Expense')],
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Archive Coffee'), findsNothing);

    await tester.drag(find.text('Coffee').first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Archive category'));
    await tester.pumpAndSettle();

    expect(actions.archivedId, 'coffee');
    expect(find.text('Category archived.'), findsOneWidget);
  });

  testWidgets('default category rows use centralized colors over stale blue',
      (tester) async {
    await _pumpScreen(
      tester,
      actions: _RecordingCategoryActions(),
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

    final icon = tester.widget<Icon>(find.byIcon(Icons.restaurant_rounded));

    expect(icon.color, const Color(0xFF43A047));
  });
}
