import 'dart:typed_data';

import 'package:conscia_app/core/network/request_options.dart';
import 'package:conscia_app/services/account_password_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount += 1;
    lastRequestOptions = options;
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('posts new account password as an authenticated access-token request',
      () async {
    final adapter = _CapturingAdapter();
    final service = AccountPasswordService(
      Dio()..httpClientAdapter = adapter,
    );

    await service.setPassword('StrongPass123');

    expect(adapter.fetchCount, 1);
    expect(adapter.lastRequestOptions?.path, 'auth/password');
    expect(adapter.lastRequestOptions?.method, 'POST');
    expect(adapter.lastRequestOptions?.data, {'password': 'StrongPass123'});
    expect(
      adapter.lastRequestOptions?.extra[useAccessTokenRequestExtraKey],
      isTrue,
    );
  });

  test('includes current password when changing an existing account password',
      () async {
    final adapter = _CapturingAdapter();
    final service = AccountPasswordService(
      Dio()..httpClientAdapter = adapter,
    );

    await service.setPassword(
      'StrongPass123',
      currentPassword: 'OldPass123',
    );

    expect(adapter.lastRequestOptions?.data, {
      'password': 'StrongPass123',
      'currentPassword': 'OldPass123',
    });
  });
}
