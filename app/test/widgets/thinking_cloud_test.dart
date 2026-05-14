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
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    // No exceptions thrown on dispose
  });
}
