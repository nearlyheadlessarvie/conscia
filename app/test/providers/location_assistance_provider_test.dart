import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.suggestions = const (
      nearbyMerchants: ['Blue Bottle Coffee'],
      likelyCategories: ['Coffee'],
    ),
    this.merchantCategories = const {},
  });

  final bool permissionGranted;
  final ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) suggestions;
  final Map<String, String> merchantCategories;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() => suggestions;

  @override
  String? categoryForMerchant(String merchant) => merchantCategories[merchant];
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(Dio());

  bool? lastLocationSuggestionsEnabled;

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? displayName,
    String? profilePictureKey,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    lastLocationSuggestionsEnabled = locationSuggestionsEnabled;
    return UserProfile(
      id: 'user-1',
      email: 'user@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: true,
      locationSuggestionsEnabled: locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
    );
  }
}

void main() {
  ProviderContainer buildContainer(
    SharedPreferences prefs, {
    LocationAssistanceService? service,
    UserProfile? userProfile,
    UserService? userService,
  }) {
    final resolvedUserProfile = userProfile ??
        UserProfile(
          id: 'user-1',
          email: 'user@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
          locationSuggestionsEnabled: false,
        );

    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (service != null)
          locationAssistanceServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWith((ref) async => resolvedUserProfile),
        userServiceProvider
            .overrideWithValue(userService ?? _FakeUserService()),
      ],
    );
  }

  test('first-use prompt is needed before the user has chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(prefs);
    addTearDown(container.dispose);

    final state = container.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isTrue);
    expect(state.isEnabled, isFalse);
  });

  test('decline marks the feature as prompted and stops re-prompting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(prefs);
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).declinePrompt();

    final rehydratedContainer = buildContainer(prefs);
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isFalse);
  });

  test('enable marks the feature active when permission succeeds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: true),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container
        .read(locationAssistanceProvider.notifier)
        .enableFromPrompt();

    final rehydratedContainer = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: true),
      userService: _FakeUserService(),
    );
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isTrue);
  });

  test('deny marks the feature as prompted and permission denied', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: false),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container
        .read(locationAssistanceProvider.notifier)
        .enableFromPrompt();

    final rehydratedContainer = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: false),
      userService: _FakeUserService(),
    );
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isFalse);
    expect(state.permissionDenied, isTrue);
    expect(state.shouldPromptOnFeatureOpen, isFalse);
  });

  test('disable from settings keeps prompt handled and clears denied state',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
      'location_suggestions_permission_denied': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: true),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container
        .read(locationAssistanceProvider.notifier)
        .disableFromSettings();

    final rehydratedContainer = buildContainer(prefs);
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isFalse);
    expect(state.permissionDenied, isFalse);
    expect(state.shouldPromptOnFeatureOpen, isFalse);
  });

  test('shared suggestion provider exposes service suggestions', () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
        merchantCategories: const {'Corner Bakery': 'Groceries'},
      ),
    );
    addTearDown(container.dispose);

    final suggestions = container.read(locationAssistanceSuggestionsProvider);

    expect(suggestions.nearbyMerchants, ['Corner Bakery']);
    expect(suggestions.likelyCategories, ['Groceries']);
    expect(suggestions.categoryForMerchant('Corner Bakery'), 'Groceries');
  });

  test('shared suggestion provider hides suggestions when assistance disabled',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
      ),
    );
    addTearDown(container.dispose);

    final suggestions = container.read(locationAssistanceSuggestionsProvider);

    expect(suggestions.nearbyMerchants, isEmpty);
    expect(suggestions.likelyCategories, isEmpty);
  });

  test('provider syncs enabled state from server-backed user profile',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      userProfile: UserProfile(
        id: 'user-1',
        email: 'user@example.com',
        currencyCode: 'USD',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
        locationSuggestionsEnabled: true,
      ),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container.read(currentUserProvider.future);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(locationAssistanceProvider);

    expect(state.isEnabled, isTrue);
    expect(state.hasPrompted, isFalse);
  });
}
