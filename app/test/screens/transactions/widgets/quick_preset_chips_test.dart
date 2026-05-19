import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/models/managed_category.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

ManagedCategory _category({
  required String id,
  required String name,
  required String type,
}) {
  return ManagedCategory(
    id: id,
    name: name,
    normalizedName: name.toLowerCase(),
    type: type,
    scope: 'Personal',
    iconKey: null,
    colorKey: null,
    isArchived: false,
    isDefault: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Future<Widget> _buildQuickPresetChipsApp({
  required QuickPresetChips child,
  List<ManagedCategory> managedCategories = const [],
  Map<String, Object> initialPrefs = const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  },
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      managedCategoriesProvider(const CategoryQuery())
          .overrideWith((ref) async => managedCategories),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders all 5 chip labels', (tester) async {
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': ['Coffee', 'Gaming'],
      },
      child: QuickPresetChips(
        selectedCategory: null,
        isExpense: true,
        onCategorySelected: (_) {},
      ),
    ));

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
    expect(find.byIcon(CategoryIcons.forCategory('Coffee')), findsOneWidget);
  });

  testWidgets('highlights selected chip', (tester) async {
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': ['Coffee'],
      },
      child: QuickPresetChips(
        selectedCategory: 'Coffee',
        isExpense: true,
        onCategorySelected: (_) {},
      ),
    ));

    final chip =
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Coffee'));
    expect(chip.selected, isTrue);
  });

  testWidgets('calls onCategorySelected when tapped', (tester) async {
    String? selected;
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      child: QuickPresetChips(
        selectedCategory: null,
        isExpense: true,
        onCategorySelected: (cat) => selected = cat,
      ),
    ));

    await tester.tap(find.text('Dining'));
    expect(selected, 'Dining');
  });

  testWidgets('shows income quick categories in income mode', (tester) async {
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': ['Bonus'],
      },
      child: QuickPresetChips(
        selectedCategory: null,
        isExpense: false,
        onCategorySelected: (_) {},
      ),
    ));

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Bonus'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('uses managed categories for quick picks', (tester) async {
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      managedCategories: [
        _category(id: 'pet', name: 'Pet care', type: 'Expense'),
        _category(id: 'salary', name: 'Salary', type: 'Income'),
      ],
      child: QuickPresetChips(
        selectedCategory: null,
        isExpense: true,
        onCategorySelected: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pet care'), findsOneWidget);
    expect(find.text('Dining'), findsNothing);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('free-tier expense chips only show allowed transaction categories',
      (tester) async {
    await tester.pumpWidget(await _buildQuickPresetChipsApp(
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': [
          'Travel',
          'Health',
          'Shopping',
          'Dining',
          'Coffee'
        ],
      },
      child: QuickPresetChips(
        selectedCategory: null,
        isExpense: true,
        isPremium: false,
        onCategorySelected: (_) {},
      ),
    ));

    expect(find.text('Travel'), findsNothing);
    expect(find.text('Health'), findsNothing);
    expect(find.text('Shopping'), findsNothing);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Transport'), findsNothing);
    expect(find.text('Coffee'), findsNothing);
  });
}
