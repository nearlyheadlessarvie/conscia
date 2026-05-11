import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conscia_app/services/push_notification_service.dart';

void main() {
  test('push service can start with push disabled without touching Firebase',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(pushNotificationServiceProvider);

    await service.start();
  });
}
