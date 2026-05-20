import 'package:conscia_app/dev/category_icon_font_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category icon font preview shows the curated trial set',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryIconFontPreviewScreen(),
      ),
    );

    expect(find.text('Category Icon Font Trial'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Dining'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-icon-font-preview-grid')),
      findsOneWidget,
    );
  });
}
