import 'dart:convert';
import 'dart:typed_data';

import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _fakeJwt({
  required DateTime expiresAt,
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': 'user-1',
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      }),
    ),
  );
  return '$header.$payload.signature';
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._tokens) : super(Dio());

  final AuthTokens _tokens;
  AuthRegistrationResult? registrationResult;
  String? lastRegisteredEmail;
  String? lastConfirmedEmail;
  String? lastConfirmationCode;
  String? lastResentEmail;
  String? lastRefreshToken;
  int registerCount = 0;
  int loginCount = 0;
  bool shouldFailRefresh = false;
  Object? loginError;

  @override
  Future<AuthRegistrationResult> register(String email, String password) async {
    registerCount += 1;
    lastRegisteredEmail = email;
    return registrationResult ??
        const AuthRegistrationResult(
          success: true,
          requiresConfirmation: true,
          email: 'pending@example.com',
          userId: 'pending-user',
        );
  }

  @override
  Future<AuthConfirmationResult> confirmRegistration(
    String email,
    String confirmationCode,
  ) async {
    lastConfirmedEmail = email;
    lastConfirmationCode = confirmationCode;
    return AuthConfirmationResult(success: true, email: email);
  }

  @override
  Future<AuthConfirmationResult> resendConfirmation(String email) async {
    lastResentEmail = email;
    return AuthConfirmationResult(
      success: true,
      requiresConfirmation: true,
      email: email,
    );
  }

  @override
  Future<AuthTokens> login(String email, String password) async {
    loginCount += 1;
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return _tokens;
  }

  @override
  Future<AuthTokens> refreshSession(String refreshToken) async {
    lastRefreshToken = refreshToken;
    if (shouldFailRefresh) {
      throw DioException(
        requestOptions: RequestOptions(path: 'auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: 'auth/refresh'),
          statusCode: 401,
        ),
      );
    }
    return _tokens;
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return _values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    _values.remove(key);
  }
}

