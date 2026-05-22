import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import 'auth_provider.dart';
import '../services/admin_entitlement_service.dart';

final adminEntitlementServiceProvider =
    Provider<AdminEntitlementService>((ref) {
  return AdminEntitlementService(ref.watch(dioProvider));
});

final adminEntitlementAccessProvider = FutureProvider<bool>((ref) async {
  ref.watch(authCacheScopeProvider);
  final service = ref.watch(adminEntitlementServiceProvider);
  try {
    return await service.getAccess();
  } on DioException catch (error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return false;
    }
    return false;
  }
});
