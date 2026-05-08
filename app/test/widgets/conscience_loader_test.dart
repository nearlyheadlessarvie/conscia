import 'package:conscia_app/widgets/conscience_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConscienceLoader renders assistant alter ego loading scene and label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(
            size: 90,
            label: 'Your conscience is weighing both sides...',
            preset: ConscienceLoaderPreset.assistant,
          ),
        ),
      ),
    );

    expect(find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-alter-ego-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-ring')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-assistant')), findsOneWidget);
  });

  testWidgets('ConscienceLoader supports calmer reflection preset with no-label mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(
            size: 72,
            preset: ConscienceLoaderPreset.reflection,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('conscience-alter-ego-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-reflection')), findsOneWidget);
    expect(find.text('Your conscience is weighing both sides...'), findsNothing);
  });
}
