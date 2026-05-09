import 'package:conscia_app/widgets/conscience_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _assetImageFinder(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetName,
    );

void main() {
  testWidgets('ConscienceLoader renders layered assistant loading scene and label', (
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
    await tester.pumpAndSettle();

    expect(find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(
      _assetImageFinder('assets/images/sprites/devil/2_push.PNG'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/2_block.PNG'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/3_left.PNG'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('conscience-devil-push')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-block')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-left')), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(
      _assetImageFinder('assets/images/sprites/devil/1_neutral.PNG'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/2_block.PNG'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/1_neutral.PNG'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('conscience-devil-neutral')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-block')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-neutral')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-reflection')), findsOneWidget);
    expect(find.text('Your conscience is weighing both sides...'), findsNothing);
  });
}
