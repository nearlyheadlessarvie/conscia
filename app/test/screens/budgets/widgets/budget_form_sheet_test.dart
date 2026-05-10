import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
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
    expect(find.widgetWithText(InputChip, 'Subscriptions'), findsOneWidget);
  });

  testWidgets('budget form hides upgrade-only categories for free users',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: false);

    await tester.tap(find.text('All categories'));
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

    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });
}