class _CapturingOkAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return ResponseBody.fromString(
      '{"accessToken":"header.payload.signature","refreshToken":"refresh-token","userId":"user-1"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Conscia',
      packageName: 'com.getconscia.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('register requiring confirmation stores pending email without tokens',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..registrationResult = const AuthRegistrationResult(
        success: true,
        requiresConfirmation: true,
        email: 'new@example.com',
        userId: 'pending-user',
      );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(service, storage);

    await notifier.register('new@example.com', 'SecureP@ss123');

    expect(notifier.state.status, AuthStatus.pendingConfirmation);
    expect(notifier.state.pendingEmail, 'new@example.com');
    expect(notifier.state.accessToken, isNull);
    expect(await storage.read(key: 'access_token'), isNull);
  });

  test(
      'confirmRegistration verifies code then logs in with pending credentials',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..registrationResult = const AuthRegistrationResult(
        success: true,
        requiresConfirmation: true,
        email: 'new@example.com',
        userId: 'pending-user',
      );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(service, storage);

    await notifier.register('new@example.com', 'SecureP@ss123');
    await notifier.confirmRegistration('123456');

    expect(service.lastConfirmedEmail, 'new@example.com');
    expect(service.lastConfirmationCode, '123456');
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.pendingEmail, isNull);
    expect(notifier.state.accessToken, 'verified.access.token');
    expect(await storage.read(key: 'access_token'), 'verified.access.token');
  });

  test('resendConfirmation uses pending email', () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..registrationResult = const AuthRegistrationResult(
        success: true,
        requiresConfirmation: true,
        email: 'new@example.com',
        userId: 'pending-user',
      );
    final notifier = AuthNotifier(service, _FakeSecureStorage());

    await notifier.register('new@example.com', 'SecureP@ss123');
    await notifier.resendConfirmation();

    expect(service.lastResentEmail, 'new@example.com');
  });

  test('login requiring confirmation stores pending email without tokens',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..loginError = const AuthConfirmationRequiredException(
        email: 'new@example.com',
      );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(service, storage);

    await notifier.login('new@example.com', 'SecureP@ss123');

    expect(notifier.state.status, AuthStatus.pendingConfirmation);
    expect(notifier.state.pendingEmail, 'new@example.com');
    expect(notifier.state.accessToken, isNull);
    expect(await storage.read(key: 'access_token'), isNull);
  });

  test('register reopens pending confirmation locally during resend cooldown',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..registrationResult = const AuthRegistrationResult(
        success: true,
        requiresConfirmation: true,
        email: 'new@example.com',
        userId: 'pending-user',
      );
    final notifier = AuthNotifier(service, _FakeSecureStorage());

    await notifier.register('new@example.com', 'SecureP@ss123');
    notifier.cancelPendingConfirmation();
    await notifier.register('new@example.com', 'SecureP@ss123');

    expect(service.registerCount, 1);
    expect(notifier.state.status, AuthStatus.pendingConfirmation);
    expect(notifier.state.pendingEmail, 'new@example.com');
  });

  test('login reopens pending confirmation locally during resend cooldown',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    )..registrationResult = const AuthRegistrationResult(
        success: true,
        requiresConfirmation: true,
        email: 'new@example.com',
        userId: 'pending-user',
      );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(service, storage);

    await notifier.register('new@example.com', 'SecureP@ss123');
    notifier.cancelPendingConfirmation();
    await notifier.login('new@example.com', 'SecureP@ss123');

    expect(service.loginCount, 0);
    expect(notifier.state.status, AuthStatus.pendingConfirmation);
    expect(notifier.state.pendingEmail, 'new@example.com');
    expect(await storage.read(key: 'access_token'), isNull);
  });

  test('refreshSession updates tokens and keeps the session authenticated',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'new.access.token',
        refreshToken: 'new-refresh-token',
        userId: 'user-1',
      ),
    );
    final storage = _FakeSecureStorage({
      'access_token': 'old.access.token',
      'refresh_token': 'old-refresh-token',
      'user_id': 'user-1',
    });
    final notifier = AuthNotifier(service, storage);

    await notifier.loginWithStoredToken();
    final refreshed = await notifier.refreshSession();

    expect(refreshed, isTrue);
    expect(service.lastRefreshToken, 'old-refresh-token');
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.accessToken, 'new.access.token');
    expect(notifier.state.refreshToken, 'new-refresh-token');
    expect(await storage.read(key: 'access_token'), 'new.access.token');
    expect(await storage.read(key: 'refresh_token'), 'new-refresh-token');
  });

  test('loginWithStoredToken refreshes an expired access token', () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'new.access.token',
        refreshToken: 'new-refresh-token',
        userId: 'user-1',
      ),
    );
    final storage = _FakeSecureStorage({
      'access_token': _fakeJwt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      ),
      'refresh_token': 'old-refresh-token',
      'user_id': 'user-1',
    });
    final notifier = AuthNotifier(service, storage);

    await notifier.loginWithStoredToken();

    expect(service.lastRefreshToken, 'old-refresh-token');
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.accessToken, 'new.access.token');
    expect(notifier.state.refreshToken, 'new-refresh-token');
  });

  test('startup restore marks session expired when expired token cannot refresh',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'new.access.token',
        refreshToken: 'new-refresh-token',
        userId: 'user-1',
      ),
    )..shouldFailRefresh = true;
    final storage = _FakeSecureStorage({
      'access_token': _fakeJwt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      ),
      'refresh_token': 'old-refresh-token',
      'user_id': 'user-1',
    });

    final notifier = AuthNotifier(service, storage);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.lastRefreshToken, 'old-refresh-token');
    expect(notifier.state.status, AuthStatus.sessionExpired);
    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
  });

  test('markSessionExpired clears tokens and exposes sessionExpired state',
      () async {
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'new.access.token',
          refreshToken: 'new-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage({
        'access_token': 'old.access.token',
        'refresh_token': 'old-refresh-token',
        'user_id': 'user-1',
      }),
    );

    await notifier.loginWithStoredToken();
    await notifier.markSessionExpired();

    expect(notifier.state.status, AuthStatus.sessionExpired);
    expect(notifier.state.accessToken, isNull);
    expect(notifier.state.refreshToken, isNull);
    expect(notifier.state.userId, isNull);
  });

  test('authDioProvider adds API version metadata to auth requests', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final adapter = _CapturingOkAdapter();
    final dio = container.read(authDioProvider)..httpClientAdapter = adapter;
    final service = AuthService(dio);

    await service.login('story-demo@example.com', 'Secure123');

    expect(adapter.lastRequestOptions?.queryParameters['v'], '1');
    expect(
      adapter.lastRequestOptions?.headers['X-Conscia-App-Version'],
      isNotNull,
    );
  });
}
