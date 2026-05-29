import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/security_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAuthService extends AuthService {
  _RecordingAuthService() : super(Dio());

  String? lastPassword;

  @override
  Future<void> setPassword(String password) async {
    lastPassword = password;
  }
}

class _RecordingPasskeyService extends PasskeyService {
  _RecordingPasskeyService()
      : super(
          publicDio: Dio(),
          authenticatedDio: Dio(),
        );

  int registerCount = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> registerCurrentUserPasskey() async {
    registerCount += 1;
  }
}

Future<void> _pumpSecurityScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  AuthService? authService,
  PasskeyService? passkeyService,
}) async {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'security@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(authService ?? AuthService(Dio())),
      passkeyAvailabilityProvider.overrideWith((ref) async => true),
      currentSessionSupportsPasskeysProvider.overrideWith((ref) => true),
      passkeyServiceProvider.overrideWithValue(
        passkeyService ?? _RecordingPasskeyService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SecurityScreen()),
    ),
  );
}

void main() {
  testWidgets('security screen opens a password sheet before saving', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _RecordingAuthService();

    await _pumpSecurityScreen(tester, prefs: prefs, authService: auth);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Change Password'), findsOneWidget);

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Change password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).at(0), 'StrongPass123');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(auth.lastPassword, 'StrongPass123');
    expect(
      find.text('Password updated. You can now sign in with email.'),
      findsOneWidget,
    );
  });

  testWidgets('security screen registers passkeys and enables passkey first',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final passkeys = _RecordingPasskeyService();

    await _pumpSecurityScreen(tester, prefs: prefs, passkeyService: passkeys);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Up Passkey'));
    await tester.pumpAndSettle();

    expect(passkeys.registerCount, 1);
    expect(
      prefs.getStringList(passkeyRegisteredEmailsPreferenceKey),
      ['security@example.com'],
    );
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isTrue);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();

    expect(find.text('Passkey First Sign-In'), findsOneWidget);
  });
}
