import 'dart:async';

import 'package:conscia_app/providers/app_availability_provider.dart';
import 'package:conscia_app/services/api_availability_service.dart';
import 'package:conscia_app/services/app_update_service.dart';
import 'package:conscia_app/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(bool isConnected) : _results = [isConnected];

  _FakeConnectivityService.sequence(List<bool> results)
      : _results = List<bool>.from(results);

  final List<bool> _results;
  int callCount = 0;

  @override
  Future<bool> hasNetworkConnection() async {
    callCount += 1;
    if (_results.isEmpty) {
      return false;
    }
    if (_results.length == 1) {
      return _results.first;
    }
    return _results.removeAt(0);
  }
}

class _FakeApiAvailabilityService implements ApiAvailabilityService {
  _FakeApiAvailabilityService({
    this.shouldThrow = false,
    this.shouldRequireUpgrade = false,
    this.livenessCompleter,
  });

  final bool shouldThrow;
  final bool shouldRequireUpgrade;
  final Completer<void>? livenessCompleter;
  int callCount = 0;

  @override
  Future<void> checkLiveness() async {
    callCount += 1;
    await livenessCompleter?.future;
    if (shouldRequireUpgrade) {
      throw const ApiUpgradeRequiredException('A newer version is required.');
    }
    if (shouldThrow) {
      throw const ApiUnavailableException('API unavailable');
    }
  }
}

class _FakeAppUpdateService implements AppUpdateService {
  _FakeAppUpdateService(this._result);

  final AppUpdateCheckResult _result;
  int callCount = 0;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    callCount += 1;
    return _result;
  }
}

void main() {
  test('refresh reports device offline without calling API or store checks',
      () async {
    final api = _FakeApiAvailabilityService();
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(false),
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(notifier.state.issue, AvailabilityIssue.deviceOffline);
    expect(api.callCount, 0);
    expect(updates.callCount, 0);
  });

  test(
      'refresh reports api unavailable when device is online but liveness fails',
      () async {
    final api = _FakeApiAvailabilityService(shouldThrow: true);
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(notifier.state.issue, AvailabilityIssue.apiUnavailable);
    expect(api.callCount, 1);
    expect(updates.callCount, 0);
  });

  test('refresh reports required update when store shows a newer version',
      () async {
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: _FakeApiAvailabilityService(),
      appUpdateService: _FakeAppUpdateService(
        const AppUpdateCheckResult(
          isUpdateRequired: true,
          installedVersion: '1.0.0',
          availableVersion: '1.1.0',
          storeUrl: 'https://example.com/store',
        ),
      ),
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(notifier.state.issue, AvailabilityIssue.updateRequired);
    expect(notifier.state.updateUrl, 'https://example.com/store');
    expect(notifier.state.availableVersion, '1.1.0');
  });

  test('refresh reports required update when backend rejects old app version',
      () async {
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: _FakeApiAvailabilityService(
        shouldRequireUpgrade: true,
      ),
      appUpdateService: _FakeAppUpdateService(const AppUpdateCheckResult()),
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(notifier.state.issue, AvailabilityIssue.updateRequired);
    expect(notifier.state.errorMessage, contains('required'));
  });

  test('refresh clears blockers when device, api, and store checks pass',
      () async {
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: _FakeApiAvailabilityService(),
      appUpdateService: _FakeAppUpdateService(
        const AppUpdateCheckResult(
          installedVersion: '1.0.0',
          availableVersion: '1.0.0',
        ),
      ),
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(notifier.state.issue, AvailabilityIssue.none);
    expect(notifier.state.isBlocked, isFalse);
  });

  test('backgrounding pauses availability refresh until resume', () async {
    final api = _FakeApiAvailabilityService();
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
      resumeRefreshDelay: Duration.zero,
    );

    await notifier.setForegrounded(false);
    await notifier.refresh();

    expect(api.callCount, 0);
    expect(updates.callCount, 0);

    await notifier.setForegrounded(true);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(api.callCount, 1);
    expect(updates.callCount, 1);
  });

  test('backgrounding ignores stale in-flight liveness failures', () async {
    final livenessCompleter = Completer<void>();
    final api = _FakeApiAvailabilityService(
      shouldThrow: true,
      livenessCompleter: livenessCompleter,
    );
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
      resumeRefreshDelay: Duration.zero,
    );

    final refreshFuture = notifier.refresh();
    await Future<void>.delayed(Duration.zero);
    await notifier.setForegrounded(false);

    livenessCompleter.complete();
    await refreshFuture;

    expect(notifier.state.issue, AvailabilityIssue.none);
    expect(notifier.state.isLoading, isFalse);
    expect(api.callCount, 1);
    expect(updates.callCount, 0);
  });

  test('resuming foreground debounces liveness refresh', () async {
    final api = _FakeApiAvailabilityService();
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final notifier = AppAvailabilityNotifier(
      connectivityService: _FakeConnectivityService(true),
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
      resumeRefreshDelay: const Duration(milliseconds: 20),
    );

    await notifier.setForegrounded(false);
    await notifier.setForegrounded(true);

    expect(api.callCount, 0);
    expect(updates.callCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(api.callCount, 1);
    expect(updates.callCount, 1);
  });

  test('refresh ignores a transient offline read immediately after resume',
      () async {
    final api = _FakeApiAvailabilityService();
    final updates = _FakeAppUpdateService(const AppUpdateCheckResult());
    final connectivity = _FakeConnectivityService.sequence([false, true]);
    final notifier = AppAvailabilityNotifier(
      connectivityService: connectivity,
      apiAvailabilityService: api,
      appUpdateService: updates,
      autoRefresh: false,
      refreshOnInit: false,
    );

    await notifier.refresh();

    expect(connectivity.callCount, 2);
    expect(notifier.state.issue, AvailabilityIssue.none);
    expect(api.callCount, 1);
    expect(updates.callCount, 1);
  });
}
