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
    expect(find.text('Worth It'), findsWidgets);
    expect(find.text('Not Sure'), findsOneWidget);
    expect(find.text('Regret'), findsWidgets);

    for (final label in ['Worth It', 'Not Sure', 'Regret']) {
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, label),
      );
      expect(button.style?.minimumSize?.resolve({})?.height, 72);
    }

    expect(find.byIcon(Icons.sentiment_satisfied_alt), findsNothing);
    expect(find.byIcon(Icons.sentiment_neutral), findsNothing);
    expect(find.byIcon(Icons.sentiment_dissatisfied), findsNothing);
  });

  testWidgets('shows gentle guidance copy and queue hint when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: CategoryIcons.badge('Dining', size: 16),
            counterparty: 'Starbucks',
            amount: 600,
            currencyCode: 'PHP',
            date: DateTime.now(),
            queueHint: '2 more moments waiting',
            showStackedPreview: true,
          ),
        ),
      ),
    );

    expect(
      find.text('Notice what this moment gave you before you decide how it felt.'),
      findsOneWidget,
    );
    expect(find.text('2 more moments waiting'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-reflect-queue-hint')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-reflect-feature-card')), findsOneWidget);
  });

  testWidgets('right swipe tags the prompt as worth it', (tester) async {
    var worthItCount = 0;
    var regretCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: CategoryIcons.badge('Dining', size: 16),
            counterparty: 'Starbucks',
            amount: 280,
            currencyCode: 'PHP',
            date: DateTime.now(),
            onWorthIt: () => worthItCount += 1,
            onRegret: () => regretCount += 1,
          ),
        ),
      ),
    );

    await tester.drag(find.text('Starbucks'), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(worthItCount, 1);
    expect(regretCount, 0);
    expect(find.text('Dismiss'), findsNothing);
  });

  testWidgets('left swipe tags the prompt as regret', (tester) async {
    var worthItCount = 0;
    var regretCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: CategoryIcons.badge('Dining', size: 16),
            counterparty: 'Starbucks',
            amount: 280,
            currencyCode: 'PHP',
            date: DateTime.now(),
            onWorthIt: () => worthItCount += 1,
            onRegret: () => regretCount += 1,
          ),
        ),
      ),
    );

    await tester.drag(find.text('Starbucks'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(worthItCount, 0);
    expect(regretCount, 1);
    expect(find.text('Dismiss'), findsNothing);
  });
}
