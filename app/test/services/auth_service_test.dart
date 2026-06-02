import 'dart:typed_data';

import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/captcha_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('register posts captcha challenge fields', () async {
    final adapter = _CapturingAdapter(_registrationResponse);
    final service = AuthService(
      Dio()..httpClientAdapter = adapter,
      captchaService: _FakeCaptchaService(),
    );

    await service.register('new@example.com', 'SecureP@ss123');

    expect(adapter.lastRequestOptions?.path, 'auth/register');
    expect(adapter.lastRequestOptions?.data, {
      'email': 'new@example.com',
      'password': 'SecureP@ss123',
      'captchaToken': 'captcha-token',
      'captchaSiteKey': 'android-site-key',
    });
  });

  test('resendConfirmation posts captcha challenge fields', () async {
    final adapter = _CapturingAdapter(_confirmationResponse);
    final service = AuthService(
      Dio()..httpClientAdapter = adapter,
      captchaService: _FakeCaptchaService(),
    );

    await service.resendConfirmation('new@example.com');

    expect(adapter.lastRequestOptions?.path, 'auth/resend-confirmation');
    expect(adapter.lastRequestOptions?.data, {
      'email': 'new@example.com',
      'captchaToken': 'captcha-token',
      'captchaSiteKey': 'android-site-key',
    });
  });

  test('startPasswordReset posts captcha challenge fields', () async {
    final adapter = _CapturingAdapter(_confirmationResponse);
    final service = AuthService(
      Dio()..httpClientAdapter = adapter,
      captchaService: _FakeCaptchaService(),
    );

    await service.startPasswordReset('new@example.com');

    expect(adapter.lastRequestOptions?.path, 'auth/password-reset/start');
    expect(adapter.lastRequestOptions?.data, {
      'email': 'new@example.com',
      'captchaToken': 'captcha-token',
      'captchaSiteKey': 'android-site-key',
    });
  });
}

const _registrationResponse =
    '{"success":true,"requiresConfirmation":true,"email":"new@example.com","userId":"user-1"}';
const _confirmationResponse =
    '{"success":true,"requiresConfirmation":true,"email":"new@example.com"}';

class _FakeCaptchaService implements CaptchaService {
  @override
  Future<CaptchaChallenge?> execute(CaptchaAction action) async =>
      const CaptchaChallenge(
        token: 'captcha-token',
        siteKey: 'android-site-key',
      );
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._responseBody);

  final String _responseBody;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return ResponseBody.fromString(
      _responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
