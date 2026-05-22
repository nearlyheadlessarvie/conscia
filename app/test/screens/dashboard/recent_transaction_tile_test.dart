import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

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

  testWidgets('regret tag uses the shared soft badge icon language', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionTile(
            id: 'tx-2',
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
            regretLevel: 0,
          ),
        ),
      ),
    );

    final regretTag = tester.widget<HugeIcon>(
      find.descendant(
        of: find.byKey(const ValueKey('regret-transaction-badge')),
        matching: find.byType(HugeIcon),
      ),
    );

    expect(regretTag.icon, isNotNull);
    expect(regretTag.size, 10.5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('regret-transaction-badge')),
        matching: find.byType(Container),
      ),
      findsOneWidget,
    );
  });
}
