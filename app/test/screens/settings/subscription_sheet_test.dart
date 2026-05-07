import 'package:conscia_app/providers/iap_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/screens/settings/widgets/subscription_sheet.dart';
import 'package:conscia_app/services/iap_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIAPService extends IAPService {
  _FakeIAPService()
      : super(
          subscriptionService: _FakeSubscriptionService(),
          onPurchaseCompleted: () {},
        );

  int manageCalls = 0;

  @override
  Future<bool> openManageSubscriptions() async {
    manageCalls += 1;
    return false;
  }
}

class _FakeSubscriptionService extends SubscriptionService {
  _FakeSubscriptionService() : super(Dio());
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required SubscriptionStatus status,
  required _FakeIAPService iapService,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith((ref) async => status),
        iapServiceProvider.overrideWithValue(iapService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => SubscriptionSheet.show(context),
              child: const Text('Open subscription'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open subscription'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('subscription sheet shows manage state for premium users', (
    tester,
  ) async {
    final iapService = _FakeIAPService();

    await _pumpSheetHost(
      tester,
      status: SubscriptionStatus(
        tier: 'premium',
        isPremium: true,
        expiresAt: DateTime(2026, 6, 7),
      ),
      iapService: iapService,
    );

    expect(find.text('Manage Conscia Premium'), findsOneWidget);
    expect(find.text('Subscribe Now'), findsNothing);
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(find.textContaining('Premium access stays active until 6/7/2026'),
        findsOneWidget);
    expect(find.text('Restore Purchases'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('subscription sheet highlights free plan for free users', (
    tester,
  ) async {
    final iapService = _FakeIAPService();

    await _pumpSheetHost(
      tester,
      status: const SubscriptionStatus(
        tier: 'free',
        isPremium: false,
      ),
      iapService: iapService,
    );

    expect(find.text('Unlock Conscia Premium'), findsOneWidget);
    expect(find.text('Subscribe Now'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('subscription sheet shows inline dev-mode management notice', (
    tester,
  ) async {
    final iapService = _FakeIAPService();

    await _pumpSheetHost(
      tester,
      status: SubscriptionStatus(
        tier: 'premium',
        isPremium: true,
        expiresAt: DateTime(2026, 6, 7),
      ),
      iapService: iapService,
    );

    await tester.ensureVisible(find.text('Manage Subscription'));
    await tester.tap(find.text('Manage Subscription'));
    await tester.pumpAndSettle();

    expect(iapService.manageCalls, 0);
    expect(
      find.textContaining(
        'Subscription management is not available in development mode.',
      ),
      findsOneWidget,
    );
  });
}
