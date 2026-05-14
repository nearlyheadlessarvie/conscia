import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/widgets/editorial_sticky_header.dart';
import 'package:conscia_app/widgets/hero_screen_scaffold.dart';
import 'package:conscia_app/widgets/conscia_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts as a transparent attached header', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          appBar: ConsciaAppBar(title: Text('Settings')),
          body: SizedBox.shrink(),
        ),
      ),
    );

    final capsule = tester.widget<Container>(
      find.byKey(const ValueKey('conscia-app-bar-capsule')),
    );
    final decoration = capsule.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(0));
    expect(decoration.color, Colors.transparent);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('morphs into a floating capsule after scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const HeroScreenScaffold(
          appBar: ConsciaAppBar(title: Text('Categories')),
          child: SizedBox(height: 1000),
        ),
      ),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    final capsule = tester.widget<Container>(
      find.byKey(const ValueKey('conscia-app-bar-capsule')),
    );
    final decoration = capsule.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(999));
    expect(decoration.color, isNot(Colors.transparent));
    expect(decoration.color!.a, closeTo(0.64, 0.01));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('stays transparent until the dock threshold is crossed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const HeroScreenScaffold(
          appBar: ConsciaAppBar(title: Text('Categories')),
          child: SizedBox(height: 1000),
        ),
      ),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -5),
    );
    await tester.pumpAndSettle();

    final capsule = tester.widget<Container>(
      find.byKey(const ValueKey('conscia-app-bar-capsule')),
    );
    final decoration = capsule.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(0));
    expect(decoration.color, Colors.transparent);
  });

  testWidgets('editorial sticky header keeps partial progress transparent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: EditorialStickyHeader(
            title: 'Insights',
            progress: 0.5,
            topPadding: 0,
          ),
        ),
      ),
    );

    final header = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('editorial-sticky-header-Insights')),
    );
    final decoration = header.decoration! as BoxDecoration;

    expect(decoration.color, Colors.transparent);
  });

  testWidgets('editorial sticky header uses the same frosted docked surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: EditorialStickyHeader(
            title: 'Insights',
            progress: 1,
            topPadding: 0,
          ),
        ),
      ),
    );

    final header = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('editorial-sticky-header-Insights')),
    );
    final decoration = header.decoration! as BoxDecoration;

    expect(decoration.color!.a, closeTo(0.64, 0.01));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('uses an iOS chevron back control when the route can pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: '/detail',
        routes: {
          '/': (_) => const Scaffold(body: Text('Home')),
          '/detail': (_) => const Scaffold(
                appBar: ConsciaAppBar(title: Text('Detail')),
                body: Text('Detail body'),
              ),
        },
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
