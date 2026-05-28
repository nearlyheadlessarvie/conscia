import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';

enum CognitoManagedLoginProvider {
  google('Google'),
  apple('SignInWithApple');

  const CognitoManagedLoginProvider(this.queryValue);

  final String queryValue;
}

typedef LaunchExternalUrl = Future<bool> Function(
  Uri uri, {
  LaunchMode mode,
});

class CognitoManagedLoginCancelledException implements Exception {
  const CognitoManagedLoginCancelledException();
}

class CognitoManagedLoginException implements Exception {
  const CognitoManagedLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CognitoManagedLoginService {
  static final _customSchemeCallbackUri = Uri.parse('conscia://auth/callback');

  CognitoManagedLoginService({
    required Dio dio,
    required Stream<Uri> incomingLinks,
    required Future<Uri?> Function() readInitialLink,
    required LaunchExternalUrl launchUrl,
    required String clientId,
    required Uri loginDomain,
    required Uri redirectUri,
    required Uri logoutUri,
    this.scopes = _defaultScopes,
    math.Random? random,
  })  : _dio = dio,
        _incomingLinks = incomingLinks,
        _readInitialLink = readInitialLink,
        _launchUrl = launchUrl,
        _clientId = clientId,
        _loginDomain = _normalizeBaseUri(loginDomain),
        _redirectUri = redirectUri,
        _logoutUri = logoutUri,
        _random = random ?? math.Random.secure() {
    _dio.options.baseUrl = _loginDomain.toString();
  }

  static const _defaultScopes =
      'openid email profile aws.cognito.signin.user.admin';

  final Dio _dio;
  final Stream<Uri> _incomingLinks;
  final Future<Uri?> Function() _readInitialLink;
  final LaunchExternalUrl _launchUrl;
  final String _clientId;
  final Uri _loginDomain;
  final Uri _redirectUri;
  final Uri _logoutUri;
  final String scopes;
  final math.Random _random;

  Future<AuthTokens> signIn({
    CognitoManagedLoginProvider? provider,
    String? emailHint,
  }) {
    return _authenticate(
      endpointPath: '/oauth2/authorize',
      provider: provider,
      emailHint: emailHint,
    );
  }

  Future<AuthTokens> signUp({String? emailHint}) {
    return _authenticate(
      endpointPath: '/signup',
      emailHint: emailHint,
    );
  }

  Future<AuthTokens> refreshSession(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth2/token',
      data: _encodeFormBody({
        'grant_type': 'refresh_token',
        'client_id': _clientId,
        'refresh_token': refreshToken,
      }),
      options: Options(
        headers: {
          Headers.contentTypeHeader: 'application/x-www-form-urlencoded',
        },
      ),
    );

    return _tokensFromOAuthJson(response.data ?? const <String, dynamic>{});
  }

  Future<void> logout() async {
    final launched = await _launchUrl(
      _loginDomain.replace(
        path: '/logout',
        queryParameters: {
          'client_id': _clientId,
          'logout_uri': _logoutUri.toString(),
        },
      ),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const CognitoManagedLoginException(
        'Could not open Conscia sign-out in the browser.',
      );
    }
  }

  Future<AuthTokens> _authenticate({
    required String endpointPath,
    CognitoManagedLoginProvider? provider,
    String? emailHint,
  }) async {
    final codeVerifier = _randomUrlSafeString(length: 64);
    final state = _randomUrlSafeString(length: 32);
    final authorizeUri = _loginDomain.replace(
      path: endpointPath,
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri.toString(),
        'response_type': 'code',
        'scope': scopes,
        'state': state,
        'code_challenge_method': 'S256',
        'code_challenge': _codeChallengeFor(codeVerifier),
        if (provider != null) 'identity_provider': provider.queryValue,
        if (emailHint != null && emailHint.trim().isNotEmpty)
          'login_hint': emailHint.trim(),
      },
    );

    final launched = await _launchUrl(
      authorizeUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const CognitoManagedLoginException(
        'Could not open Conscia sign-in in the browser.',
      );
    }

    final callbackUri = await _waitForCallback(state);
    final error = callbackUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      if (error == 'access_denied') {
        throw const CognitoManagedLoginCancelledException();
      }

      final description = callbackUri.queryParameters['error_description'];
      throw CognitoManagedLoginException(
        description?.trim().isNotEmpty == true
            ? description!
            : 'Conscia sign-in could not finish right now.',
      );
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const CognitoManagedLoginException(
        'Conscia sign-in did not return an authorization code.',
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth2/token',
      data: _encodeFormBody({
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'code': code,
        'redirect_uri': _redirectUri.toString(),
        'code_verifier': codeVerifier,
      }),
      options: Options(
        headers: {
          Headers.contentTypeHeader: 'application/x-www-form-urlencoded',
        },
      ),
    );

    return _tokensFromOAuthJson(response.data ?? const <String, dynamic>{});
  }

  Future<Uri> _waitForCallback(String expectedState) async {
    final initialLink = await _readInitialLink();
    if (_matchesCallback(initialLink, expectedState)) {
      return initialLink!;
    }

    return _incomingLinks.firstWhere(
      (uri) => _matchesCallback(uri, expectedState),
    ).timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw const CognitoManagedLoginException(
        'Conscia sign-in timed out before the browser returned to the app.',
      ),
    );
  }

  bool _matchesCallback(Uri? uri, String expectedState) {
    if (uri == null) {
      return false;
    }

    final matchesRedirectUri =
        uri.scheme == _redirectUri.scheme &&
        uri.host == _redirectUri.host &&
        uri.path == _redirectUri.path;
    final matchesCustomSchemeCallback =
        uri.scheme == _customSchemeCallbackUri.scheme &&
        uri.host == _customSchemeCallbackUri.host &&
        uri.path == _customSchemeCallbackUri.path;

    if (!matchesRedirectUri && !matchesCustomSchemeCallback) {
      return false;
    }

    return uri.queryParameters['state'] == expectedState;
  }

  AuthTokens _tokensFromOAuthJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'] as String?;
    final idToken = json['id_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const CognitoManagedLoginException(
        'Conscia sign-in did not return an access token.',
      );
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const CognitoManagedLoginException(
        'Conscia sign-in did not return a refresh token.',
      );
    }

    final userId = _readSubject(idToken) ?? _readSubject(accessToken);
    if (userId == null || userId.isEmpty) {
      throw const CognitoManagedLoginException(
        'Conscia sign-in returned tokens without a usable subject.',
      );
    }

    return AuthTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  String? _readSubject(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      final sub = payload['sub'];
      return sub is String && sub.isNotEmpty ? sub : null;
    } catch (_) {
      return null;
    }
  }

  String _codeChallengeFor(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier)).bytes;
    return base64Url.encode(digest).replaceAll('=', '');
  }

  String _randomUrlSafeString({required int length}) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  static String _encodeFormBody(Map<String, String> fields) {
    return fields.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  static Uri _normalizeBaseUri(Uri uri) {
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return uri.replace(path: path, query: null, fragment: null);
  }
}
