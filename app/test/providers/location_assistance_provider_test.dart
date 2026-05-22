import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.locationServiceEnabled = true,
    this.permissionStatus = LocationPermissionStatus.denied,
    this.permissionStatusAfterRequest,
    this.permissionStatusSequenceAfterRequest,
    this.throwOnRequest = false,
    this.suggestions = const (
      nearbyMerchants: ['Blue Bottle Coffee'],
      likelyCategories: ['Coffee'],
    ),
    this.merchantCategories = const {},
  });

  final bool permissionGranted;
  final bool locationServiceEnabled;
  final LocationPermissionStatus permissionStatus;
  final LocationPermissionStatus? permissionStatusAfterRequest;
  final List<LocationPermissionStatus>? permissionStatusSequenceAfterRequest;
  final bool throwOnRequest;
  final ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) suggestions;
  final Map<String, String> merchantCategories;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  int permissionRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => locationServiceEnabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    if (throwOnRequest) {
      throw PlatformException(
        code: 'already_active',
        message: 'Image picker is already active',
      );
    }
    return permissionGranted;
  }

  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final sequence = permissionStatusSequenceAfterRequest;
    if (permissionRequests > 0 && sequence != null && sequence.isNotEmpty) {
      return sequence.removeAt(0);
    }
    if (permissionRequests > 0 && permissionStatusAfterRequest != null) {
      return permissionStatusAfterRequest!;
    }
    if (permissionRequests > 0 && permissionGranted) {
      return LocationPermissionStatus.granted;
    }
    return permissionStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls += 1;
    return true;
  }

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

class _ThrowingUserService extends UserService {
  _ThrowingUserService() : super(Dio());

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
    throw DioException(
      requestOptions: RequestOptions(path: '/profile'),
      type: DioExceptionType.connectionError,
      error: 'network down',
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

  test('settings enable redirects to app settings after denied forever',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
      'location_suggestions_permission_denied': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: false,
      permissionStatus: LocationPermissionStatus.deniedForever,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.redirectedToSystemSettings);
    expect(service.openAppSettingsCalls, 1);
    expect(container.read(locationAssistanceProvider).isEnabled, isFalse);
  });

  test('settings enable turns on immediately when OS permission is already granted',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: true,
      permissionStatus: LocationPermissionStatus.granted,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.enabled);
    expect(service.permissionRequests, 0);
    expect(container.read(locationAssistanceProvider).isEnabled, isTrue);
  });

  test(
      'settings enable trusts the final OS permission state after request returns',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: false,
      permissionStatus: LocationPermissionStatus.denied,
      permissionStatusAfterRequest: LocationPermissionStatus.granted,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.enabled);
    expect(container.read(locationAssistanceProvider).isEnabled, isTrue);
    expect(container.read(locationAssistanceProvider).permissionDenied, isFalse);
  });

  test(
      'settings enable waits briefly for granted OS permission to propagate after request',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: false,
      permissionStatus: LocationPermissionStatus.denied,
      permissionStatusSequenceAfterRequest: [
        LocationPermissionStatus.denied,
        LocationPermissionStatus.granted,
      ],
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.enabled);
    expect(container.read(locationAssistanceProvider).isEnabled, isTrue);
    expect(container.read(locationAssistanceProvider).permissionDenied, isFalse);
  });

  test(
      'settings enable stays on when the OS request grants permission before status reads catch up',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: true,
      permissionStatus: LocationPermissionStatus.denied,
      permissionStatusAfterRequest: LocationPermissionStatus.denied,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.enabled);
    expect(container.read(locationAssistanceProvider).isEnabled, isTrue);
    expect(container.read(locationAssistanceProvider).permissionDenied, isFalse);
  });

  test('reconcile does not immediately undo a fresh successful enable',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: true,
      permissionStatus: LocationPermissionStatus.denied,
      permissionStatusAfterRequest: LocationPermissionStatus.denied,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).enableFromSettings();
    await container
        .read(locationAssistanceProvider.notifier)
        .reconcileWithSystemState();

    expect(container.read(locationAssistanceProvider).isEnabled, isTrue);
  });

  test('settings enable redirects to location settings when device location is off',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeLocationAssistanceService(
      permissionGranted: false,
      locationServiceEnabled: false,
    );

    final container = buildContainer(
      prefs,
      service: service,
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();

    expect(outcome, LocationSettingsEnableOutcome.redirectedToLocationSettings);
    expect(service.openLocationSettingsCalls, 1);
    expect(service.openAppSettingsCalls, 0);
    expect(container.read(locationAssistanceProvider).isEnabled, isFalse);
  });

  test('pending settings enable completes after returning with location ready',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final firstContainer = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: false,
        locationServiceEnabled: false,
      ),
      userService: _FakeUserService(),
    );
    addTearDown(firstContainer.dispose);

    final firstOutcome = await firstContainer
        .read(locationAssistanceProvider.notifier)
        .enableFromSettings();
    expect(firstOutcome,
        LocationSettingsEnableOutcome.redirectedToLocationSettings);

    final secondContainer = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: true,
        locationServiceEnabled: true,
        permissionStatus: LocationPermissionStatus.granted,
      ),
      userService: _FakeUserService(),
    );
    addTearDown(secondContainer.dispose);

    await secondContainer
        .read(locationAssistanceProvider.notifier)
        .completePendingSettingsEnableIfPossible();

    final state = secondContainer.read(locationAssistanceProvider);
    expect(state.isEnabled, isTrue);
    expect(state.permissionDenied, isFalse);
  });

  test('reconcile turns the feature off when OS permission is later revoked',
      () async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: false,
        locationServiceEnabled: true,
        permissionStatus: LocationPermissionStatus.deniedForever,
      ),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container
        .read(locationAssistanceProvider.notifier)
        .reconcileWithSystemState();

    final state = container.read(locationAssistanceProvider);
    expect(state.isEnabled, isFalse);
    expect(state.permissionDenied, isTrue);
  });

  test('decline still marks prompt handled when profile sync fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      userService: _ThrowingUserService(),
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).declinePrompt();

    final rehydratedContainer = buildContainer(prefs);
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.hasPrompted, isTrue);
    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.isEnabled, isFalse);
  });

  test('prompt stays handled when permission request throws transiently',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(
        permissionGranted: false,
        throwOnRequest: true,
      ),
      userService: _FakeUserService(),
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).enableFromPrompt();

    final state = container.read(locationAssistanceProvider);
    expect(state.hasPrompted, isTrue);
    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.isEnabled, isFalse);
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

  test('provider keeps smart location state device-local even if server profile says enabled',
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

    expect(state.isEnabled, isFalse);
    expect(state.hasPrompted, isFalse);
  });
}
