import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/settings_screen.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
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

class _RecordingUserService extends UserService {
  _RecordingUserService() : super(Dio());

  String? lastLocale;
  bool? lastLocationSuggestionsEnabled;
  String? lastAiPersonalityIntensity;

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    lastLocale = locale;
    lastLocationSuggestionsEnabled = locationSuggestionsEnabled;
    lastAiPersonalityIntensity = aiPersonalityIntensity;
    return UserProfile(
      id: 'user-1',
      email: 'settings@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: true,
      locationSuggestionsEnabled:
          locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
    );
  }
}

Future<ProviderContainer> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required LocationAssistanceService locationService,
  UserService? userService,
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
          aiPersonalityIntensity: 'balanced',
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
      if (userService != null) userServiceProvider.overrideWithValue(userService),
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
    final userService = _RecordingUserService();

    final container = await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
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
    expect(userService.lastLocationSuggestionsEnabled, isTrue);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isTrue,
    );
    expect(find.textContaining('Currently on'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(userService.lastLocationSuggestionsEnabled, isFalse);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isFalse,
    );
    expect(find.textContaining('Currently off'), findsOneWidget);
    expect(
      find.textContaining('System location permission may also need to be enabled'),
      findsNothing,
    );
  });

  testWidgets('settings can change region and number format', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Region / Number Format'));
    await tester.pumpAndSettle();

    expect(find.text('Number Format'), findsOneWidget);

    await tester.tap(find.text('English (UK)'));
    await tester.pumpAndSettle();

    expect(userService.lastLocale, 'en_GB');
  });

  testWidgets('settings can change ai personality intensity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Personality Intensity'));
    await tester.pumpAndSettle();

    expect(find.text('Balanced'), findsWidgets);
    await tester.tap(find.text('Intense').last);
    await tester.pumpAndSettle();

    expect(userService.lastAiPersonalityIntensity, 'intense');
  });
}
