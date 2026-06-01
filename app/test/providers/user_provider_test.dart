import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/sign_in_preference_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  test('currentUserProvider refreshes when authenticated user changes',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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
        sharedPreferencesProvider.overrideWithValue(prefs),
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

  test('currentSessionUserProvider hides stale profile while switching users',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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
        hasCompletedOnboarding: true,
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
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    fakeUserService.activeUserId = 'user-1';
    await container.read(currentUserProvider.future);
    expect(container.read(currentSessionUserProvider), isNotNull);

    fakeUserService.activeUserId = 'user-2';
    fakeAuthNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );

    expect(container.read(currentSessionUserProvider), isNull);
  });

  test('currentUserProvider remembers profile display name over email fallback',
      () async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'story-demo@example.com',
    });
    final prefs = await SharedPreferences.getInstance();
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final fakeUserService = _FakeUserService({
      'user-1': UserProfile(
        id: 'user-1',
        email: 'story-demo@example.com',
        displayName: 'Story Demo',
        currencyCode: 'USD',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
      ),
    })
      ..activeUserId = 'user-1';

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => fakeAuthNotifier),
        userServiceProvider.overrideWithValue(fakeUserService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentUserProvider.future);

    expect(
      prefs.getString(rememberedSignInDisplayNamePreferenceKey),
      'Story Demo',
    );
  });

  test('currentUserProvider keeps claimed display name when profile loads',
      () async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Claimed Name',
    });
    final prefs = await SharedPreferences.getInstance();
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final fakeUserService = _FakeUserService({
      'user-1': UserProfile(
        id: 'user-1',
        email: 'story-demo@example.com',
        displayName: 'Profile Name',
        currencyCode: 'USD',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
      ),
    })
      ..activeUserId = 'user-1';

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => fakeAuthNotifier),
        userServiceProvider.overrideWithValue(fakeUserService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentUserProvider.future);

    expect(
      prefs.getString(rememberedSignInDisplayNamePreferenceKey),
      'Claimed Name',
    );
  });
}
