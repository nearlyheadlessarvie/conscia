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
}
