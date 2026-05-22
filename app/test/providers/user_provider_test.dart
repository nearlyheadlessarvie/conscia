import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  final Map<String, String> _values = {};

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
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
    state = initialState;
  }

  void setAuthState(AuthState nextState) {
    state = nextState;
  }
}

class _FakeUserService extends UserService {
  _FakeUserService(this._profilesByUserId) : super(Dio());

  final Map<String, UserProfile> _profilesByUserId;
  final List<String> requestedUserIds = [];
  String? activeUserId;

  @override
  Future<UserProfile> getProfile() async {
    final userId = activeUserId;
    if (userId == null) {
      throw StateError('No active user id set');
    }

    requestedUserIds.add(userId);
    return _profilesByUserId[userId]!;
  }
}

void main() {
  test('currentUserProvider refreshes when authenticated user changes', () async {
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final fakeUserService = _FakeUserService({
      'user-1': UserProfile(
        id: 'user-1',
        email: 'first@example.com',
        currencyCode: 'USD',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: false,
      ),
      'user-2': UserProfile(
        id: 'user-2',
        email: 'second@example.com',
        currencyCode: 'PHP',
        locale: 'en_PH',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
      ),
    });

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => fakeAuthNotifier),
        userServiceProvider.overrideWithValue(fakeUserService),
      ],
    );
    addTearDown(container.dispose);

    fakeUserService.activeUserId = 'user-1';
    final first = await container.read(currentUserProvider.future);
    expect(first.id, 'user-1');

    fakeUserService.activeUserId = 'user-2';
    fakeAuthNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );

    final second = await container.read(currentUserProvider.future);
    expect(second.id, 'user-2');
    expect(fakeUserService.requestedUserIds, ['user-1', 'user-2']);
  });
}
