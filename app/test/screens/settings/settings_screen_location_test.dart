import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
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
    String? displayName,
    String? photoUrl,
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
      locationSuggestionsEnabled: locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
    );
  }
}

Future<ProviderContainer> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required LocationAssistanceService locationService,
  UserService? userService,
  FamilySpace? familySpace,
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
      familySpaceProvider.overrideWith((ref) async => familySpace),
      subscriptionProvider.overrideWith(
        (ref) async => const SubscriptionStatus(
          tier: 'free',
          isPremium: false,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationAssistanceServiceProvider.overrideWithValue(locationService),
      if (userService != null)
        userServiceProvider.overrideWithValue(userService),
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
      find.textContaining(
          'System location permission may also need to be enabled'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Smart location suggestions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(userService.lastLocationSuggestionsEnabled, isTrue);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isTrue,
    );
    expect(find.textContaining('Currently on'), findsOneWidget);

    await tester.ensureVisible(find.text('Smart location suggestions'));
    await tester.pumpAndSettle();

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
      find.textContaining(
          'System location permission may also need to be enabled'),
      findsNothing,
    );
  });

  testWidgets('settings can change region format', (tester) async {
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

    await tester.ensureVisible(find.text('Currency & Region Format'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Currency & Region Format'));
    await tester.pumpAndSettle();

    expect(find.text('Region Format'), findsOneWidget);

    await tester.tap(find.text('European'));
    await tester.pumpAndSettle();

    expect(userService.lastLocale, 'de_DE');
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

    await tester.ensureVisible(find.text('AI Personality Intensity'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Personality Intensity'));
    await tester.pumpAndSettle();

    expect(find.text('Balanced'), findsWidgets);
    await tester.tap(find.text('Intense').last);
    await tester.pumpAndSettle();

    expect(userService.lastAiPersonalityIntensity, 'intense');
  });

  testWidgets('shared conscia appears under profile with household summary', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Owner',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('Owner · PHP'), findsOneWidget);
    expect(find.text('Family Space settings'), findsOneWidget);

    final profileTop = tester.getTopLeft(find.text('Profile')).dy;
    final sharedTop = tester.getTopLeft(find.text('Shared Conscia')).dy;
    final preferencesTop = tester.getTopLeft(find.text('Preferences')).dy;

    expect(sharedTop, greaterThan(profileTop));
    expect(sharedTop, lessThan(preferencesTop));
  });

  testWidgets('preferences and planning rows are grouped in the intended order',
      (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('AI Personality Intensity'));
    await tester.pumpAndSettle();

    final aiTop = tester.getTopLeft(find.text('AI Personality Intensity')).dy;
    final smartLocationTop =
        tester.getTopLeft(find.text('Smart location suggestions')).dy;
    expect(aiTop, lessThan(smartLocationTop));

    await tester.ensureVisible(find.text('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('Budgets & Categories'), findsOneWidget);
    final planningTop = tester.getTopLeft(find.text('Budgets & Categories')).dy;
    final categoriesTop = tester.getTopLeft(find.text('Categories')).dy;
    final budgetsTop = tester.getTopLeft(find.text('Budgets')).dy;

    expect(categoriesTop, greaterThan(planningTop));
    expect(budgetsTop, greaterThan(categoriesTop));
    expect(
      find.text('Create and tune monthly caps for spending categories'),
      findsOneWidget,
    );
  });
}
