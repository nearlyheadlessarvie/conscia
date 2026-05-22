import 'dart:async';

import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/receipts/receipt_scanner_screen.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [];
}

class _FakeLocationAssistanceService extends LocationAssistanceService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) getTransactionSuggestions() =>
      const (nearbyMerchants: <String>[], likelyCategories: <String>[]);
}

Future<void> _pumpReceiptRouterApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();

  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/scan',
    routes: [
      GoRoute(
        path: '/scan',
        builder: (_, __) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (_, __) => const TransactionFormScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'receipt@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoryFrequencyProvider.overrideWithValue(
          ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
        ),
        locationAssistanceServiceProvider.overrideWithValue(
          _FakeLocationAssistanceService(),
        ),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

Future<void> _pumpReceiptRouterAppWithPreviousRoute(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();

  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => router.push('/scan'),
              child: const Text('Open Scan'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (_, __) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (_, __) => const TransactionFormScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'receipt@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoryFrequencyProvider.overrideWithValue(
          ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
        ),
        locationAssistanceServiceProvider.overrideWithValue(
          _FakeLocationAssistanceService(),
        ),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('premium receipt scanner uses redesigned shared surface',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'premium',
              isPremium: true,
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'receipt@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          categoryFrequencyProvider.overrideWithValue(
            ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
          ),
          locationAssistanceServiceProvider.overrideWithValue(
            _FakeLocationAssistanceService(),
          ),
          budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
          budgetReconciliationEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: ReceiptScannerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('receipt-scan-hero')), findsOneWidget);
    expect(find.text('SCAN RECEIPT'), findsOneWidget);
    expect(find.text('Snap it. Review it. Done.'), findsOneWidget);
    expect(find.text('Choose a source'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.byKey(const ValueKey('receipt-scan-camera-action')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('receipt-scan-gallery-action')),
        findsOneWidget);
  });

  testWidgets('receipt scanner ignores repeated taps while picker is active',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final pickerCompleter = Completer<XFile?>();
    var pickerCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'premium',
              isPremium: true,
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'receipt@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          categoryFrequencyProvider.overrideWithValue(
            ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
          ),
          locationAssistanceServiceProvider.overrideWithValue(
            _FakeLocationAssistanceService(),
          ),
          budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
          budgetReconciliationEnabledProvider.overrideWithValue(false),
          receiptImagePickerProvider.overrideWithValue((source) {
            pickerCalls += 1;
            return pickerCompleter.future;
          }),
        ],
        child: const MaterialApp(
          home: ReceiptScannerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final cameraAction =
        find.byKey(const ValueKey('receipt-scan-camera-action'));
    await tester.tap(cameraAction);
    await tester.pump();
    await tester.tap(cameraAction, warnIfMissed: false);
    await tester.pump();

    expect(pickerCalls, 1);

    pickerCompleter.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('receipt maybe later opens add expense form for free users',
      (tester) async {
    await _pumpReceiptRouterApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Receipt Scanner'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);

    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
  });

  testWidgets(
      'receipt maybe later add expense form can close back to previous screen',
      (tester) async {
    await _pumpReceiptRouterAppWithPreviousRoute(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Scanner'), findsOneWidget);

    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);

    Navigator.of(tester.element(find.text('Add transaction'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Open Scan'), findsOneWidget);
    expect(find.text('Add transaction'), findsNothing);
  });
}
