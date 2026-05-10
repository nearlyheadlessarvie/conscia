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
  testWidgets('MainShell shows five navigation destinations and add FAB',
      (tester) async {
    await _pumpShell(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('MainShell renders an emphasized raised scan action on mobile',
      (tester) async {
    await _pumpShell(tester);

    final raisedScanButton =
        find.byKey(const ValueKey('main-shell-scan-button'));
    expect(raisedScanButton, findsOneWidget);

    final scanPosition = tester.getTopLeft(raisedScanButton);
    final navigationBarPosition = tester.getTopLeft(find.byType(NavigationBar));
    final scanBottom = tester.getBottomLeft(raisedScanButton);

    expect(scanPosition.dy, lessThan(navigationBarPosition.dy));
    expect(scanBottom.dy, greaterThan(navigationBarPosition.dy));
  });

  testWidgets('MainShell hides the shared add FAB on transactions, assistant, and settings on mobile',
      (tester) async {
    await _pumpShell(tester, initialLocation: '/transactions');
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(tester, initialLocation: '/assistant');
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(tester, initialLocation: '/settings');
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('MainShell hides the navigation rail add FAB on transactions, assistant, and settings',
      (tester) async {
    const wideSize = Size(1200, 800);

    await _pumpShell(
      tester,
      initialLocation: '/transactions',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(
      tester,
      initialLocation: '/assistant',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpShell(
      tester,
      initialLocation: '/settings',
      windowSize: wideSize,
    );
    expect(find.byType(NavigationRail), findsOneWidget);
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

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsOneWidget);

    router.go('/transactions');
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsNothing);
    expect(find.text('transactions'), findsOneWidget);
  });
}
