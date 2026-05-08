import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/api_constants.dart';
import '../core/routing/app_router.dart';
import '../services/auth_service.dart';

enum AuthStatus { unauthenticated, authenticated, sessionExpired }

const _unset = Object();

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.accessToken,
    this.refreshToken,
    this.userId,
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
      userId: identical(userId, _unset)
          ? this.userId
          : userId as String?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

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
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await _authService.register(email, password);
      await _persistTokens(tokens);
      saveLastEmail(email);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (ApiConstants.useMockAuth) {
        final tokens = await _authService.login('google_user@gmail.com', 'mock');
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (ApiConstants.useMockAuth) {
        final tokens = await _authService.login('apple_user@privaterelay.appleid.com', 'mock');
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    state = const AuthState();
  }

  Future<bool> refreshSession() async {
    final refreshToken = state.refreshToken ?? await _storage.read(key: _refreshTokenKey);
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
