import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/password_reset_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
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
    return null;
  }
}

class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier()
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        );

  String? lastResetEmail;
  String? lastConfirmEmail;
  String? lastConfirmCode;
  String? lastConfirmPassword;

  @override
  Future<void> startPasswordReset(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> confirmPasswordReset(
    String email,
    String confirmationCode,
    String password,
  ) async {
    lastConfirmEmail = email;
    lastConfirmCode = confirmationCode;
    lastConfirmPassword = password;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('password reset starts with email entry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _RecordingAuthNotifier()),
        ],
        child: const MaterialApp(
          home: PasswordResetScreen(),
        ),
      ),
    );

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);
    expect(find.text('Verification code'), findsNothing);
  });

  testWidgets('password reset confirms code and new password', (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: PasswordResetScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'reset@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
    await tester.pump();

    expect(authNotifier.lastResetEmail, 'reset@example.com');
    expect(find.text('Verification code'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'FreshPass123');
    await tester.enterText(fields.at(2), 'FreshPass123');
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pump();

    expect(authNotifier.lastConfirmEmail, 'reset@example.com');
    expect(authNotifier.lastConfirmCode, '123456');
    expect(authNotifier.lastConfirmPassword, 'FreshPass123');
  });
}
