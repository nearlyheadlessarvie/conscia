import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/app_error.dart';
import '../core/routing/app_router.dart';
import '../services/auth_service.dart';
import '../services/cognito_managed_login_service.dart';

enum AuthStatus {
  unauthenticated,
  pendingConfirmation,
  authenticated,
  sessionExpired,
}

const _unset = Object();

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final String? userId;
  final String? pendingEmail;
  final bool isLoading;
  final bool isRestoringSession;
  final String? error;
  final bool wasExplicitLogout;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.accessToken,
    this.idToken,
    this.refreshToken,
    this.userId,
    this.pendingEmail,
    this.isLoading = false,
    this.isRestoringSession = false,
    this.error,
    this.wasExplicitLogout = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isSessionExpired => status == AuthStatus.sessionExpired;

  AuthState copyWith({
    AuthStatus? status,
    Object? accessToken = _unset,
    Object? idToken = _unset,
    Object? refreshToken = _unset,
    Object? userId = _unset,
    Object? pendingEmail = _unset,
    bool? isLoading,
    bool? isRestoringSession,
    Object? error = _unset,
    bool? wasExplicitLogout,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: identical(accessToken, _unset)
          ? this.accessToken
          : accessToken as String?,
      idToken: identical(idToken, _unset) ? this.idToken : idToken as String?,
      refreshToken: identical(refreshToken, _unset)
          ? this.refreshToken
          : refreshToken as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      pendingEmail: identical(pendingEmail, _unset)
          ? this.pendingEmail
          : pendingEmail as String?,
      isLoading: isLoading ?? this.isLoading,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      error: identical(error, _unset) ? this.error : error as String?,
      wasExplicitLogout: wasExplicitLogout ?? this.wasExplicitLogout,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final CognitoManagedLoginService _managedLoginService;
  final FlutterSecureStorage _storage;
  final bool _useManagedLogin;
  String? _pendingPassword;

  static const confirmationResendCooldown = Duration(minutes: 1);
  static const _accessTokenKey = 'access_token';
  static const _idTokenKey = 'id_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _pendingConfirmationEmailKey = 'pending_confirmation_email';
  static const _confirmationCooldownKeyPrefix =
      'confirmation_resend_allowed_at_ms';

  AuthNotifier(
    this._authService,
    this._storage, {
    CognitoManagedLoginService? managedLoginService,
    bool? useManagedLogin,
    bool autoRestoreSession = true,
  })  : _managedLoginService =
            managedLoginService ?? _UnavailableManagedLoginService.instance,
        _useManagedLogin = useManagedLogin ?? !ApiConstants.useMockAuth,
        super(
          AuthState(isRestoringSession: autoRestoreSession),
        ) {
    if (autoRestoreSession) {
      _loadStoredTokens();
    }
  }

  Future<void> _loadStoredTokens() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final idToken = await _storage.read(key: _idTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final userId = await _storage.read(key: _userIdKey);

      await _restoreStoredSession(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken,
        userId: userId,
      );
      if (state.isRestoringSession) {
        state = state.copyWith(isRestoringSession: false);
      }
    } catch (_) {
      // Tests and rare platform startup races can make secure storage
      // unavailable. Stay signed out instead of surfacing an async crash.
      state = state.copyWith(isRestoringSession: false);
      return;
    }
  }

  Future<void> loginWithStoredToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final idToken = await _storage.read(key: _idTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userId = await _storage.read(key: _userIdKey);

    if (accessToken == null || refreshToken == null || userId == null) {
      throw Exception('No stored session');
    }

    final restored = await _restoreStoredSession(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      userId: userId,
      throwIfMissing: true,
    );

    if (!restored) {
      throw Exception('No stored session');
    }
  }

  Future<void> login(String email, String password) async {
    if (await _resumePendingConfirmationIfCoolingDown(email, password)) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      final tokens = await _authService.login(email, password);
      await _persistTokens(tokens);
      saveLastEmail(email);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        pendingEmail: null,
        isLoading: false,
        isRestoringSession: false,
        wasExplicitLogout: false,
      );
    } on AuthConfirmationRequiredException catch (e) {
      saveLastEmail(email);
      await _rememberPendingConfirmation(e.email, password: password);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> register(String email, String password) async {
    if (await _resumePendingConfirmationIfCoolingDown(email, password)) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      final result = await _authService.register(email, password);
      saveLastEmail(email);

      if (result.requiresConfirmation) {
        await _rememberPendingConfirmation(
          result.email ?? email,
          password: password,
          userId: result.userId,
        );
        return;
      }

      final tokens = await _authService.login(email, password);
      await _setAuthenticated(tokens);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> confirmRegistration(String confirmationCode) async {
    final email = state.pendingEmail;
    final password = _pendingPassword;
    if (email == null || email.isEmpty) {
      throw Exception('No pending email confirmation');
    }

    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      await _authService.confirmRegistration(email, confirmationCode);

      if (password == null) {
        await _clearPendingConfirmation();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingEmail: null,
          idToken: null,
          userId: null,
          isLoading: false,
          wasExplicitLogout: false,
        );
        return;
      }

      final tokens = await _authService.login(email, password);
      _pendingPassword = null;
      await _setAuthenticated(tokens);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> resendConfirmation() async {
    final email = state.pendingEmail;
    if (email == null || email.isEmpty) {
      throw Exception('No pending email confirmation');
    }

    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      await _authService.resendConfirmation(email);
      await _startConfirmationCooldown(email);
      state = state.copyWith(isLoading: false);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  void cancelPendingConfirmation() {
    _pendingPassword = null;
    state = const AuthState();
  }

  Future<Duration> confirmationResendCooldownRemaining([String? email]) async {
    final normalizedEmail = _normalizeEmail(
      email ?? state.pendingEmail ?? await _storedPendingConfirmationEmail(),
    );
    if (normalizedEmail == null) return Duration.zero;

    final prefs = await SharedPreferences.getInstance();
    final allowedAtMs =
        prefs.getInt(_confirmationCooldownKey(normalizedEmail)) ?? 0;
    final remainingMs = allowedAtMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return Duration.zero;

    return Duration(milliseconds: remainingMs);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      if (!_useManagedLogin) {
        final tokens =
            await _authService.login('google_user@gmail.com', 'mock');
        await _setAuthenticated(tokens);
        return;
      }
      final tokens = await _managedLoginService.signIn(
        provider: CognitoManagedLoginProvider.google,
      );
      await _setAuthenticated(tokens);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      if (!_useManagedLogin) {
        final tokens = await _authService.login(
            'apple_user@privaterelay.appleid.com', 'mock');
        await _setAuthenticated(tokens);
        return;
      }
      final tokens = await _managedLoginService.signIn(
        provider: CognitoManagedLoginProvider.apple,
      );
      await _setAuthenticated(tokens);
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> completeExternalSignIn(
    AuthTokens tokens, {
    String? email,
  }) async {
    if (email != null && email.trim().isNotEmpty) {
      saveLastEmail(email.trim());
    }
    await _setAuthenticated(tokens);
  }

  Future<void> continueWithManagedLogin({String? emailHint}) async {
    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      final tokens = await _managedLoginService.signIn(emailHint: emailHint);
      if (emailHint != null && emailHint.trim().isNotEmpty) {
        saveLastEmail(emailHint.trim());
      }
      await _setAuthenticated(tokens);
    } on CognitoManagedLoginCancelledException {
      state = state.copyWith(
        isLoading: false,
        isRestoringSession: false,
        error: null,
      );
      return;
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> signUpWithManagedLogin({String? emailHint}) async {
    state = state.copyWith(
      isLoading: true,
      isRestoringSession: false,
      error: null,
    );
    try {
      final tokens = await _managedLoginService.signUp(emailHint: emailHint);
      if (emailHint != null && emailHint.trim().isNotEmpty) {
        saveLastEmail(emailHint.trim());
      }
      await _setAuthenticated(tokens);
    } on CognitoManagedLoginCancelledException {
      state = state.copyWith(
        isLoading: false,
        isRestoringSession: false,
        error: null,
      );
      return;
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> logout() async {
    _pendingPassword = null;
    state = const AuthState(
      wasExplicitLogout: true,
      isRestoringSession: false,
    );
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    if (_useManagedLogin) {
      try {
        await _managedLoginService.logout();
      } catch (_) {
        // Local sign-out already succeeded; don't trap the user on a browser failure.
      }
    }
  }

  Future<bool> refreshSession() async {
    final refreshToken =
        state.refreshToken ?? await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await markSessionExpired();
      return false;
    }

    try {
      final tokens = !_useManagedLogin
          ? await _authService.refreshSession(refreshToken)
          : await _managedLoginService.refreshSession(refreshToken);
      await _persistTokens(tokens);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        pendingEmail: null,
        isLoading: false,
        isRestoringSession: false,
        error: null,
      );
      return true;
    } catch (_) {
      await markSessionExpired();
      return false;
    }
  }

  Future<void> markSessionExpired() async {
    _pendingPassword = null;
    state = const AuthState(
      status: AuthStatus.sessionExpired,
      isRestoringSession: false,
      error: 'Session expired',
      wasExplicitLogout: false,
    );
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<bool> _restoreStoredSession({
    required String? accessToken,
    required String? idToken,
    required String? refreshToken,
    required String? userId,
    bool throwIfMissing = false,
  }) async {
    if (accessToken == null || refreshToken == null || userId == null) {
      if (throwIfMissing) {
        throw Exception('No stored session');
      }
      return false;
    }

    if (!_looksLikeJwt(accessToken)) {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _idTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      if (throwIfMissing) {
        throw Exception('No stored session');
      }
      return false;
    }

    final isExpired = _isJwtExpired(accessToken);
    if (isExpired) {
      try {
        final tokens = !_useManagedLogin
            ? await _authService.refreshSession(refreshToken)
            : await _managedLoginService.refreshSession(refreshToken);
        await _persistTokens(tokens);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          accessToken: tokens.accessToken,
          idToken: tokens.idToken,
          refreshToken: tokens.refreshToken,
          userId: tokens.userId,
          pendingEmail: null,
          isLoading: false,
          isRestoringSession: false,
          error: null,
          wasExplicitLogout: false,
        );
        return true;
      } catch (_) {
        await markSessionExpired();
        return false;
      }
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      userId: userId,
      isRestoringSession: false,
      error: null,
      wasExplicitLogout: false,
    );
    return true;
  }

  static bool _looksLikeJwt(String token) => token.split('.').length == 3;

  static bool _isJwtExpired(String token) {
    final payload = _tryDecodeJwtPayload(token);
    final exp = payload?['exp'];
    if (exp is! num) {
      return false;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );

    return !expiresAt.isAfter(
      DateTime.now().toUtc().add(const Duration(seconds: 30)),
    );
  }

  static Map<String, dynamic>? _tryDecodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    if (tokens.idToken == null || tokens.idToken!.isEmpty) {
      await _storage.delete(key: _idTokenKey);
    } else {
      await _storage.write(key: _idTokenKey, value: tokens.idToken);
    }
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _userIdKey, value: tokens.userId);
  }

  Future<void> _setAuthenticated(AuthTokens tokens) async {
    await _persistTokens(tokens);
    await _clearPendingConfirmation();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.userId,
      pendingEmail: null,
      isLoading: false,
      isRestoringSession: false,
      error: null,
      wasExplicitLogout: false,
    );
  }

  Future<bool> _resumePendingConfirmationIfCoolingDown(
    String email,
    String password,
  ) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return false;

    final remaining =
        await confirmationResendCooldownRemaining(normalizedEmail);
    if (remaining <= Duration.zero) return false;

    _pendingPassword = password;
    saveLastEmail(normalizedEmail);
    state = state.copyWith(
      status: AuthStatus.pendingConfirmation,
      pendingEmail: normalizedEmail,
      accessToken: null,
      idToken: null,
      refreshToken: null,
      userId: null,
      isLoading: false,
      isRestoringSession: false,
      error: null,
      wasExplicitLogout: false,
    );
    return true;
  }

  Future<void> _rememberPendingConfirmation(
    String email, {
    String? password,
    String? userId,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;

    _pendingPassword = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingConfirmationEmailKey, normalizedEmail);
    await _startConfirmationCooldown(normalizedEmail);

    state = state.copyWith(
      status: AuthStatus.pendingConfirmation,
      pendingEmail: normalizedEmail,
      accessToken: null,
      idToken: null,
      refreshToken: null,
      userId: userId,
      isLoading: false,
      isRestoringSession: false,
      error: null,
      wasExplicitLogout: false,
    );
  }

  Future<void> _startConfirmationCooldown(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _confirmationCooldownKey(normalizedEmail),
      DateTime.now().add(confirmationResendCooldown).millisecondsSinceEpoch,
    );
  }

  Future<String?> _storedPendingConfirmationEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingConfirmationEmailKey);
  }

  Future<void> _clearPendingConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingConfirmationEmailKey);
  }

  static String _confirmationCooldownKey(String email) =>
      '$_confirmationCooldownKeyPrefix:$email';

  static String? _normalizeEmail(String? email) {
    final trimmed = email?.trim().toLowerCase();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.queryParameters = <String, dynamic>{
          ...options.queryParameters,
          'v': options.queryParameters['v'] ?? '1',
        };

        final info = await PackageInfo.fromPlatform();
        options.headers['X-Conscia-App-Version'] =
            '${info.version}+${info.buildNumber}';

        handler.next(options);
      },
    ),
  );

  return dio;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authDioProvider));
});

