import 'package:conscia_app/core/constants/category_icons.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the category badge without wrapping it in another avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: CategoryIcons.badge(
              'Subscriptions',
              size: 16,
              filled: false,
            ),
            counterparty: 'OpenAI',
            amount: 300,
            currencyCode: 'PHP',
            date: DateTime.now(),
          ),
        ),
      ),
    );

    expect(find.byType(CircleAvatar), findsNothing);
  });
}
