import 'package:conscia_app/widgets/conscience_loader_tracks.dart';
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
  testWidgets(
    'ConscienceLoader can render assistant saved branch poses from the sprite sheet',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConscienceLoader(
              size: 90,
              preset: ConscienceLoaderPreset.assistant,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('conscience-angel-shield')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
    },
  );

  testWidgets(
    'ConsciaAlterEgoMotion can force the assistant spent branch in tests',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.assistantLoading,
              forcedOutcome: ConscienceBattleOutcome.spent,
              size: 90,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('conscience-devil-win')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('conscience-angel-lose')), findsOneWidget);
    },
  );

  testWidgets(
    'ConscienceLoader renders assistant saved branch poses',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.assistantLoading,
              forcedOutcome: ConscienceBattleOutcome.saved,
              size: 90,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('conscience-angel-shield')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
      expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
    },
  );

  testWidgets(
    'ConscienceLoader renders assistant spent branch poses',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.assistantLoading,
              forcedOutcome: ConscienceBattleOutcome.spent,
              size: 90,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('conscience-devil-win')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('conscience-angel-lose')), findsOneWidget);
      expect(find.byKey(const ValueKey('conscience-money-afraid')),
          findsOneWidget);
    },
  );

  testWidgets(
      'ConscienceLoader renders layered assistant loading scene and label', (
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

    expect(
        find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(
      _assetImageFinder('assets/images/sprites/devil/2_push.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/2_block.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/3_left.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/devil/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('conscience-angel-shield')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('conscience-loader-ring')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-assistant')),
        findsOneWidget);
  });

  testWidgets(
    'ConscienceLoader reflection stays in calm protection poses',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.reflectionLoading,
              size: 90,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('conscience-angel-coinShield')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
      expect(find.byKey(const ValueKey('conscience-angel-lose')), findsNothing);
      expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
    },
  );

  testWidgets(
      'ConscienceLoader supports calmer reflection preset with no-label mode',
      (tester) async {
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
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/2_block.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/1_neutral.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/devil/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('conscience-devil-push')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-coinShield')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-reflection')),
        findsOneWidget);
    expect(
        find.text('Your conscience is weighing both sides...'), findsNothing);
  });

  testWidgets(
    'Reflection loader does not expose spent-ending defeat keys',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConsciaAlterEgoMotion(
              preset: ConsciaAlterEgoPreset.reflectionLoading,
              size: 72,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
      expect(find.byKey(const ValueKey('conscience-angel-lose')), findsNothing);
    },
  );
}
