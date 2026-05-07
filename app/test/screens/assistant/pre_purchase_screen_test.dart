import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/assistant/pre_purchase_screen.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.suggestions = const (
      nearbyMerchants: ['Corner Bakery'],
      likelyCategories: ['Groceries'],
    ),
  });

  final bool permissionGranted;
  final ({List<String> nearbyMerchants, List<String> likelyCategories})
      suggestions;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions() => suggestions;
}

Future<void> _pumpPrePurchaseScreen(
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
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'prepurchase@example.com',
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
        home: PrePurchaseScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('pre-purchase shows first-use location prompt only when needed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsOneWidget);
    expect(find.text('You can change this later in Settings.'), findsOneWidget);
    expect(
      find.text(
        'Get nearby merchant and category suggestions wherever you need a little guidance. Suggestions only help fill things faster. You can still edit everything yourself.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);
  });

  testWidgets('pre-purchase can suggest merchant and category when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsOneWidget);
    expect(find.text('Corner Bakery'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Corner Bakery'));
    await tester.tap(find.text('Corner Bakery'));
    await tester.pumpAndSettle();

    final descriptionField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
    );
    expect(descriptionField.controller?.text, 'Corner Bakery');

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.tap(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.pumpAndSettle();

    final dropdownButton = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(dropdownButton.value, 'Groceries');

    expect(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>),
        matching: find.text('Groceries'),
      ),
      findsOneWidget,
    );
  });
}
