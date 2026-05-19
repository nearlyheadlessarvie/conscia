import 'package:flutter/foundation.dart';
import 'package:new_version_plus/new_version_plus.dart';

import '../core/constants/api_constants.dart';

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    this.isUpdateRequired = false,
    this.installedVersion,
    this.availableVersion,
    this.storeUrl,
  });

  final bool isUpdateRequired;
  final String? installedVersion;
  final String? availableVersion;
  final String? storeUrl;
}

abstract class AppUpdateService {
  Future<AppUpdateCheckResult> checkForUpdate();
}

class StoreAppUpdateService implements AppUpdateService {
  StoreAppUpdateService({
    NewVersionPlus? newVersionPlus,
  }) : _newVersionPlus = newVersionPlus ?? NewVersionPlus();

  final NewVersionPlus _newVersionPlus;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (kIsWeb || ApiConstants.useMockAuth) {
      return const AppUpdateCheckResult();
    }

    final status = await _newVersionPlus.getVersionStatus();
    if (status == null) {
      return const AppUpdateCheckResult();
    }

    return AppUpdateCheckResult(
      isUpdateRequired: status.canUpdate,
      installedVersion: status.localVersion,
      availableVersion: status.storeVersion,
      storeUrl: status.appStoreLink,
    );
  }
}
