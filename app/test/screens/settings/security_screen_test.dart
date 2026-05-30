import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/security_screen.dart';
import 'package:conscia_app/services/account_password_service.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAccountPasswordService extends AccountPasswordService {
  _RecordingAccountPasswordService() : super(Dio());

  String? lastPassword;
  String? lastCurrentPassword;
  Object? setPasswordError;

  @override
  Future<void> setPassword(String password, {String? currentPassword}) async {
    final error = setPasswordError;
    if (error != null) {
      throw error;
    }
    lastPassword = password;
    lastCurrentPassword = currentPassword;
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
  AccountPasswordService? accountPasswordService,
  PasskeyService? passkeyService,
  bool hasPassword = false,
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
          hasPassword: hasPassword,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountPasswordServiceProvider.overrideWithValue(
        accountPasswordService ?? _RecordingAccountPasswordService(),
      ),
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
  tearDown(AppError.resetForTests);

  testWidgets('security screen adds a password without current password', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _RecordingAccountPasswordService();

    await _pumpSecurityScreen(
      tester,
      prefs: prefs,
      accountPasswordService: auth,
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Add Password'), findsOneWidget);

    await tester.tap(find.text('Add Password'));
    await tester.pumpAndSettle();

    expect(find.text('Add password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).at(0), 'StrongPass123');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(auth.lastPassword, 'StrongPass123');
    expect(auth.lastCurrentPassword, isNull);
    expect(
      find.text('Password updated.'),
      findsOneWidget,
    );
  });

  testWidgets('security screen changes a password with current password', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _RecordingAccountPasswordService();

    await _pumpSecurityScreen(
      tester,
      prefs: prefs,
      accountPasswordService: auth,
      hasPassword: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Change Password'), findsOneWidget);

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Change password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123');
    await tester.enterText(find.byType(TextField).at(2), 'StrongPass123');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(auth.lastPassword, 'StrongPass123');
    expect(auth.lastCurrentPassword, 'OldPass123');
  });

  testWidgets('security screen rejects passwords outside Cognito policy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _RecordingAccountPasswordService();

    await _pumpSecurityScreen(
      tester,
      prefs: prefs,
      accountPasswordService: auth,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'STRONGPASS123');
    await tester.enterText(find.byType(TextField).at(1), 'STRONGPASS123');
    await tester.tap(find.text('Save password'));
    await tester.pump();

    expect(find.textContaining('Include 1 lowercase letter'), findsOneWidget);
    expect(auth.lastPassword, isNull);
  });

  testWidgets('security screen shows password save errors inline', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _RecordingAccountPasswordService()
      ..setPasswordError = Exception('Password update failed');
    AppError.configure(
      referenceIdFactory: () => 'SECURITY',
      logger: (_) {},
    );

    await _pumpSecurityScreen(
      tester,
      prefs: prefs,
      accountPasswordService: auth,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'StrongPass123');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123');
    await tester.tap(find.text('Save password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Add password'), findsOneWidget);
    expect(
      find.textContaining('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
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
