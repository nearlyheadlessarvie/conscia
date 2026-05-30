import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/new_password_required_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

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
        ) {
    state = const AuthState(
      status: AuthStatus.pendingPasswordChange,
      pendingEmail: 'reviewer@example.com',
      passwordChangeSession: 'challenge-session',
    );
  }

  String? lastPassword;

  @override
  Future<void> completePasswordChange(String newPassword) async {
    lastPassword = newPassword;
  }
}

void main() {
  testWidgets(
      'required password change rejects passwords outside Cognito policy',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: NewPasswordRequiredScreen(),
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'REVIEWERPASS123');
    await tester.enterText(fields.at(1), 'REVIEWERPASS123');
    await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
    await tester.pump();

    expect(find.textContaining('Include 1 lowercase letter'), findsOneWidget);
    expect(authNotifier.lastPassword, isNull);
  });
}
