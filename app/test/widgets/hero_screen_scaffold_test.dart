import 'package:conscia_app/widgets/hero_screen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HeroScreenScaffold lifts the bottom action above the keyboard',
      (tester) async {
    Future<double> pumpWithInset(double bottomInset) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: bottomInset),
            ),
            child: const HeroScreenScaffold(
              bottom: SizedBox(
                key: ValueKey('bottom-cta'),
                height: 48,
                child: Placeholder(),
              ),
              child: SizedBox(height: 800),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getBottomLeft(find.byKey(const ValueKey('bottom-cta'))).dy;
    }

    final withoutKeyboard = await pumpWithInset(0);
    final withKeyboard = await pumpWithInset(260);

    expect(withKeyboard, lessThan(withoutKeyboard));
  });

  testWidgets('HeroScreenScaffold keeps scroll position isolated per key',
      (tester) async {
    final bucket = PageStorageBucket();

    Future<void> pumpScreen({
      required Key scrollKey,
      required String label,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PageStorage(
            bucket: bucket,
            child: HeroScreenScaffold(
              scrollViewKey: scrollKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 3200),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpScreen(
      scrollKey: const PageStorageKey('first-scroll'),
      label: 'First screen top',
    );

    final beforeScrollTop = tester.getTopLeft(find.text('First screen top')).dy;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    final afterScrollTop = tester.getTopLeft(find.text('First screen top')).dy;
    expect(afterScrollTop, lessThan(beforeScrollTop));

    await pumpScreen(
      scrollKey: const PageStorageKey('second-scroll'),
      label: 'Second screen top',
    );

    expect(find.text('Second screen top'), findsOneWidget);
  });
}
