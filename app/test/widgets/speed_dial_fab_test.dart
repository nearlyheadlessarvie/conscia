// app/test/widgets/speed_dial_fab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/widgets/speed_dial_fab.dart';

GoRouter _makeRouter() => GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
                floatingActionButton: SpeedDialFab(),
                body: Text('home'),
              )),
      GoRoute(
          path: '/transactions/add',
          builder: (_, __) => const Scaffold(body: Text('add'))),
    ]);

void main() {
  testWidgets('SpeedDialFab renders closed state with add icon',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(routerConfig: _makeRouter()),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('SpeedDialFab shows child actions when tapped', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(routerConfig: _makeRouter()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Ask Conscia'), findsOneWidget);
    expect(find.text('Scan Receipt'), findsOneWidget);
  });
}
