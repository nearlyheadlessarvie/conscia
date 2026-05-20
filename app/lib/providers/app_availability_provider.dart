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

  final ConnectivityService _connectivityService;
  final ApiAvailabilityService _apiAvailabilityService;
  final AppUpdateService _appUpdateService;
  final bool autoRefresh;
  final bool refreshOnInit;

  Timer? _timer;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final checkedAt = DateTime.now();
    final hasConnection = await _connectivityService.hasNetworkConnection();
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
    } on ApiUpgradeRequiredException catch (error) {
      state = state.copyWith(
        issue: AvailabilityIssue.updateRequired,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: error.message,
      );
      return;
    } on ApiUnavailableException catch (error) {
      state = state.copyWith(
        issue: AvailabilityIssue.apiUnavailable,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: error.message,
      );
      return;
    } catch (_) {
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
      state = state.copyWith(
        issue: AvailabilityIssue.none,
        isLoading: false,
        lastChecked: checkedAt,
        errorMessage: null,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
