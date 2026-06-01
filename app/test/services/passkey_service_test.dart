import 'dart:convert';

import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/core/network/request_options.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:passkeys/authenticator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passkeys/types.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  RequestOptions? lastRequestOptions;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingRegisterAuthenticator extends PasskeyAuthenticator {
  _ThrowingRegisterAuthenticator(this.error);

  final Object error;

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    throw error;
  }
}

class _SuccessfulRegisterAuthenticator extends PasskeyAuthenticator {
  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    return const RegisterResponseType(
      id: 'device-credential-id',
      rawId: 'raw-device-credential-id',
      clientDataJSON: 'client-data',
      attestationObject: 'attestation',
      transports: ['internal'],
    );
  }
}

class _RecordingAuthenticateAuthenticator extends PasskeyAuthenticator {
  AuthenticateRequestType? lastRequest;

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async {
    lastRequest = request;
    return const AuthenticateResponseType(
      id: 'credential-id',
      rawId: 'credential-id',
      clientDataJSON: 'client-data',
      authenticatorData: 'authenticator-data',
      signature: 'signature',
      userHandle: 'user-handle',
    );
  }
}

_JsonAdapter _successfulPasskeySignInAdapter() {
  return _JsonAdapter(
    (options) {
      if (options.path == 'auth/passkeys/login/start') {
        return ResponseBody.fromString(
          jsonEncode({
            'session': 'challenge-session',
            'challengeName': 'WEB_AUTHN',
            'credentialRequestOptions': jsonEncode({
              'challenge': 'Y2hhbGxlbmdl',
              'rpId': 'getconscia.com',
              'allowCredentials': [
                {
                  'type': 'public-key',
                  'id': 'credential-id',
                  'transports': ['internal']
                }
              ],
              'userVerification': 'preferred',
            }),
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      if (options.path == 'auth/passkeys/login/complete') {
        return ResponseBody.fromString(
          jsonEncode({
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'userId': 'user-id',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      throw StateError('Unexpected request to ${options.path}');
    },
  );
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

  test('friendlyPasskeyErrorMessage replaces generic passkey removal failures',
      () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/passkeys/credential-id'),
      response: Response(
        requestOptions:
            RequestOptions(path: '/api/auth/passkeys/credential-id'),
        statusCode: 400,
        data: const {},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      friendlyPasskeyErrorMessage(
        error,
        operation: PasskeyOperation.delete,
      ),
      'Passkey removal failed. Please refresh and try again.',
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
      "Couldn't sign in with that passkey. Try again or sign in with email.",
    );
  });

  test('friendlyPasskeyErrorMessage avoids account-specific unavailable copy',
      () {
    expect(
      friendlyPasskeyErrorMessage(NoCredentialsAvailableException()),
      "Couldn't sign in with that passkey. Try again or sign in with email.",
    );
  });

  test('friendlyPasskeyErrorMessage includes native setup error codes', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      friendlyPasskeyErrorMessage(
        PlatformException(
          code: 'failed',
          message: 'The operation could not be completed.',
        ),
        operation: PasskeyOperation.register,
      ),
      'Passkey setup is unavailable right now. Code: failed',
    );
  });

  test('friendlyPasskeyErrorMessage explains existing passkey setup blocks',
      () {
    expect(
      friendlyPasskeyErrorMessage(
        ExistingPasskeyRegistrationException(
          PlatformException(code: 'failed'),
        ),
        operation: PasskeyOperation.register,
      ),
      'A passkey is already registered for this account. Remove it from Security settings and from this device before setting it up again.',
    );
  });

  test('friendlyPasskeyErrorMessage explains duplicate iOS passkeys', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      friendlyPasskeyErrorMessage(
        ExcludeCredentialsCanNotBeRegisteredException(),
      ),
      'A passkey may already be saved on this device. Also remove the saved passkey in the Passwords app > getconscia.com before setting it up again.',
    );
  });

  test('passkeyDeviceRemovalInstructions returns iOS Passwords app guidance',
      () {
    expect(
      passkeyDeviceRemovalInstructions(platform: TargetPlatform.iOS),
      'Also remove the saved passkey in the Passwords app > getconscia.com before setting it up again.',
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

  test('signIn can allow external passkey selection', () async {
    final authenticator = _RecordingAuthenticateAuthenticator();
    final adapter = _successfulPasskeySignInAdapter();
    final service = PasskeyService(
      publicDio: Dio()..httpClientAdapter = adapter,
      authenticatedDio: Dio(),
      authenticator: authenticator,
    );

    final tokens = await service.signIn(
      'story-demo@example.com',
      preferImmediatelyAvailableCredentials: false,
    );

    expect(tokens.accessToken, 'access-token');
    final startRequest = adapter.requests.firstWhere(
      (request) => request.path == 'auth/passkeys/login/start',
    );
    expect(startRequest.data, {
      'email': 'story-demo@example.com',
      'allowExternalPasskeys': true,
    });
    expect(
      authenticator.lastRequest?.preferImmediatelyAvailableCredentials,
      isFalse,
    );
    expect(authenticator.lastRequest?.mediation, MediationType.Required);
  });

  test('signIn keeps external passkey flag off by default', () async {
    final authenticator = _RecordingAuthenticateAuthenticator();
    final adapter = _successfulPasskeySignInAdapter();
    final service = PasskeyService(
      publicDio: Dio()..httpClientAdapter = adapter,
      authenticatedDio: Dio(),
      authenticator: authenticator,
    );

    final tokens = await service.signIn('story-demo@example.com');

    expect(tokens.accessToken, 'access-token');
    final startRequest = adapter.requests.firstWhere(
      (request) => request.path == 'auth/passkeys/login/start',
    );
    expect(startRequest.data, {'email': 'story-demo@example.com'});
    expect(
      authenticator.lastRequest?.preferImmediatelyAvailableCredentials,
      isTrue,
    );
  });

  test('registerCurrentUserPasskey returns the device credential id', () async {
    final adapter = _JsonAdapter(
      (options) {
        if (options.path == 'auth/passkeys/register/start') {
          return ResponseBody.fromString(
            jsonEncode({
              'credentialCreationOptions': jsonEncode({
                'rp': {'id': 'getconscia.com', 'name': 'getconscia.com'},
                'user': {
                  'id': 'dXNlci0x',
                  'name': 'debug@example.com',
                  'displayName': 'debug@example.com',
                },
                'challenge': 'Y2hhbGxlbmdl',
                'pubKeyCredParams': [
                  {'type': 'public-key', 'alg': -7}
                ],
                'timeout': 60000,
                'excludeCredentials': <Map<String, dynamic>>[],
                'authenticatorSelection': {
                  'requireResidentKey': true,
                  'residentKey': 'required',
                  'userVerification': 'preferred',
                },
              }),
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path == 'auth/passkeys/register/complete') {
          return ResponseBody.fromString('', 204);
        }

        throw StateError('Unexpected request to ${options.path}');
      },
    );
    final service = PasskeyService(
      publicDio: Dio(),
      authenticatedDio: Dio()..httpClientAdapter = adapter,
      authenticator: _SuccessfulRegisterAuthenticator(),
    );

    final credentialId = await service.registerCurrentUserPasskey();

    expect(credentialId, 'device-credential-id');
    expect(adapter.requests.map((request) => request.path), [
      'auth/passkeys/register/start',
      'auth/passkeys/register/complete',
    ]);
    expect(
      adapter.lastRequestOptions?.extra[useAccessTokenRequestExtraKey],
      isTrue,
    );
  });

  test('registerCurrentUserPasskey reports sanitized diagnostics on failure',
      () async {
    final adapter = _JsonAdapter(
      (options) {
        if (options.path == 'auth/passkeys/register/start') {
          return ResponseBody.fromString(
            jsonEncode({
              'credentialCreationOptions': jsonEncode({
                'rp': {'id': 'getconscia.com', 'name': 'getconscia.com'},
                'user': {
                  'id': 'dXNlci0x',
                  'name': 'debug@example.com',
                  'displayName': 'debug@example.com',
                },
                'challenge': 'Y2hhbGxlbmdl',
                'pubKeyCredParams': [
                  {'type': 'public-key', 'alg': -7}
                ],
                'timeout': 60000,
                'excludeCredentials': [
                  {'type': 'public-key', 'id': 'PHgRKawUSV-hOj2g_THPdw'}
                ],
                'authenticatorSelection': {
                  'requireResidentKey': true,
                  'residentKey': 'required',
                  'userVerification': 'preferred',
                },
              }),
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path == 'client-diagnostics') {
          return ResponseBody.fromString('', 202);
        }

        throw StateError('Unexpected request to ${options.path}');
      },
    );
    final service = PasskeyService(
      publicDio: Dio(),
      authenticatedDio: Dio()..httpClientAdapter = adapter,
      authenticator: _ThrowingRegisterAuthenticator(
        PlatformException(
          code: 'failed',
          message: 'The operation could not be completed.',
          details: 'native details should be sanitized',
        ),
      ),
    );

    await expectLater(
      service.registerCurrentUserPasskey(),
      throwsA(isA<ExistingPasskeyRegistrationException>()),
    );

    final diagnosticRequest = adapter.requests
        .singleWhere((request) => request.path == 'client-diagnostics');
    expect(diagnosticRequest.method, 'POST');
    expect(diagnosticRequest.extra[useAccessTokenRequestExtraKey], isTrue);
    final payload = diagnosticRequest.data as Map<String, dynamic>;
    expect(payload['eventName'], 'passkey.register.failed');
    expect(payload['operation'], 'register');
    expect(payload['errorType'], 'PlatformException');
    expect(payload['errorCode'], 'failed');
    expect(payload['errorMessage'], 'The operation could not be completed.');
    expect(payload['context'], {
      'rpId': 'getconscia.com',
      'excludeCredentialsCount': '1',
      'residentKey': 'required',
      'userVerification': 'preferred',
    });
    final serializedPayload = jsonEncode(payload);
    expect(serializedPayload, isNot(contains('debug@example.com')));
    expect(serializedPayload, isNot(contains('Y2hhbGxlbmdl')));
    expect(serializedPayload,
        isNot(contains('native details should be sanitized')));
  });
}
