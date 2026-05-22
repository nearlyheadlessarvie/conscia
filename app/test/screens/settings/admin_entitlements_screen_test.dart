import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/admin_entitlement_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/admin_entitlements_screen.dart';
import 'package:conscia_app/services/admin_entitlement_service.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
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
  }) async =>
      null;
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
}

class _FakeAdminEntitlementService extends AdminEntitlementService {
  _FakeAdminEntitlementService() : super(Dio());

  int lookupCalls = 0;
  int grantCalls = 0;
  String? lastLookupEmail;
  String? lastGrantedUserId;
  String? lastGrantNote;

  @override
  Future<AdminUserLookup> lookupByEmail(String email) async {
    lookupCalls += 1;
    lastLookupEmail = email;
    return const AdminUserLookup(
      userId: '10000000-0000-4000-8000-000000000001',
      email: 'story-demo@example.com',
      isLifetime: true,
      source: 'lifetime',
      isActive: true,
    );
  }

  @override
  Future<AdminUserLookup> grantLifetimePremium(
      String userId, String note) async {
    grantCalls += 1;
    lastGrantedUserId = userId;
    lastGrantNote = note;
    return const AdminUserLookup(
      userId: '10000000-0000-4000-8000-000000000001',
      email: 'story-demo@example.com',
      isLifetime: true,
      source: 'lifetime',
      isActive: true,
    );
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeAdminEntitlementService service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'admin-user-1',
              accessToken: 'header.payload.signature',
            ),
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'admin-user-1',
            email: 'story-admin@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        adminEntitlementAccessProvider.overrideWith((ref) async => true),
        adminEntitlementServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: AdminEntitlementsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('lookup populates target user id and shows source',
      (tester) async {
    final service = _FakeAdminEntitlementService();

    await _pumpScreen(tester, service: service);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('admin-entitlements-lookup-email')),
      'story-demo@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lookup user'));
    await tester.pumpAndSettle();

    expect(service.lookupCalls, 1);
    expect(service.lastLookupEmail, 'story-demo@example.com');
    expect(find.byType(FloatingLabelTextField), findsWidgets);
    expect(
      find.text(
          'story-demo@example.com\n10000000-0000-4000-8000-000000000001\nlifetime\nactive=true'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('admin-entitlements-target-user-id')),
        matching: find.text('10000000-0000-4000-8000-000000000001'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('grant button calls admin entitlement service', (tester) async {
    final service = _FakeAdminEntitlementService();

    await _pumpScreen(tester, service: service);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('admin-entitlements-target-user-id')),
      '10000000-0000-4000-8000-000000000001',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin-entitlements-note')),
      'story demo grant',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Grant lifetime premium'),
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, 'Grant lifetime premium'));
    await tester.pumpAndSettle();

    expect(service.grantCalls, 1);
    expect(service.lastGrantedUserId, '10000000-0000-4000-8000-000000000001');
    expect(service.lastGrantNote, 'story demo grant');
    expect(
      find.text(
          'Granted story-demo@example.com (10000000-0000-4000-8000-000000000001) source=lifetime'),
      findsOneWidget,
    );
  });
}
