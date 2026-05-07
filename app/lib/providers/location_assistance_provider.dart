import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_assistance_service.dart';
import 'usage_provider.dart';

class LocationAssistanceSuggestions {
  final List<String> nearbyMerchants;
  final List<String> likelyCategories;

  const LocationAssistanceSuggestions({
    required this.nearbyMerchants,
    required this.likelyCategories,
  });
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

  final SharedPreferences _prefs;
  final LocationAssistanceService _service;

  LocationAssistanceNotifier(this._prefs, this._service)
      : super(_loadFromPrefs(_prefs));

  static LocationAssistanceState _loadFromPrefs(SharedPreferences prefs) {
    return LocationAssistanceState(
      isEnabled: prefs.getBool(_enabledKey) ?? false,
      hasPrompted: prefs.getBool(_promptedKey) ?? false,
      permissionDenied: prefs.getBool(_deniedKey) ?? false,
    );
  }

  Future<void> declinePrompt() async {
    await _persistState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> enableFromPrompt() async {
    final granted = await _service.requestPermission();
    await _persistState(
      isEnabled: granted,
      hasPrompted: true,
      permissionDenied: !granted,
    );
  }

  Future<void> enableFromSettings() => enableFromPrompt();

  Future<void> disableFromSettings() async {
    await _persistState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> _persistState({
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
  }
}

final locationAssistanceProvider =
    StateNotifierProvider<LocationAssistanceNotifier, LocationAssistanceState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(locationAssistanceServiceProvider);
    return LocationAssistanceNotifier(prefs, service);
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
  );
});
