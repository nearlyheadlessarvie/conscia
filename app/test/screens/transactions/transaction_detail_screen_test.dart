import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/screens/transactions/transaction_detail_screen.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('detail screen shows edited transaction returned from edit route', (
    tester,
  ) async {
    final originalTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Watami',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final updatedTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Ippudo',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final router = GoRouter(
      initialLocation: '/transactions/tx-1',
      routes: [
        GoRoute(
          path: '/transactions/:id',
          builder: (_, state) => TransactionDetailScreen(
            transactionId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(updatedTransaction),
                    child: const Text('Return updated'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith(
            (ref, id) async => originalTransaction,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Watami'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return updated'));
    await tester.pumpAndSettle();

    expect(find.text('Ippudo'), findsOneWidget);
    expect(find.text('Watami'), findsNothing);
  });
}