final managedLoginServiceProvider = Provider<CognitoManagedLoginService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  return CognitoManagedLoginService(
    dio: dio,
    launchUrl: launchUrl,
    openAuthSession: openManagedLoginAuthSheet,
    clientId: ApiConstants.cognitoClientId,
    loginDomain: Uri.parse(ApiConstants.cognitoLoginDomain),
    redirectUri: Uri.parse(ApiConstants.cognitoRedirectUri),
    appRedirectUri: Uri.parse(ApiConstants.cognitoAppRedirectUri),
    logoutUri: Uri.parse(ApiConstants.cognitoLogoutUri),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
    managedLoginService: ref.watch(managedLoginServiceProvider),
  );
});

final authCacheScopeProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  return [
    auth.status.name,
    auth.userId ?? '',
    auth.pendingEmail ?? '',
  ].join(':');
});

final class _UnavailableManagedLoginService extends CognitoManagedLoginService {
  _UnavailableManagedLoginService._()
      : super(
          dio: Dio(),
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => false,
          openAuthSession: (uri, {required appCallbackUri}) async =>
              throw const CognitoManagedLoginException(
                'Managed login is not configured for this session.',
              ),
          clientId: '',
          loginDomain: Uri.parse('https://login.getconscia.com'),
          redirectUri:
              Uri.parse('https://auth.getconscia.com/open/auth/callback'),
          appRedirectUri: Uri.parse(ApiConstants.cognitoAppRedirectUri),
          logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
        );

  static final instance = _UnavailableManagedLoginService._();

  @override
  Future<AuthTokens> signIn({
    CognitoManagedLoginProvider? provider,
    String? emailHint,
  }) {
    throw const CognitoManagedLoginException(
      'Managed login is not configured for this session.',
    );
  }

  @override
  Future<AuthTokens> signUp({String? emailHint}) {
    throw const CognitoManagedLoginException(
      'Managed login is not configured for this session.',
    );
  }

  @override
  Future<AuthTokens> refreshSession(String refreshToken) {
    throw const CognitoManagedLoginException(
      'Managed login is not configured for this session.',
    );
  }

  @override
  Future<void> logout() async {}
}
