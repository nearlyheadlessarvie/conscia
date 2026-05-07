import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({required this.permissionGranted});

  final bool permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;
}

Future<void> _pumpTransactionForm(
  WidgetTester tester, {
  SharedPreferences? prefs,
  LocationAssistanceService? locationService,
}) async {
  final resolvedPrefs = prefs ??
      await () async {
        SharedPreferences.setMockInitialValues({
          'location_suggestions_enabled': false,
          'location_suggestions_prompted': true,
        });
        return SharedPreferences.getInstance();
      }();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
          ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
        ),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'tx@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(resolvedPrefs),
        locationAssistanceServiceProvider.overrideWithValue(
          locationService ??
              _FakeLocationAssistanceService(permissionGranted: true),
        ),
      ],
      child: const MaterialApp(
        home: TransactionFormScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('transaction form shows a single quick preset row when unselected', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.byType(QuickPresetChips), findsOneWidget);
    expect(find.text('Quick add'), findsNothing);
  });

  testWidgets('transaction form swaps visible quick categories for income', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('transaction form prompts for location assistance on first open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Turn on'), findsOneWidget);
  });

  testWidgets('transaction form shows merchant suggestion UI when enabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsOneWidget);
    expect(find.text('Nearby merchants'), findsOneWidget);
    expect(find.text('Likely categories'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Coffee'), findsWidgets);
  });
}
