import 'dart:typed_data';

import 'package:conscia_app/core/network/dio_client.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
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

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }

  int refreshSessionCount = 0;
  int markSessionExpiredCount = 0;

  void setAuthState(AuthState nextState) {
    state = nextState;
  }

  @override
  Future<bool> refreshSession() async {
    refreshSessionCount += 1;
    return super.refreshSession();
  }

  @override
  Future<void> markSessionExpired() async {
    markSessionExpiredCount += 1;
    await super.markSessionExpired();
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount += 1;
    return ResponseBody.fromString(
      '{"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OkAdapter implements HttpClientAdapter {
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount += 1;
    return ResponseBody.fromString(
      '{"status":"Healthy","checks":[]}',
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
  test('dioProvider stays stable when auth state changes', () {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    final firstClient = container.read(dioProvider);

    authNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );

    final secondClient = container.read(dioProvider);

    expect(secondClient, same(firstClient));
  });

  test('does not mark session expired when a stale request fails after logout',
      () async {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        accessToken: 'old-token',
        refreshToken: 'old-refresh-token',
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
    );
    addTearDown(container.dispose);

    await authNotifier.logout();
    final adapter = _UnauthorizedAdapter();
    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await expectLater(
      dio.get<dynamic>('/transactions'),
      throwsA(isA<DioException>()),
    );

    expect(authNotifier.state.status, AuthStatus.unauthenticated);
    expect(authNotifier.refreshSessionCount, 0);
    expect(authNotifier.markSessionExpiredCount, 0);
    expect(adapter.fetchCount, 0);
  });

  test('allows health requests to reach the network adapter after logout',
      () async {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        accessToken: 'old-token',
        refreshToken: 'old-refresh-token',
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
    );
    addTearDown(container.dispose);

    await authNotifier.logout();
    final adapter = _OkAdapter();
    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    final response = await dio.get<dynamic>('http://localhost:5248/health');

    expect(response.statusCode, 200);
    expect(adapter.fetchCount, 1);
  });
}
