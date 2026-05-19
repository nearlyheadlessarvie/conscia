import 'package:conscia_app/widgets/thinking_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ThinkingCloudWidget renders a CustomPaint at the requested size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ThinkingCloudWidget(size: 200))),
      ),
    );
    // Widget exists
    expect(find.byType(ThinkingCloudWidget), findsOneWidget);
    // CustomPaint is present (the painter surface)
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    // Size is correct
    final sz = tester.getSize(find.byType(ThinkingCloudWidget));
    expect(sz.width, closeTo(200, 1));
    expect(sz.height, closeTo(200, 1));
  });

  testWidgets('ThinkingCloudWidget disposes without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThinkingCloudWidget())),
    );
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    // No exceptions thrown on dispose
  });

  test('ThinkingCloudWidget palette includes neutral ink particles', () {
    final neutralParticles = debugThinkingCloudPalette.where((color) {
      final red = (color.r * 255).round();
      final green = (color.g * 255).round();
      final blue = (color.b * 255).round();
      return (red - green).abs() <= 8 && (green - blue).abs() <= 8;
    });

    expect(neutralParticles.length, greaterThanOrEqualTo(3));
  });

  test('ThinkingCloudWidget gives neutral particles more visual weight', () {
    expect(
      debugThinkingCloudNeutralWeight,
      greaterThanOrEqualTo(0.34),
    );
  });

  test('ThinkingCloudWidget includes a denser boundary halo', () {
    expect(debugThinkingCloudBoundaryHaloCount, greaterThanOrEqualTo(40));
  });

  testWidgets('ThinkingCloudWidget supports a non-zero starting phase',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ThinkingCloudWidget(
            animate: false,
            initialPhase: 1.25,
          ),
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ThinkingCloudWidget),
        matching: find.byType(CustomPaint),
      ),
    );

    expect(debugThinkingCloudPainterPhase(customPaint.painter), 1.25);
  });

  testWidgets('ThinkingCloudWidget creates a safe fallback phase',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ThinkingCloudWidget(animate: false),
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ThinkingCloudWidget),
        matching: find.byType(CustomPaint),
      ),
    );
    final phase = debugThinkingCloudPainterPhase(customPaint.painter);

    expect(phase, isNotNull);
    expect(phase!.isFinite, isTrue);
  });
}
