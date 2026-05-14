import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/currency_badge.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:conscia_app/widgets/scope_pill_switch.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [];
}

Future<void> _pumpBudgetFormSheet(
  WidgetTester tester, {
  required bool isPremium,
  String? initialCategory,
  bool hasFamilySpace = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionProvider.overrideWith(
          (ref) async => SubscriptionStatus(
            tier: isPremium ? 'premium' : 'free',
            isPremium: isPremium,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'budget@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        familySpaceProvider.overrideWith(
          (ref) async => hasFamilySpace
              ? const FamilySpace(
                  id: 'family-1',
                  name: 'Santos Household',
                  currencyCode: 'USD',
                  isReadOnly: false,
                  role: 'Owner',
                )
              : null,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: BudgetFormSheet(initialCategory: initialCategory),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('budget form surfaces a preselected category clearly', (
    tester,
  ) async {
    await _pumpBudgetFormSheet(
      tester,
      isPremium: true,
      initialCategory: 'Subscriptions',
    );

    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('budget form hides upgrade-only categories for free users',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: false);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Dining'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);
    expect(find.text('Travel'), findsNothing);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('budget form shows all expense categories for premium users',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: true);

    final categoryRail = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(categoryRail, const Offset(-260, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('monthly cap uses Conscia v2 floating label treatment',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: true);

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
        floatingFields.any((field) => field.label == 'Monthly limit'), isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Monthly Limit',
      ),
      findsNothing,
    );
  });

  testWidgets('monthly cap keeps currency badge clear of the placeholder',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: true);

    final badgeRect = tester.getRect(find.byType(CurrencyBadge));
    final labelRect = tester.getRect(find.text('Monthly limit'));

    expect(labelRect.left, greaterThan(badgeRect.right + 8));
  });

  testWidgets('budget form uses the shared scope pill switch', (tester) async {
    await _pumpBudgetFormSheet(
      tester,
      isPremium: true,
      hasFamilySpace: true,
    );

    expect(find.byType(ScopePillSwitch), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
  });
}
