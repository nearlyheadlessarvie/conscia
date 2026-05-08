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
}
