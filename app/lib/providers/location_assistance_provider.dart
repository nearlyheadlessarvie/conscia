import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../services/location_assistance_service.dart';
import '../services/user_service.dart';
import 'usage_provider.dart';
import 'user_provider.dart';

enum LocationSettingsEnableOutcome {
  enabled,
  denied,
  redirectedToLocationSettings,
  redirectedToSystemSettings,
}

class LocationAssistanceSuggestions {
  final List<String> nearbyMerchants;
  final List<String> likelyCategories;
  final Map<String, String> merchantCategories;

  const LocationAssistanceSuggestions({
    required this.nearbyMerchants,
    required this.likelyCategories,
    this.merchantCategories = const {},
  });

  String? categoryForMerchant(String merchant) => merchantCategories[merchant];
}

class LocationAssistanceState {
  final bool isEnabled;
  final bool hasPrompted;
  final bool permissionDenied;

  const LocationAssistanceState({
    required this.isEnabled,
    required this.hasPrompted,
    required this.permissionDenied,
  });

  bool get shouldPromptOnFeatureOpen => !hasPrompted;
}

class LocationAssistanceNotifier extends StateNotifier<LocationAssistanceState> {
  static const _enabledKey = 'location_suggestions_enabled';
  static const _promptedKey = 'location_suggestions_prompted';
  static const _deniedKey = 'location_suggestions_permission_denied';
  static const _pendingEnableKey = 'location_suggestions_pending_enable';

  final SharedPreferences _prefs;
  final LocationAssistanceService _service;
  final UserService _userService;
  final Ref _ref;

  LocationAssistanceNotifier(
    this._ref,
    this._prefs,
    this._service,
    this._userService, {
    bool? serverEnabled,
  }) : super(_loadState(_prefs, serverEnabled: serverEnabled));

  static LocationAssistanceState _loadState(
    SharedPreferences prefs, {
    bool? serverEnabled,
  }) {
    return LocationAssistanceState(
      isEnabled: serverEnabled ?? prefs.getBool(_enabledKey) ?? false,
      hasPrompted: prefs.getBool(_promptedKey) ?? false,
      permissionDenied: prefs.getBool(_deniedKey) ?? false,
    );
  }

  Future<void> declinePrompt() async {
    await _prefs.setBool(_pendingEnableKey, false);
    await _persistStateAndProfile(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> enableFromPrompt() async {
    final granted = await _service.requestPermission();
    await _persistStateAndProfile(
      isEnabled: granted,
      hasPrompted: true,
      permissionDenied: !granted,
    );
  }

  Future<LocationSettingsEnableOutcome> enableFromSettings() async {
    if (!await _service.isLocationServiceEnabled()) {
      await _prefs.setBool(_pendingEnableKey, true);
      await _service.openLocationSettings();
      return LocationSettingsEnableOutcome.redirectedToLocationSettings;
    }

    final permission = await _service.checkPermissionStatus();
    if (permission == LocationPermissionStatus.deniedForever) {
      await _prefs.setBool(_pendingEnableKey, true);
      await _service.openAppSettings();
      return LocationSettingsEnableOutcome.redirectedToSystemSettings;
    }

    if (state.permissionDenied) {
      final deniedStatePermission = await _service.checkPermissionStatus();
      if (deniedStatePermission == LocationPermissionStatus.deniedForever) {
        await _prefs.setBool(_pendingEnableKey, true);
        await _service.openAppSettings();
        return LocationSettingsEnableOutcome.redirectedToSystemSettings;
      }
    }

    final granted = await _service.requestPermission();
    await _persistStateAndProfile(
      isEnabled: granted,
      hasPrompted: true,
      permissionDenied: !granted,
    );

    if (!granted) {
      final permission = await _service.checkPermissionStatus();
      if (permission == LocationPermissionStatus.deniedForever) {
        await _prefs.setBool(_pendingEnableKey, true);
        await _service.openAppSettings();
        return LocationSettingsEnableOutcome.redirectedToSystemSettings;
      }
      return LocationSettingsEnableOutcome.denied;
    }

    return LocationSettingsEnableOutcome.enabled;
  }

  Future<void> disableFromSettings() async {
    await _prefs.setBool(_pendingEnableKey, false);
    await _persistStateAndProfile(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> completePendingSettingsEnableIfPossible() async {
    final pendingEnable = _prefs.getBool(_pendingEnableKey) ?? false;
    if (!pendingEnable) return;

    if (!await _service.isLocationServiceEnabled()) return;
    final permission = await _service.checkPermissionStatus();
    if (permission != LocationPermissionStatus.granted) return;

    await _prefs.setBool(_pendingEnableKey, false);
    await _persistStateAndProfile(
      isEnabled: true,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> reconcileWithSystemState() async {
    final pendingEnable = _prefs.getBool(_pendingEnableKey) ?? false;
    if (pendingEnable) {
      await completePendingSettingsEnableIfPossible();
      return;
    }

    if (!state.isEnabled) return;

    final locationServicesEnabled = await _service.isLocationServiceEnabled();
    final permission = await _service.checkPermissionStatus();
    final shouldRemainEnabled =
        locationServicesEnabled && permission == LocationPermissionStatus.granted;
    if (shouldRemainEnabled) return;

    await _persistStateAndProfile(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: permission != LocationPermissionStatus.granted,
    );
  }

  Future<void> _persistStateAndProfile({
    required bool isEnabled,
    required bool hasPrompted,
    required bool permissionDenied,
  }) async {
    await _prefs.setBool(_enabledKey, isEnabled);
    await _prefs.setBool(_promptedKey, hasPrompted);
    await _prefs.setBool(_deniedKey, permissionDenied);
    state = LocationAssistanceState(
      isEnabled: isEnabled,
      hasPrompted: hasPrompted,
      permissionDenied: permissionDenied,
    );
    try {
      await _userService.updateProfile(
        locationSuggestionsEnabled: isEnabled,
      );
      _ref.invalidate(currentUserProvider);
    } on DioException {
      // Keep the local prompt state sticky even if profile sync fails.
    }
  }
}

final locationAssistanceProvider =
    StateNotifierProvider<LocationAssistanceNotifier, LocationAssistanceState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(locationAssistanceServiceProvider);
    final userService = ref.watch(userServiceProvider);
    final serverEnabled =
        ref.read(currentUserProvider).valueOrNull?.locationSuggestionsEnabled;
    return LocationAssistanceNotifier(
      ref,
      prefs,
      service,
      userService,
      serverEnabled: serverEnabled,
    );
  },
);

final locationAssistanceSuggestionsProvider =
    Provider<LocationAssistanceSuggestions>((ref) {
  final locationAssistance = ref.watch(locationAssistanceProvider);
  if (!locationAssistance.isEnabled) {
    return const LocationAssistanceSuggestions(
      nearbyMerchants: [],
      likelyCategories: [],
    );
  }

  final service = ref.watch(locationAssistanceServiceProvider);
  final suggestions = service.getTransactionSuggestions();
  return LocationAssistanceSuggestions(
    nearbyMerchants: suggestions.nearbyMerchants,
    likelyCategories: suggestions.likelyCategories,
    merchantCategories: {
      for (final merchant in suggestions.nearbyMerchants)
        if (service.categoryForMerchant(merchant) case final category?)
          merchant: category,
    },
  );
});
