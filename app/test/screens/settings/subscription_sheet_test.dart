import 'package:conscia_app/providers/iap_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/core/theme/app_theme.dart';
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
  int purchaseCalls = 0;
  bool purchaseShouldSucceed = false;
  @override
  IAPStatus get status => fakeStatus;
  IAPStatus fakeStatus = const IAPStatus();

  @override
  Future<bool> openManageSubscriptions() async {
    manageCalls += 1;
    return false;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> purchaseSubscription() async {
    purchaseCalls += 1;
    return purchaseShouldSucceed;
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
  testWidgets('subscription sheet shows lifetime access for comped premium users',
      (
    tester,
  ) async {
    final iapService = _FakeIAPService();

    await _pumpSheetHost(
      tester,
      status: const SubscriptionStatus(
        tier: 'premium',
        isPremium: true,
        isLifetime: true,
        source: 'lifetime',
      ),
      iapService: iapService,
    );

    expect(find.text('Conscia Premium'), findsOneWidget);
    expect(find.text('Lifetime access'), findsOneWidget);
    expect(find.textContaining('renews'), findsNothing);
  });

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

    expect(find.text('Conscia Premium'), findsOneWidget);
    expect(find.text('Subscribe Now'), findsNothing);
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(find.text('Active · renews Jun 7, 2026'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byKey(const ValueKey('subscription-plan-premium-radio')),
        findsNothing);
    expect(find.byKey(const ValueKey('subscription-comparison-list')),
        findsOneWidget);
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
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byKey(const ValueKey('subscription-plan-free-radio')),
        findsNothing);
    expect(find.byKey(const ValueKey('subscription-comparison-list')),
        findsOneWidget);
  });

  testWidgets('subscription comparison uses flat separators instead of table card',
      (
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

    expect(
      find.byKey(const ValueKey('subscription-comparison-list')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription-comparison-list')),
        matching: find.byType(Divider),
      ),
      findsWidgets,
    );

    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Subscribe Now'),
    );
    final background =
        cta.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(background, const Color(0xFFFFB300));
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

  testWidgets('subscription sheet uses rounded top corners', (tester) async {
    final iapService = _FakeIAPService();

    await _pumpSheetHost(
      tester,
      status: const SubscriptionStatus(
        tier: 'free',
        isPremium: false,
      ),
      iapService: iapService,
    );

    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    final shape = bottomSheet.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, const BorderRadius.vertical(top: Radius.circular(32)));
  });

  testWidgets('subscription CTA stays readable in dark theme', (tester) async {
    final iapService = _FakeIAPService();

    tester.view.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.view.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'free',
              isPremium: false,
            ),
          ),
          iapServiceProvider.overrideWithValue(iapService),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
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

    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Subscribe Now'),
    );
    final background = cta.style?.backgroundColor?.resolve(<WidgetState>{});
    final foreground = cta.style?.foregroundColor?.resolve(<WidgetState>{});

    expect(background, isNot(foreground));
  });

  testWidgets('subscription sheet does not show a config error before store product loads',
      (tester) async {
    final iapService = _FakeIAPService()
      ..fakeStatus = const IAPStatus(state: IAPState.uninitialized);

    await _pumpSheetHost(
      tester,
      status: const SubscriptionStatus(
        tier: 'free',
        isPremium: false,
      ),
      iapService: iapService,
    );

    expect(find.text('Subscribe Now'), findsOneWidget);
    expect(
      find.textContaining('Product not configured in store yet'),
      findsNothing,
    );
  });
}
