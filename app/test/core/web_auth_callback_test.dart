import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web auth callback page posts the OAuth result back to Flutter', () {
    final page = File('web/auth.html');

    expect(page.existsSync(), isTrue);
    final html = page.readAsStringSync();
    expect(html, contains('flutter-web-auth-2'));
    expect(html, contains('postMessage'));
    expect(html, contains('localStorage.setItem'));
  });
}
