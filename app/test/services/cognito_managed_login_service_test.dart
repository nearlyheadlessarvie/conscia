import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

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
  test('signIn exchanges authorize callback code for Cognito tokens', () async {
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
    final incomingLinks = StreamController<Uri>();
    addTearDown(incomingLinks.close);

    Uri? launchedUri;
    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      incomingLinks: incomingLinks.stream,
      readInitialLink: () async => null,
      launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
        launchedUri = uri;
        Future<void>.microtask(() {
          incomingLinks.add(
            Uri.parse(
              'https://auth.getconscia.com/open/auth/callback'
              '?code=managed-code'
              '&state=${uri.queryParameters['state']}',
            ),
          );
        });
        return true;
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('https://auth.getconscia.com/open/auth/callback'),
      logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
    );

    final tokens = await service.signIn(
      provider: CognitoManagedLoginProvider.google,
    );

    expect(tokens.accessToken, 'managed-access-token');
    expect(tokens.idToken, isNotEmpty);
    expect(tokens.refreshToken, 'managed-refresh-token');
    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');

    expect(launchedUri, isNotNull);
    expect(launchedUri!.path, '/oauth2/authorize');
    expect(launchedUri!.queryParameters['client_id'], 'managed-client-id');
    expect(
      launchedUri!.queryParameters['redirect_uri'],
      'https://auth.getconscia.com/open/auth/callback',
    );
    expect(launchedUri!.queryParameters['response_type'], 'code');
    expect(
      launchedUri!.queryParameters['identity_provider'],
      'Google',
    );
    expect(
      launchedUri!.queryParameters['scope'],
      contains('aws.cognito.signin.user.admin'),
    );
    expect(launchedUri!.queryParameters['code_challenge_method'], 'S256');
    expect(launchedUri!.queryParameters['code_challenge'], isNotEmpty);
    expect(launchedUri!.queryParameters['state'], isNotEmpty);

    expect(adapter.lastRequestOptions?.path, '/oauth2/token');
    expect(
      adapter.lastRequestOptions?.headers[Headers.contentTypeHeader],
      'application/x-www-form-urlencoded',
    );
    expect(adapter.lastRequestBody, isA<String>());
    expect(adapter.lastRequestBody as String, contains('grant_type=authorization_code'));
    expect(adapter.lastRequestBody as String, contains('client_id=managed-client-id'));
    expect(adapter.lastRequestBody as String, contains('code=managed-code'));
    expect(
      adapter.lastRequestBody as String,
      contains(
        'redirect_uri=${Uri.encodeQueryComponent('https://auth.getconscia.com/open/auth/callback')}',
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
    final incomingLinks = StreamController<Uri>();
    addTearDown(incomingLinks.close);

    Uri? launchedUri;
    final dio = Dio()..httpClientAdapter = adapter;
    final service = CognitoManagedLoginService(
      dio: dio,
      incomingLinks: incomingLinks.stream,
      readInitialLink: () async => null,
      launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
        launchedUri = uri;
        Future<void>.microtask(() {
          incomingLinks.add(
            Uri.parse(
              'https://auth.getconscia.com/open/auth/callback'
              '?code=signup-code'
              '&state=${uri.queryParameters['state']}',
            ),
          );
        });
        return true;
      },
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('https://auth.getconscia.com/open/auth/callback'),
      logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
    );

    final tokens = await service.signUp(emailHint: 'story-demo@example.com');

    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');
    expect(launchedUri, isNotNull);
    expect(launchedUri!.path, '/signup');
    expect(
      launchedUri!.queryParameters['login_hint'],
      'story-demo@example.com',
    );
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
      incomingLinks: const Stream<Uri>.empty(),
      readInitialLink: () async => null,
      launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => true,
      clientId: 'managed-client-id',
      loginDomain: Uri.parse('https://login.getconscia.com'),
      redirectUri: Uri.parse('https://auth.getconscia.com/open/auth/callback'),
      logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
    );

    final tokens = await service.refreshSession('managed-refresh-token');

    expect(tokens.accessToken, 'next-access-token');
    expect(tokens.refreshToken, 'next-refresh-token');
    expect(tokens.userId, '4dfd3d03-c1da-4dd8-8a63-c973d4d1f83a');
    expect(adapter.lastRequestOptions?.path, '/oauth2/token');
    expect(adapter.lastRequestBody, isA<String>());
    expect(adapter.lastRequestBody as String, contains('grant_type=refresh_token'));
    expect(
      adapter.lastRequestBody as String,
      contains('refresh_token=managed-refresh-token'),
    );
  });
}
