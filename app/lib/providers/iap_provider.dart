import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/iap_service.dart';
import 'subscription_provider.dart';

final iapServiceProvider = Provider<IAPService>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  final service = IAPService(
    subscriptionService: subscriptionService,
    onPurchaseCompleted: () {
      ref.invalidate(subscriptionProvider);
    },
  );

  ref.onDispose(service.dispose);

  service.initialize();

  return service;
});

final iapStatusProvider = StreamProvider<IAPStatus>((ref) {
  final service = ref.watch(iapServiceProvider);
  return service.statusStream;
});
