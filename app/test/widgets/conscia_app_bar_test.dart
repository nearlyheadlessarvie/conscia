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

  testWidgets('keeps title centered with a trailing action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: ConsciaAppBar(
            title: const Text('Settings'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: () {},
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    final titleCenter = tester.getCenter(find.text('Settings')).dx;
    final screenCenter = tester.getSize(find.byType(Scaffold)).width / 2;

    expect(titleCenter, closeTo(screenCenter, 1));
  });

  testWidgets('uses edge alignment at rest and inset only when docked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const HeroScreenScaffold(
          appBar: ConsciaAppBar(title: Text('Settings')),
          child: SizedBox(height: 1000),
        ),
      ),
    );

    var capsuleLeft = tester
        .getTopLeft(find.byKey(const ValueKey('conscia-app-bar-capsule')))
        .dx;
    var capsuleRight = tester
        .getTopRight(find.byKey(const ValueKey('conscia-app-bar-capsule')))
        .dx;
    final screenWidth = tester.getSize(find.byType(Scaffold)).width;

    expect(capsuleLeft, 0);
    expect(screenWidth - capsuleRight, 0);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    capsuleLeft = tester
        .getTopLeft(find.byKey(const ValueKey('conscia-app-bar-capsule')))
        .dx;
    capsuleRight = tester
        .getTopRight(find.byKey(const ValueKey('conscia-app-bar-capsule')))
        .dx;

    expect(capsuleLeft, 8);
    expect(screenWidth - capsuleRight, 8);
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

  testWidgets('editorial sticky header only insets when docked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: EditorialStickyHeader(
            title: 'Transactions',
            progress: 0,
            topPadding: 0,
          ),
        ),
      ),
    );

    var headerLeft = tester
        .getTopLeft(
          find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
        )
        .dx;
    var headerRight = tester
        .getTopRight(
          find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
        )
        .dx;
    final screenWidth = tester.getSize(find.byType(Scaffold)).width;

    expect(headerLeft, 0);
    expect(screenWidth - headerRight, 0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: EditorialStickyHeader(
            title: 'Transactions',
            progress: 1,
            topPadding: 0,
          ),
        ),
      ),
    );

    headerLeft = tester
        .getTopLeft(
          find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
        )
        .dx;
    headerRight = tester
        .getTopRight(
          find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
        )
        .dx;

    expect(headerLeft, 8);
    expect(screenWidth - headerRight, 8);
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
