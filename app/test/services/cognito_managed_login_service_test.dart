import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _fakeJwt({
  required String sub,
  String? email,
  DateTime? expiresAt,
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': sub,
        if (email != null) 'email': email,
        if (expiresAt != null) 'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      }),
    ),
  );
  return '$header.$payload.signature';
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;
  Object? lastRequestBody;
  final Queue<ResponseBody> _responses = Queue<ResponseBody>();

  void enqueueJsonResponse(Map<String, Object?> body) {
    _responses.add(
      ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    lastRequestBody = options.data;
    if (_responses.isEmpty) {
      throw StateError('No queued response for ${options.path}');
    }
    return _responses.removeFirst();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('signIn exchanges native auth-sheet callback code for Cognito tokens',
      () async {
    final adapter = _CapturingAdapter()
      ..enqueueJsonResponse({
        'access_token': 'managed-access-token',
        'id_token': _fakeJwt(
          sub: '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a',
          email: 'story-demo@example.com',
        ),
        'refresh_token': 'managed-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    Uri? sheetUri;
    String? callbackUrlScheme;
    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      openAuthSession: (uri, {required appCallbackUri}) async {
        sheetUri = uri;
        callbackUrlScheme = appCallbackUri.scheme;
        return Uri.parse(
          'conscia://auth/callback'
          '?code=managed-code'
          '&state=${uri.queryParameters['state']}',
        );
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    final tokens = await service.signIn(
      provider: CognitoManagedLoginProvider.google,
    );

    expect(tokens.accessToken, 'managed-access-token');
    expect(tokens.idToken, isNotEmpty);
    expect(tokens.refreshToken, 'managed-refresh-token');
    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');

    expect(sheetUri, isNotNull);
    expect(sheetUri!.path, '/oauth2/authorize');
    expect(sheetUri!.queryParameters['client_id'], 'managed-client-id');
    expect(
      sheetUri!.queryParameters['redirect_uri'],
      'conscia://auth/callback',
    );
    expect(sheetUri!.queryParameters['response_type'], 'code');
    expect(
      sheetUri!.queryParameters['identity_provider'],
      'Google',
    );
    expect(
      sheetUri!.queryParameters['scope'],
      contains('aws.cognito.signin.user.admin'),
    );
    expect(sheetUri!.queryParameters['code_challenge_method'], 'S256');
    expect(sheetUri!.queryParameters['code_challenge'], isNotEmpty);
    expect(sheetUri!.queryParameters['state'], isNotEmpty);
    expect(callbackUrlScheme, 'conscia');

    expect(adapter.lastRequestOptions?.path, '/oauth2/token');
    expect(
      adapter.lastRequestOptions?.headers[Headers.contentTypeHeader],
      'application/x-www-form-urlencoded',
    );
    expect(adapter.lastRequestBody, isA<String>());
    expect(adapter.lastRequestBody as String,
        contains('grant_type=authorization_code'));
    expect(adapter.lastRequestBody as String,
        contains('client_id=managed-client-id'));
    expect(adapter.lastRequestBody as String, contains('code=managed-code'));
    expect(
      adapter.lastRequestBody as String,
      contains(
        'redirect_uri=${Uri.encodeQueryComponent('conscia://auth/callback')}',
      ),
    );
    expect(adapter.lastRequestBody as String, contains('code_verifier='));
  });

  test('signUp uses Cognito signup endpoint with login hint', () async {
    final adapter = _CapturingAdapter()
      ..enqueueJsonResponse({
        'access_token': 'signup-access-token',
        'id_token': _fakeJwt(
          sub: '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a',
          email: 'story-demo@example.com',
        ),
        'refresh_token': 'signup-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    Uri? sheetUri;
    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      openAuthSession: (uri, {required appCallbackUri}) async {
        sheetUri = uri;
        return Uri.parse(
          'conscia://auth/callback'
          '?code=signup-code'
          '&state=${uri.queryParameters['state']}',
        );
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    final tokens = await service.signUp(emailHint: 'story-demo@example.com');

    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');
    expect(sheetUri, isNotNull);
    expect(sheetUri!.path, '/signup');
    expect(
      sheetUri!.queryParameters['login_hint'],
      'story-demo@example.com',
    );
  });

  test('signIn accepts custom-scheme callback handoff from the auth web page',
      () async {
    final adapter = _CapturingAdapter()
      ..enqueueJsonResponse({
        'access_token': 'managed-access-token',
        'id_token': _fakeJwt(
          sub: '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a',
          email: 'story-demo@example.com',
        ),
        'refresh_token': 'managed-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });

    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      openAuthSession: (uri, {required appCallbackUri}) async => Uri.parse(
        'conscia://auth/callback'
        '?code=managed-code'
        '&state=${uri.queryParameters['state']}',
      ),
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    final tokens =
        await service.signIn(provider: CognitoManagedLoginProvider.google);

    expect(tokens.accessToken, 'managed-access-token');
    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');
  });

  test('refreshSession returns fresh tokens from the token endpoint', () async {
    final adapter = _CapturingAdapter()
      ..enqueueJsonResponse({
        'access_token': 'next-access-token',
        'id_token': _fakeJwt(
          sub: '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a',
          email: 'story-demo@example.com',
        ),
        'refresh_token': 'next-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      openAuthSession: (uri, {required appCallbackUri}) async =>
          throw UnimplementedError(),
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    final tokens = await service.refreshSession('managed-refresh-token');

    expect(tokens.accessToken, 'next-access-token');
    expect(tokens.refreshToken, 'next-refresh-token');
    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');
    expect(adapter.lastRequestOptions?.path, '/oauth2/token');
    expect(adapter.lastRequestBody, isA<String>());
    expect(adapter.lastRequestBody as String,
        contains('grant_type=refresh_token'));
    expect(
      adapter.lastRequestBody as String,
      contains('refresh_token=managed-refresh-token'),
    );
  });

  test('logout uses managed auth session so the browser tab can close',
      () async {
    Uri? sheetUri;
    Uri? callbackUri;
    final service = CognitoManagedLoginService(
      dio: Dio(),
      openAuthSession: (uri, {required appCallbackUri}) async {
        sheetUri = uri;
        callbackUri = appCallbackUri;
        return Uri.parse('conscia://auth/logout');
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    await service.logout();

    expect(sheetUri, isNotNull);
    expect(sheetUri!.path, '/logout');
    expect(sheetUri!.queryParameters['client_id'], 'managed-client-id');
    expect(
      sheetUri!.queryParameters['logout_uri'],
      'conscia://auth/logout',
    );
    expect(callbackUri, Uri.parse('conscia://auth/logout'));
  });

  test(
      'signIn maps native auth-sheet cancellation to managed login cancellation',
      () async {
    final service = CognitoManagedLoginService(
      dio: Dio(),
      openAuthSession: (uri, {required appCallbackUri}) async {
        throw PlatformException(
          code: 'CANCELED',
          message: 'User canceled login',
        );
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('conscia://auth/callback'),
      appRedirectUri: Uri.parse('conscia://auth/callback'),
      logoutUri: Uri.parse('conscia://auth/logout'),
    );

    await expectLater(
      service.signIn(provider: CognitoManagedLoginProvider.google),
      throwsA(isA<CognitoManagedLoginCancelledException>()),
    );
  });
}
