import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(dioProvider));
});

final subscriptionProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return const SubscriptionStatus(tier: 'free', isPremium: false);
  }
  final service = ref.watch(subscriptionServiceProvider);
  return service.getStatus();
});
