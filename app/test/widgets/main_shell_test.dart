import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/widgets/main_shell.dart';

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const MainShell(
            child: Scaffold(body: Text('home')),
          ),
        ),
      ],
    );

void main() {
  testWidgets('MainShell shows five navigation destinations and add FAB',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('MainShell renders an emphasized raised scan action on mobile',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();

    final raisedScanButton = find.byKey(const ValueKey('main-shell-scan-button'));
    expect(raisedScanButton, findsOneWidget);

    final scanPosition = tester.getTopLeft(raisedScanButton);
    final navigationBarPosition = tester.getTopLeft(find.byType(NavigationBar));

    expect(scanPosition.dy, lessThan(navigationBarPosition.dy));
  });
}
