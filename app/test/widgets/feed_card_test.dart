import 'package:conscia_app/widgets/feed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FeedCard uses a softly raised bordered surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedCard(
            child: Text('Flat surface'),
          ),
        ),
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(FeedCard),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
  });
}
