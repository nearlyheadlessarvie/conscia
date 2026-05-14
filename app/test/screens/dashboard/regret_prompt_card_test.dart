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

  testWidgets('uses large shared feeling buttons with thumb cue icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: CategoryIcons.badge('Dining', size: 16),
            counterparty: 'Fridays',
            amount: 1000,
            currencyCode: 'PHP',
            date: DateTime.now(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_alt_outlined), findsOneWidget);
    expect(find.text('Worth It'), findsOneWidget);
    expect(find.text('Not Sure'), findsOneWidget);
    expect(find.text('Regret'), findsOneWidget);

    for (final label in ['Worth It', 'Not Sure', 'Regret']) {
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.style?.minimumSize?.resolve({})?.height, 72);
    }

    expect(find.byIcon(Icons.sentiment_satisfied_alt), findsNothing);
    expect(find.byIcon(Icons.sentiment_neutral), findsNothing);
    expect(find.byIcon(Icons.sentiment_dissatisfied), findsNothing);
  });
}
