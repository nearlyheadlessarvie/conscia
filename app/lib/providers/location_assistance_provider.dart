import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_assistance_service.dart';
import 'usage_provider.dart';

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
    await _prefs.setBool(_enabledKey, false);
    await _prefs.setBool(_promptedKey, true);
    await _prefs.setBool(_deniedKey, false);
    state = const LocationAssistanceState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> enableFromPrompt() async {
    final granted = await _service.requestPermission();
    await _prefs.setBool(_enabledKey, granted);
    await _prefs.setBool(_promptedKey, true);
    await _prefs.setBool(_deniedKey, !granted);
    state = LocationAssistanceState(
      isEnabled: granted,
      hasPrompted: true,
      permissionDenied: !granted,
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
