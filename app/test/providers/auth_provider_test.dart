import 'dart:convert';
import 'dart:typed_data';

import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/cognito_managed_login_service.dart';
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
  String? lastPasswordResetEmail;
  String? lastPasswordResetConfirmEmail;
  String? lastPasswordResetCode;
  String? lastPasswordResetPassword;
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
  Future<AuthConfirmationResult> startPasswordReset(String email) async {
    lastPasswordResetEmail = email;
    return AuthConfirmationResult(success: true, email: email);
  }

  @override
  Future<AuthConfirmationResult> confirmPasswordReset(
    String email,
    String confirmationCode,
    String password,
  ) async {
    lastPasswordResetConfirmEmail = email;
    lastPasswordResetCode = confirmationCode;
    lastPasswordResetPassword = password;
    return AuthConfirmationResult(success: true, email: email);
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

class _FakeManagedLoginService extends CognitoManagedLoginService {
  _FakeManagedLoginService()
      : super(
          dio: Dio(),
          openAuthSession: (uri, {required appCallbackUri}) async => Uri.parse(
            'conscia://auth/callback'
            '?code=test-code'
            '&state=test-state',
          ),
          clientId: 'managed-client-id',
          loginDomain: Uri.parse('https://login.getconscia.com'),
          redirectUri: Uri.parse('conscia://auth/callback'),
          appRedirectUri: Uri.parse('conscia://auth/callback'),
          logoutUri: Uri.parse('conscia://auth/logout'),
        );

  AuthTokens signInTokens = const AuthTokens(
    accessToken: 'managed.access.token',
    idToken: 'managed.id.token',
    refreshToken: 'managed-refresh-token',
    userId: 'user-1',
  );
  AuthTokens refreshTokens = const AuthTokens(
    accessToken: 'managed.refreshed.access.token',
    idToken: 'managed.refreshed.id.token',
    refreshToken: 'managed-refreshed-refresh-token',
    userId: 'user-1',
  );
  Object? signInError;
  final List<Object> signInErrors = <Object>[];
  Object? signUpError;
  CognitoManagedLoginProvider? lastProvider;
  String? lastEmailHint;
  String? lastRefreshToken;
  int signInCount = 0;
  int logoutCount = 0;

  @override
  Future<AuthTokens> signIn({
    CognitoManagedLoginProvider? provider,
    String? emailHint,
  }) async {
    signInCount += 1;
    if (signInErrors.isNotEmpty) {
      throw signInErrors.removeAt(0);
    }
    final error = signInError;
    if (error != null) {
      throw error;
    }
    lastProvider = provider;
    lastEmailHint = emailHint;
    return signInTokens;
  }

  @override
  Future<AuthTokens> signUp({String? emailHint}) async {
    final error = signUpError;
    if (error != null) {
      throw error;
    }
    lastEmailHint = emailHint;
    return signInTokens;
  }

  @override
  Future<AuthTokens> refreshSession(String refreshToken) async {
    lastRefreshToken = refreshToken;
    return refreshTokens;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
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

  group('managed login redirect resolution', () {
    test('uses same-origin auth bridge for web callbacks', () {
      final redirectUri = resolveManagedLoginRedirectUri(
        isWebOverride: true,
        webBaseUri: Uri.parse('http://localhost:3000/onboarding/sign-in'),
      );

      expect(redirectUri, Uri.parse('http://localhost:3000/auth.html'));
      expect(
        resolveManagedLoginAppCallbackUri(
          isWebOverride: true,
          redirectUri: redirectUri,
        ),
        redirectUri,
      );
    });

    test('keeps native app callback off web', () {
      final redirectUri = resolveManagedLoginRedirectUri(isWebOverride: false);

      expect(redirectUri, Uri.parse('conscia://auth/callback'));
      expect(
        resolveManagedLoginAppCallbackUri(
          isWebOverride: false,
          redirectUri: redirectUri,
        ),
        Uri.parse('conscia://auth/callback'),
      );
    });

    test('uses configured web callback when supplied', () {
      final redirectUri = resolveManagedLoginRedirectUri(
        isWebOverride: true,
        webRedirectUriOverride: 'https://debug.example.com/auth.html',
      );

      expect(redirectUri, Uri.parse('https://debug.example.com/auth.html'));
    });
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Conscia',
      packageName: 'com.getconscia.app.ai',
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

  test('startup with no stored session clears restoring flag', () async {
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'verified.access.token',
          refreshToken: 'verified-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage(),
    );

    expect(notifier.state.isRestoringSession, isTrue);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.isRestoringSession, isFalse);
    expect(notifier.state.status, AuthStatus.unauthenticated);
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

  test('startPasswordReset sends the reset email through auth service',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'verified.access.token',
        refreshToken: 'verified-refresh-token',
        userId: 'user-1',
      ),
    );
    final notifier = AuthNotifier(
      service,
      _FakeSecureStorage(),
      autoRestoreSession: false,
    );

    await notifier.startPasswordReset('Reset@Example.com ');

    expect(service.lastPasswordResetEmail, 'reset@example.com');
    expect(notifier.state.status, AuthStatus.unauthenticated);
    expect(notifier.state.isLoading, isFalse);
  });

  test('confirmPasswordReset confirms reset then signs in with new password',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'reset.access.token',
        refreshToken: 'reset-refresh-token',
        userId: 'user-1',
      ),
    );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(
      service,
      storage,
      autoRestoreSession: false,
    );

    await notifier.confirmPasswordReset(
      'Reset@Example.com ',
      '654321',
      'FreshPass123',
    );

    expect(service.lastPasswordResetConfirmEmail, 'reset@example.com');
    expect(service.lastPasswordResetCode, '654321');
    expect(service.lastPasswordResetPassword, 'FreshPass123');
    expect(service.loginCount, 1);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.accessToken, 'reset.access.token');
    expect(await storage.read(key: 'access_token'), 'reset.access.token');
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

  test('startup with valid stored session restores auth without sign-out state',
      () async {
    final storage = _FakeSecureStorage({
      'access_token': _fakeJwt(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      ),
      'refresh_token': 'stored-refresh-token',
      'user_id': 'user-1',
    });
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      storage,
    );

    expect(notifier.state.isRestoringSession, isTrue);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.isRestoringSession, isFalse);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.userId, 'user-1');
  });

  test(
      'startup restore marks session expired when expired token cannot refresh',
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

  test('setPassword posts the new account password', () async {
    final adapter = _CapturingOkAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = AuthService(dio);

    await service.setPassword('StrongPass123');

    expect(adapter.lastRequestOptions?.path, 'auth/password');
    expect(adapter.lastRequestOptions?.method, 'POST');
    expect(
      adapter.lastRequestOptions?.data,
      {'password': 'StrongPass123'},
    );
  });

  test('signInWithGoogle persists managed login tokens including id token',
      () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'unused.access.token',
        refreshToken: 'unused-refresh-token',
        userId: 'user-1',
      ),
    );
    final managedLogin = _FakeManagedLoginService()
      ..signInTokens = const AuthTokens(
        accessToken: 'managed.access.token',
        idToken: 'managed.id.token',
        refreshToken: 'managed-refresh-token',
        userId: 'managed-user',
      );
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(
      service,
      storage,
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.signInWithGoogle();

    expect(managedLogin.lastProvider, CognitoManagedLoginProvider.google);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.userId, 'managed-user');
    expect(notifier.state.accessToken, 'managed.access.token');
    expect(await storage.read(key: 'access_token'), 'managed.access.token');
    expect(await storage.read(key: 'id_token'), 'managed.id.token');
  });

  test('signInWithGoogle retries a transient Cognito linker failure once',
      () async {
    final managedLogin = _FakeManagedLoginService()
      ..signInErrors.add(
        const CognitoManagedLoginException(
          'PreSignUp failed with error already found an entry for username.',
        ),
      )
      ..signInTokens = const AuthTokens(
        accessToken: 'managed.access.token',
        idToken: 'managed.id.token',
        refreshToken: 'managed-refresh-token',
        userId: 'managed-user',
      );
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage(),
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.signInWithGoogle();

    expect(managedLogin.signInCount, 2);
    expect(managedLogin.lastProvider, CognitoManagedLoginProvider.google);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.userId, 'managed-user');
  });

  test('signInWithGoogle clears stale local onboarding completion', () async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
    });
    final managedLogin = _FakeManagedLoginService()
      ..signInTokens = const AuthTokens(
        accessToken: 'managed.access.token',
        idToken: 'managed.id.token',
        refreshToken: 'managed-refresh-token',
        userId: 'managed-user',
      );
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage(),
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.signInWithGoogle();

    expect(await hasCompletedOnboarding(), isFalse);
    expect(notifier.state.status, AuthStatus.authenticated);
  });

  test('logout clears local managed session without opening Cognito logout',
      () async {
    final managedLogin = _FakeManagedLoginService();
    final storage = _FakeSecureStorage();
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      storage,
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.signInWithGoogle();
    await notifier.logout();

    expect(managedLogin.logoutCount, 0);
    expect(notifier.state.status, AuthStatus.unauthenticated);
    expect(notifier.state.wasExplicitLogout, isTrue);
    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'id_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
    expect(await storage.read(key: 'user_id'), isNull);
  });

  test('refreshSession uses managed login token refresh and stores id token',
      () async {
    final storage = _FakeSecureStorage({
      'access_token': _fakeJwt(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      ),
      'id_token': _fakeJwt(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      ),
      'refresh_token': 'managed-refresh-token',
      'user_id': 'user-1',
    });
    final managedLogin = _FakeManagedLoginService()
      ..refreshTokens = const AuthTokens(
        accessToken: 'managed.refreshed.access.token',
        idToken: 'managed.refreshed.id.token',
        refreshToken: 'managed.refreshed.refresh.token',
        userId: 'managed-user',
      );
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      storage,
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.loginWithStoredToken();
    final refreshed = await notifier.refreshSession();

    expect(refreshed, isTrue);
    expect(managedLogin.lastRefreshToken, 'managed-refresh-token');
    expect(await storage.read(key: 'access_token'),
        'managed.refreshed.access.token');
    expect(await storage.read(key: 'id_token'), 'managed.refreshed.id.token');
    expect(await storage.read(key: 'refresh_token'),
        'managed.refreshed.refresh.token');
  });

  test('continueWithManagedLogin ignores auth-sheet cancellation quietly',
      () async {
    final managedLogin = _FakeManagedLoginService()
      ..signInError = const CognitoManagedLoginCancelledException();
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage(),
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.continueWithManagedLogin(emailHint: 'calm@example.com');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNull);
    expect(notifier.state.status, AuthStatus.unauthenticated);
  });

  test('signUpWithManagedLogin ignores auth-sheet cancellation quietly',
      () async {
    final managedLogin = _FakeManagedLoginService()
      ..signUpError = const CognitoManagedLoginCancelledException();
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'unused.access.token',
          refreshToken: 'unused-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage(),
      autoRestoreSession: false,
      managedLoginService: managedLogin,
      useManagedLogin: true,
    );

    await notifier.signUpWithManagedLogin(emailHint: 'calm@example.com');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNull);
    expect(notifier.state.status, AuthStatus.unauthenticated);
  });
}
