import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/api_availability_service.dart';
import '../services/app_update_service.dart';
import '../services/connectivity_service.dart';

enum AvailabilityIssue {
  none,
  deviceOffline,
  apiUnavailable,
  updateRequired,
}

class AppAvailabilityState {
  const AppAvailabilityState({
    this.issue = AvailabilityIssue.none,
    this.isLoading = false,
    this.lastChecked,
    this.errorMessage,
    this.updateUrl,
    this.installedVersion,
    this.availableVersion,
  });

  final AvailabilityIssue issue;
  final bool isLoading;
  final DateTime? lastChecked;
  final String? errorMessage;
  final String? updateUrl;
  final String? installedVersion;
  final String? availableVersion;

  bool get isBlocked => issue != AvailabilityIssue.none;
  bool get isDeviceOffline => issue == AvailabilityIssue.deviceOffline;
  bool get isApiUnavailable => issue == AvailabilityIssue.apiUnavailable;
  bool get isUpdateRequired => issue == AvailabilityIssue.updateRequired;

  AppAvailabilityState copyWith({
    AvailabilityIssue? issue,
    bool? isLoading,
    DateTime? lastChecked,
    String? errorMessage,
    String? updateUrl,
    String? installedVersion,
    String? availableVersion,
  }) {
    return AppAvailabilityState(
      issue: issue ?? this.issue,
      isLoading: isLoading ?? this.isLoading,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage,
      updateUrl: updateUrl,
      installedVersion: installedVersion,
      availableVersion: availableVersion,
    );
  }
}

class AppAvailabilityNotifier extends StateNotifier<AppAvailabilityState> {
  AppAvailabilityNotifier({
    required ConnectivityService connectivityService,
    required ApiAvailabilityService apiAvailabilityService,
    required AppUpdateService appUpdateService,
    this.autoRefresh = true,
    this.refreshOnInit = true,
    this.resumeRefreshDelay = foregroundResumeRefreshDelay,
  })  : _connectivityService = connectivityService,
        _apiAvailabilityService = apiAvailabilityService,
        _appUpdateService = appUpdateService,
        super(const AppAvailabilityState()) {
    if (refreshOnInit) {
      refresh();
    }
    if (autoRefresh) {
      _timer = Timer.periodic(autoRetryInterval, (_) => refresh());
    }
  }

  static const autoRetryInterval = Duration(seconds: 10);
  static const offlineConfirmationDelay = Duration(milliseconds: 350);
  static const foregroundResumeRefreshDelay = Duration(seconds: 2);

  final ConnectivityService _connectivityService;
  final ApiAvailabilityService _apiAvailabilityService;
  final AppUpdateService _appUpdateService;
  final bool autoRefresh;
  final bool refreshOnInit;
  final Duration resumeRefreshDelay;

  Timer? _timer;
  Timer? _resumeRefreshTimer;
  bool _foregrounded = true;
  int _refreshToken = 0;

  Future<void> refresh() async {
    if (!_foregrounded) return;
    final refreshToken = ++_refreshToken;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final checkedAt = DateTime.now();
    final hasConnection = await _confirmNetworkConnection();
    if (!_canApplyRefresh(refreshToken)) return;
    if (!hasConnection) {
      state = state.copyWith(
        issue: AvailabilityIssue.deviceOffline,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: 'This device is offline.',
      );
      return;
    }

    try {
      await _apiAvailabilityService.checkLiveness();
      if (!_canApplyRefresh(refreshToken)) return;
    } on ApiUpgradeRequiredException catch (error) {
      if (!_canApplyRefresh(refreshToken)) return;
      state = state.copyWith(
        issue: AvailabilityIssue.updateRequired,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: error.message,
      );
      return;
    } on ApiUnavailableException catch (error) {
      if (!_canApplyRefresh(refreshToken)) return;
      state = state.copyWith(
        issue: AvailabilityIssue.apiUnavailable,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: error.message,
      );
      return;
    } catch (_) {
      if (!_canApplyRefresh(refreshToken)) return;
      state = state.copyWith(
        issue: AvailabilityIssue.apiUnavailable,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: 'Conscia is temporarily unavailable.',
      );
      return;
    }

    try {
      final update = await _appUpdateService.checkForUpdate();
      if (!_canApplyRefresh(refreshToken)) return;
      state = state.copyWith(
        issue: update.isUpdateRequired
            ? AvailabilityIssue.updateRequired
            : AvailabilityIssue.none,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: null,
        updateUrl: update.storeUrl,
        installedVersion: update.installedVersion,
        availableVersion: update.availableVersion,
      );
    } catch (_) {
      if (!_canApplyRefresh(refreshToken)) return;
      state = state.copyWith(
        issue: AvailabilityIssue.none,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: null,
      );
    }
  }

  Future<bool> _confirmNetworkConnection() async {
    final hasConnection = await _connectivityService.hasNetworkConnection();
    if (hasConnection) {
      return true;
    }

    await Future<void>.delayed(offlineConfirmationDelay);
    return _connectivityService.hasNetworkConnection();
  }

  bool _canApplyRefresh(int refreshToken) {
    return _foregrounded && refreshToken == _refreshToken;
  }

  Future<void> setForegrounded(bool value) async {
    if (_foregrounded == value) return;
    _foregrounded = value;
    if (!_foregrounded) {
      _refreshToken += 1;
      _timer?.cancel();
      _timer = null;
      _resumeRefreshTimer?.cancel();
      _resumeRefreshTimer = null;
      state = state.copyWith(isLoading: false);
      return;
    }

    if (autoRefresh && _timer == null) {
      _timer = Timer.periodic(autoRetryInterval, (_) => refresh());
    }
    _resumeRefreshTimer?.cancel();
    _resumeRefreshTimer = Timer(resumeRefreshDelay, () {
      _resumeRefreshTimer = null;
      unawaited(refresh());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeRefreshTimer?.cancel();
    super.dispose();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return PlatformConnectivityService();
});

final apiAvailabilityServiceProvider = Provider<ApiAvailabilityService>((ref) {
  final dio = ref.watch(dioProvider);
  return DioApiAvailabilityService(dio);
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return StoreAppUpdateService();
});

final appAvailabilityProvider =
    StateNotifierProvider<AppAvailabilityNotifier, AppAvailabilityState>((ref) {
  return AppAvailabilityNotifier(
    connectivityService: ref.watch(connectivityServiceProvider),
    apiAvailabilityService: ref.watch(apiAvailabilityServiceProvider),
    appUpdateService: ref.watch(appUpdateServiceProvider),
  );
});
