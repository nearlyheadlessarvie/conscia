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

class _FailingBudgetService extends _StaticBudgetService {
  @override
  Future<Budget> create(CreateBudgetDto dto) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/budgets'),
      response: Response(
        requestOptions: RequestOptions(path: '/budgets'),
        statusCode: 409,
        data: {'error': 'A budget for that category already exists.'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

Future<void> _pumpBudgetFormSheet(
  WidgetTester tester, {
  required bool isPremium,
  String? initialCategory,
  bool hasFamilySpace = false,
  BudgetService? budgetService,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final resolvedBudgetService = budgetService ?? _StaticBudgetService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetServiceProvider.overrideWithValue(
          resolvedBudgetService,
        ),
        budgetListProvider.overrideWith(
          (ref) => BudgetListNotifier(resolvedBudgetService),
        ),
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
    expect(find.text('Category'), findsOneWidget);
  });

  testWidgets('budget form shows all expense categories for free users',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: false);

    await tester.ensureVisible(find.text('More'));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Dining'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('budget form shows all expense categories for premium users',
      (tester) async {
    await _pumpBudgetFormSheet(tester, isPremium: true);

    await tester.ensureVisible(find.text('More'));
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
    final inputRect = tester.getRect(find.byType(TextField));

    expect(labelRect.left, greaterThan(badgeRect.right + 8));
    expect(labelRect.left - badgeRect.right, lessThanOrEqualTo(16));
    expect(inputRect.left - badgeRect.right, lessThanOrEqualTo(16));
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

  testWidgets('budget form shows create conflicts inline', (tester) async {
    await _pumpBudgetFormSheet(
      tester,
      isPremium: true,
      initialCategory: 'Dining',
      budgetService: _FailingBudgetService(),
    );

    await tester.enterText(find.byType(TextField), '4000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create Budget'));
    await tester.pumpAndSettle();

    final errorTop = tester
        .getTopLeft(find.text('A budget for that category already exists.'))
        .dy;
    final buttonTop = tester
        .getTopLeft(find.widgetWithText(FilledButton, 'Create Budget'))
        .dy;

    expect(
      find.text('A budget for that category already exists.'),
      findsOneWidget,
    );
    expect(errorTop, lessThan(buttonTop));
  });
}
