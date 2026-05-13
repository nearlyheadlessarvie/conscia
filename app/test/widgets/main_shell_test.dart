import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/widgets/main_shell.dart';

GoRouter _router({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('home')),
          ),
        ),
        GoRoute(
          path: '/transactions',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('transactions')),
          ),
        ),
        GoRoute(
          path: '/scan',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('scan')),
          ),
        ),
        GoRoute(
          path: '/assistant',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('assistant')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('settings')),
          ),
        ),
        GoRoute(
          path: '/sheet-demo',
          builder: (_, __) => MainShell(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const SizedBox(
                        height: 120,
                        child: Center(child: Text('Sheet content')),
                      ),
                    ),
                    child: const Text('Open sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

Future<void> _pumpShell(
  WidgetTester tester, {
  String initialLocation = '/',
  Size? windowSize,
}) async {
  if (windowSize != null) {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: _router(initialLocation: initialLocation),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MainShell renders floating dock without text labels',
      (tester) async {
    await _pumpShell(tester);

    expect(find.text('Home'), findsNothing);
    expect(find.text('Transactions'), findsNothing);
    expect(find.text('Scan'), findsNothing);
    expect(find.text('Assistant'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
  });

  testWidgets('MainShell keeps the scan action centered and emphasized',
      (tester) async {
    await _pumpShell(tester);

    final scanAction = find.byKey(const ValueKey('floating-dock-scan-action'));
    expect(scanAction, findsOneWidget);

    final dockRect =
        tester.getRect(find.byKey(const ValueKey('floating-dock-nav')));
    final scanRect = tester.getRect(scanAction);

    expect(scanRect.center.dx, closeTo(dockRect.center.dx, 1));
    expect(scanRect.height, greaterThan(48));
  });

  testWidgets('MainShell uses a circular active highlight for side tabs',
      (tester) async {
    await _pumpShell(tester);

    final activeHomeItem = find.byKey(const ValueKey('floating-dock-item-0'));
    expect(activeHomeItem, findsOneWidget);

    final activeDecoration = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: activeHomeItem,
            matching: find.byType(AnimatedContainer),
          ),
        )
        .single
        .decoration as BoxDecoration;

    expect(activeDecoration.shape, BoxShape.circle);
  });

  testWidgets('MainShell does not show a shared add FAB on mobile',
      (tester) async {
    await _pumpShell(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('MainShell does not show a navigation rail add FAB on wide home',
      (tester) async {
    await _pumpShell(
      tester,
      initialLocation: '/',
      windowSize: const Size(1200, 800),
    );

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets(
      'MainShell hides the navigation rail add FAB on transactions, assistant, and settings',
      (tester) async {
    const wideSize = Size(1200, 800);

    await _pumpShell(
      tester,
      initialLocation: '/transactions',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(
      tester,
      initialLocation: '/assistant',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(
      tester,
      initialLocation: '/settings',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('MainShell dismisses an open bottom sheet when switching tabs',
      (tester) async {
    final router = _router(initialLocation: '/sheet-demo');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MainShell));
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => const SizedBox(
          height: 120,
          child: Center(child: Text('Sheet content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsOneWidget);

    router.go('/transactions');
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsNothing);
    expect(find.text('transactions'), findsOneWidget);
  });
}
