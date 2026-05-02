import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(dioProvider));
});

final subscriptionProvider =
    FutureProvider<SubscriptionStatus>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getStatus();
});
