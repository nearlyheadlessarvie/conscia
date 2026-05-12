import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/app_error.dart';
import '../core/routing/app_router.dart';
import '../services/auth_service.dart';

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
  final String? refreshToken;
  final String? userId;
  final String? pendingEmail;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.pendingEmail,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isSessionExpired => status == AuthStatus.sessionExpired;

  AuthState copyWith({
    AuthStatus? status,
    Object? accessToken = _unset,
    Object? refreshToken = _unset,
    Object? userId = _unset,
    Object? pendingEmail = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: identical(accessToken, _unset)
          ? this.accessToken
          : accessToken as String?,
      refreshToken: identical(refreshToken, _unset)
          ? this.refreshToken
          : refreshToken as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      pendingEmail: identical(pendingEmail, _unset)
          ? this.pendingEmail
          : pendingEmail as String?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;
  String? _pendingPassword;

  static const confirmationResendCooldown = Duration(minutes: 1);
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _pendingConfirmationEmailKey = 'pending_confirmation_email';
  static const _confirmationCooldownKeyPrefix =
      'confirmation_resend_allowed_at_ms';

  AuthNotifier(this._authService, this._storage) : super(const AuthState()) {
    _loadStoredTokens();
  }

  Future<void> _loadStoredTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userId = await _storage.read(key: _userIdKey);

    if (accessToken == null || refreshToken == null || userId == null) return;

    // Reject tokens that aren't valid JWTs (e.g. stale mock_access_token_*)
    final parts = accessToken.split('.');
    if (parts.length != 3) {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      return;
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<void> loginWithStoredToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userId = await _storage.read(key: _userIdKey);

    if (accessToken == null || refreshToken == null || userId == null) {
      throw Exception('No stored session');
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<void> login(String email, String password) async {
    if (await _resumePendingConfirmationIfCoolingDown(email, password)) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await _authService.login(email, password);
      await _persistTokens(tokens);
      saveLastEmail(email);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        pendingEmail: null,
        isLoading: false,
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

    state = state.copyWith(isLoading: true, error: null);
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

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.confirmRegistration(email, confirmationCode);

      if (password == null) {
        await _clearPendingConfirmation();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingEmail: null,
          userId: null,
          isLoading: false,
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

    state = state.copyWith(isLoading: true, error: null);
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (ApiConstants.useMockAuth) {
        final tokens =
            await _authService.login('google_user@gmail.com', 'mock');
        await _persistTokens(tokens);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userId: tokens.userId,
          isLoading: false,
        );
        return;
      }
      final tokens = await _authService.signInWithGoogle();
      await _persistTokens(tokens);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        isLoading: false,
      );
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (ApiConstants.useMockAuth) {
        final tokens = await _authService.login(
            'apple_user@privaterelay.appleid.com', 'mock');
        await _persistTokens(tokens);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userId: tokens.userId,
          isLoading: false,
        );
        return;
      }
      final tokens = await _authService.signInWithApple();
      await _persistTokens(tokens);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        isLoading: false,
      );
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: error.userMessage);
      throw error;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    _pendingPassword = null;
    state = const AuthState();
  }

  Future<bool> refreshSession() async {
    final refreshToken =
        state.refreshToken ?? await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await markSessionExpired();
      return false;
    }

    try {
      final tokens = await _authService.refreshSession(refreshToken);
      await _persistTokens(tokens);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        pendingEmail: null,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (_) {
      await markSessionExpired();
      return false;
    }
  }

  Future<void> markSessionExpired() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    _pendingPassword = null;
    state = const AuthState(
      status: AuthStatus.sessionExpired,
      error: 'Session expired',
    );
  }

  Future<void> _persistTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _userIdKey, value: tokens.userId);
  }

  Future<void> _setAuthenticated(AuthTokens tokens) async {
    await _persistTokens(tokens);
    await _clearPendingConfirmation();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.userId,
      pendingEmail: null,
      isLoading: false,
      error: null,
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
      refreshToken: null,
      userId: null,
      isLoading: false,
      error: null,
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
      refreshToken: null,
      userId: userId,
      isLoading: false,
      error: null,
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
  return Dio(
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
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authDioProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
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
