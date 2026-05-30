import 'package:conscia_app/widgets/conscia_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('staggered dots wave renders vertical pill bars', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ConsciaStaggeredDotsWave(
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));

    final barSizes = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(ConsciaStaggeredDotsWave),
            matching: find.byType(SizedBox),
          ),
        )
        .where((box) => box.width != null && box.height != null)
        .where((box) => box.width! < 10)
        .toList();

    expect(barSizes, hasLength(5));
    expect(
      barSizes.any((box) => box.height! > box.width! * 1.5),
      isTrue,
    );
    expect(find.byType(DecoratedBox), findsNWidgets(5));
  });
}
