import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../services/location_assistance_service.dart';
import 'usage_provider.dart';

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
  static const _permissionResolutionAttempts = 4;
  static const _permissionResolutionDelay = Duration(milliseconds: 200);
  static const _reconcileCooldown = Duration(seconds: 2);

  final SharedPreferences _prefs;
  final LocationAssistanceService _service;
  Future<LocationSettingsEnableOutcome>? _enableRequest;
  DateTime? _lastSuccessfulEnableAt;

  LocationAssistanceNotifier(
    SharedPreferences prefs,
    LocationAssistanceService service,
  )   : _prefs = prefs,
        _service = service,
        super(_loadState(prefs));

  static LocationAssistanceState _loadState(
    SharedPreferences prefs,
  ) {
    return LocationAssistanceState(
      isEnabled: prefs.getBool(_enabledKey) ?? false,
      hasPrompted: prefs.getBool(_promptedKey) ?? false,
      permissionDenied: prefs.getBool(_deniedKey) ?? false,
    );
  }

  Future<void> declinePrompt() async {
    await _prefs.setBool(_pendingEnableKey, false);
    await _persistState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> enableFromPrompt() async {
    final inFlight = _enableRequest;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final request = _enableFromPromptInternal();
    _enableRequest = request;
    try {
      await request;
    } finally {
      if (identical(_enableRequest, request)) {
        _enableRequest = null;
      }
    }
  }

  Future<LocationSettingsEnableOutcome> _enableFromPromptInternal() async {
    final granted = await _resolvePermissionRequest();
    return granted
        ? LocationSettingsEnableOutcome.enabled
        : LocationSettingsEnableOutcome.denied;
  }

  Future<LocationSettingsEnableOutcome> enableFromSettings() async {
    final inFlight = _enableRequest;
    if (inFlight != null) {
      return inFlight;
    }

    final request = _enableFromSettingsInternal();
    _enableRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_enableRequest, request)) {
        _enableRequest = null;
      }
    }
  }

  Future<LocationSettingsEnableOutcome> _enableFromSettingsInternal() async {
    if (!await _service.isLocationServiceEnabled()) {
      await _prefs.setBool(_pendingEnableKey, true);
      await _service.openLocationSettings();
      return LocationSettingsEnableOutcome.redirectedToLocationSettings;
    }

    final permission = await _service.checkPermissionStatus();
    if (permission == LocationPermissionStatus.granted) {
      await _persistState(
        isEnabled: true,
        hasPrompted: true,
        permissionDenied: false,
      );
      return LocationSettingsEnableOutcome.enabled;
    }

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

    final granted = await _resolvePermissionRequest();
    if (granted) return LocationSettingsEnableOutcome.enabled;

    final deniedPermission = await _service.checkPermissionStatus();
    if (deniedPermission == LocationPermissionStatus.deniedForever) {
      await _prefs.setBool(_pendingEnableKey, true);
      await _service.openAppSettings();
      return LocationSettingsEnableOutcome.redirectedToSystemSettings;
    }
    return LocationSettingsEnableOutcome.denied;
  }

  Future<void> disableFromSettings() async {
    await _prefs.setBool(_pendingEnableKey, false);
    await _persistState(
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
    await _persistState(
      isEnabled: true,
      hasPrompted: true,
      permissionDenied: false,
    );
  }

  Future<void> reconcileWithSystemState() async {
    if (_enableRequest != null) return;
    final lastSuccessfulEnableAt = _lastSuccessfulEnableAt;
    if (lastSuccessfulEnableAt != null &&
        DateTime.now().difference(lastSuccessfulEnableAt) <
            _reconcileCooldown) {
      return;
    }

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

    await _persistState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: permission != LocationPermissionStatus.granted,
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

  Future<bool> _resolvePermissionRequest() async {
    await _setLocalState(
      isEnabled: state.isEnabled,
      hasPrompted: true,
      permissionDenied: false,
    );

    var requestGranted = false;
    try {
      requestGranted = await _service.requestPermission();
    } on PlatformException {
      // Android can report overlapping permission requests transiently.
      // Fall through to the final OS state check below.
    }

    if (requestGranted) {
      _lastSuccessfulEnableAt = DateTime.now();
      await _prefs.setBool(_pendingEnableKey, false);
      await _persistState(
        isEnabled: true,
        hasPrompted: true,
        permissionDenied: false,
      );
      return true;
    }

    final locationServicesEnabled = await _resolveLocationServiceState();
    final permission = await _resolvePermissionStatus();
    final resolvedGranted =
        locationServicesEnabled && permission == LocationPermissionStatus.granted;

    await _persistState(
      isEnabled: resolvedGranted,
      hasPrompted: true,
      permissionDenied: !resolvedGranted,
    );
    return resolvedGranted;
  }

  Future<void> _setLocalState({
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

  Future<bool> _resolveLocationServiceState() async {
    var enabled = await _service.isLocationServiceEnabled();
    if (enabled) return true;

    for (var attempt = 1; attempt < _permissionResolutionAttempts; attempt++) {
      await Future<void>.delayed(_permissionResolutionDelay);
      enabled = await _service.isLocationServiceEnabled();
      if (enabled) return true;
    }
    return false;
  }

  Future<LocationPermissionStatus> _resolvePermissionStatus() async {
    var permission = await _service.checkPermissionStatus();
    if (permission == LocationPermissionStatus.granted) {
      return permission;
    }

    for (var attempt = 1; attempt < _permissionResolutionAttempts; attempt++) {
      await Future<void>.delayed(_permissionResolutionDelay);
      permission = await _service.checkPermissionStatus();
      if (permission == LocationPermissionStatus.granted) {
        return permission;
      }
    }

    return permission;
  }
}

final locationAssistanceProvider =
    StateNotifierProvider<LocationAssistanceNotifier, LocationAssistanceState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(locationAssistanceServiceProvider);
    return LocationAssistanceNotifier(
      prefs,
      service,
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
