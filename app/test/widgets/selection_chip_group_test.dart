import 'package:conscia_app/widgets/feed_card.dart';
import 'package:conscia_app/widgets/selection_chip_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selection chip group highlights the active option', (
    tester,
  ) async {
    String? selected = 'Two';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SelectionChipGroup(
              options: const ['One', 'Two'],
              value: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selection-chip-Two-selected')),
      findsOneWidget,
    );
  });

  testWidgets('feed card renders child content inside the redesigned shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedCard(
            child: Text('Hello feed'),
          ),
        ),
      ),
    );

    expect(find.text('Hello feed'), findsOneWidget);
    expect(find.byType(FeedCard), findsOneWidget);
  });

  testWidgets('selection chip group supports custom labels and avatars', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionChipGroup(
            options: const ['self_employed'],
            value: 'self_employed',
            labelBuilder: (option) => 'Self-employed',
            avatarBuilder: (_, __) => const CircleAvatar(radius: 8),
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Self-employed'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('selection chip group shows a trailing check for the active option', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionChipGroup(
            options: const ['employed', 'retired'],
            value: 'retired',
            labelBuilder: (option) => option,
            trailingBuilder: (option, selected) => selected
                ? SizedBox(
                    key: ValueKey('selection-chip-check-$option'),
                    width: 12,
                    height: 12,
                  )
                : null,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('selection-chip-check-retired')), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-chip-check-employed')), findsNothing);
  });
}
