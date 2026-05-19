import 'package:conscia_app/widgets/hero_screen_scaffold.dart';
import 'package:conscia_app/widgets/conscia_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HeroScreenScaffold can let a hero bleed behind the app bar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 24),
          ),
          child: HeroScreenScaffold(
            bleedBehindAppBar: true,
            padding: EdgeInsets.zero,
            appBar: ConsciaAppBar(title: Text('Categories')),
            child: SizedBox(
              key: ValueKey('bleeding-hero'),
              height: 200,
            ),
          ),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('bleeding-hero'))).dy,
      0,
    );
  });

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

  testWidgets(
      'HeroScreenScaffold bottom widget clears a simulated shell nav bar',
      (tester) async {
    // Simulate the shell nav bar by setting MediaQuery.padding.bottom
    // (same effect as an outer Scaffold with a BottomNavigationBar of height 80).
    const navBarHeight = 80.0;
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: navBarHeight),
          ),
          child: HeroScreenScaffold(
            bottom: SizedBox(
              key: ValueKey('cta'),
              height: 52,
              child: Placeholder(),
            ),
            child: SizedBox(height: 400),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
    final ctaBottom =
        tester.getBottomLeft(find.byKey(const ValueKey('cta'))).dy;

    // The CTA's bottom edge must be at least navBarHeight above the screen bottom.
    // This ensures the CTA is not obscured by the shell nav bar.
    expect(
      ctaBottom,
      lessThanOrEqualTo(screenHeight - navBarHeight),
      reason: 'CTA is obscured by the shell nav bar',
    );
  });
}
