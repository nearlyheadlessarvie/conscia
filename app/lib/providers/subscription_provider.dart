import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  throw UnimplementedError('Override with Dio instance');
});

final subscriptionProvider =
    FutureProvider<SubscriptionStatus>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getStatus();
});
