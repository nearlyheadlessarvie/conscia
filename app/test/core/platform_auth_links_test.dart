import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile platform configs do not reference auth.getconscia.com', () {
    final androidManifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final iosEntitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();

    expect(androidManifest, isNot(contains('auth.getconscia.com')));
    expect(iosEntitlements, isNot(contains('auth.getconscia.com')));
  });
}
