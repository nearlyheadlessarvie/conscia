import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recent transaction tile uses one category badge background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionTile(
            id: 'tx-1',
            categoryBadge: CategoryIcons.badge(
              'Dining',
              size: 22,
              filled: false,
            ),
            counterparty: 'Starbucks',
            category: 'Dining',
            date: DateTime(2026, 5, 9),
            amount: 280,
            isIncome: false,
            currencyCode: 'PHP',
            regretLevel: 1,
          ),
        ),
      ),
    );

    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('Starbucks'), findsOneWidget);
  });
}
