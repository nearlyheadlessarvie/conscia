import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/admin_entitlement_service.dart';

final adminEntitlementServiceProvider =
    Provider<AdminEntitlementService>((ref) {
  return AdminEntitlementService(ref.watch(dioProvider));
});
