import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/settings_screen.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLocationAssistanceService extends LocationAssistanceService {
  _RecordingLocationAssistanceService({required this.permissionGranted});

  final bool permissionGranted;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted;
  }

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions() {
    return const (
      nearbyMerchants: <String>[],
      likelyCategories: <String>[],
    );
  }
}

Future<ProviderContainer> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required LocationAssistanceService locationService,
}) async {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'settings@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
        ),
      ),
      subscriptionProvider.overrideWith(
        (ref) async => const SubscriptionStatus(
          tier: 'free',
          isPremium: false,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationAssistanceServiceProvider.overrideWithValue(locationService),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );

  return container;
}

void main() {
  testWidgets('settings can toggle smart location suggestions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
      'location_suggestions_permission_denied': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    final container = await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart location suggestions'), findsOneWidget);
    expect(find.textContaining('Currently off'), findsOneWidget);
    expect(
      find.textContaining('System location permission may also need to be enabled'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isTrue,
    );
    expect(find.textContaining('Currently on'), findsOneWidget);
  });
}
