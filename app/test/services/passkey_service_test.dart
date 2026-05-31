import 'dart:convert';
import 'dart:typed_data';

import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/core/network/request_options.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passkeys/exceptions.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(() {
    AppError.resetForTests();
    debugDefaultTargetPlatformOverride = null;
  });

  test('friendlyPasskeyErrorMessage preserves API/server failures', () {
    AppError.configure(
      referenceIdFactory: () => 'PASS1234',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/passkeys/login/complete'),
      response: Response(
        requestOptions:
            RequestOptions(path: '/api/auth/passkeys/login/complete'),
        statusCode: 500,
        data: {'error': 'Unexpected failure'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      friendlyPasskeyErrorMessage(error),
      'Conscia is having trouble right now. Please try again. Reference: PASS1234',
    );
  });

  test('friendlyPasskeyErrorMessage maps domain association platform errors',
      () {
    expect(
      friendlyPasskeyErrorMessage(
        PlatformException(
          code: 'domain-not-associated',
          message: 'webcredentials association missing',
        ),
      ),
      'Passkeys are not fully configured for this app yet.',
    );
  });

  test('friendlyPasskeyErrorMessage maps unhandled Android passkey errors', () {
    expect(
      friendlyPasskeyErrorMessage(
        UnhandledAuthenticatorException(
          'android-unhandled: android.credentials.GetCredentialException.TYPE_UNKNOWN',
          'No credentials available',
          null,
        ),
      ),
      'Passkey sign-in could not use the saved credential on this device. Sign in with email, then remove and set up the passkey again.',
    );
  });

  test('friendlyPasskeyErrorMessage explains duplicate iOS passkeys', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      friendlyPasskeyErrorMessage(
        ExcludeCredentialsCanNotBeRegisteredException(),
      ),
      'A passkey may already be saved on this device. Also remove the saved passkey in iOS Settings > Passwords > getconscia.com before setting it up again.',
    );
  });

  test('passkeyDeviceRemovalInstructions returns Android guidance', () {
    expect(
      passkeyDeviceRemovalInstructions(platform: TargetPlatform.android),
      'Also remove the saved passkey in Google Password Manager > Passwords & passkeys > getconscia.com before setting it up again.',
    );
  });

  test('isPasskeyCredentialUnavailable identifies stale local credentials', () {
    expect(isPasskeyCredentialUnavailable(NoCredentialsAvailableException()),
        isTrue);
    expect(
      isPasskeyCredentialUnavailable(
        UnhandledAuthenticatorException(
          'android-unhandled: android.credentials.GetCredentialException.TYPE_UNKNOWN',
          'No credentials available',
          null,
        ),
      ),
      isTrue,
    );
  });

  test('listCurrentUserPasskeys uses authenticated access token request',
      () async {
    final adapter = _JsonAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode([
          {
            'credentialId': 'credential-id',
            'friendlyName': 'Android',
            'createdAt': '2026-05-31T02:15:00Z',
            'relyingPartyId': 'getconscia.com',
            'authenticatorAttachment': 'platform',
            'transports': ['internal'],
          }
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    final service = PasskeyService(
      publicDio: Dio(),
      authenticatedDio: Dio()..httpClientAdapter = adapter,
    );

    final credentials = await service.listCurrentUserPasskeys();

    final credential = credentials.single;
    expect(credential.credentialId, 'credential-id');
    expect(credential.friendlyName, 'Android');
    expect(credential.relyingPartyId, 'getconscia.com');
    expect(credential.authenticatorAttachment, 'platform');
    expect(credential.transports, ['internal']);
    expect(adapter.lastRequestOptions?.path, 'auth/passkeys');
    expect(adapter.lastRequestOptions?.method, 'GET');
    expect(
      adapter.lastRequestOptions?.extra[useAccessTokenRequestExtraKey],
      isTrue,
    );
  });

  test('deleteCurrentUserPasskey deletes selected credential', () async {
    final adapter = _JsonAdapter((_) => ResponseBody.fromString('', 204));
    final service = PasskeyService(
      publicDio: Dio(),
      authenticatedDio: Dio()..httpClientAdapter = adapter,
    );

    await service.deleteCurrentUserPasskey('credential/id');

    expect(adapter.lastRequestOptions?.path, 'auth/passkeys/credential%2Fid');
    expect(adapter.lastRequestOptions?.method, 'DELETE');
    expect(
      adapter.lastRequestOptions?.extra[useAccessTokenRequestExtraKey],
      isTrue,
    );
  });
}
