import 'package:conscia_app/widgets/conscience_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConscienceLoader renders alter ego scene and label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(
            size: 90,
            label: 'Your conscience is weighing both sides...',
          ),
        ),
      ),
    );

    expect(find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-ring')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-flash')), findsOneWidget);
  });

  testWidgets('ConscienceLoader supports no-label mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(size: 72),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Your conscience is weighing both sides...'), findsNothing);
  });
}
