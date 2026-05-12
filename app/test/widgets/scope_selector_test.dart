import 'package:conscia_app/widgets/scope_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fills the available width with balanced segments', (
    tester,
  ) async {
    var selected = 'personal';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: ScopeSelector(
                value: selected,
                familyEnabled: true,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );

    final selectorBox = tester.getRect(find.byType(ScopeSelector));

    expect(selectorBox.width, 360);

    await tester.tapAt(selectorBox.centerRight - const Offset(24, 0));

    expect(selected, 'family');
  });
}
