import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/widgets/screen_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScreenSection renders section title as uppercase muted label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ScreenSection(
            title: 'Regret patterns',
            subtitle:
                'The repeat signals worth noticing before the next purchase.',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('REGRET PATTERNS'), findsOneWidget);
    expect(find.text('Regret patterns'), findsNothing);
    expect(
      find.text('The repeat signals worth noticing before the next purchase.'),
      findsOneWidget,
    );

    final title = tester.widget<Text>(find.text('REGRET PATTERNS'));
    expect(title.style?.fontSize, 11);
    expect(title.style?.fontWeight, FontWeight.w900);
    expect(title.style?.letterSpacing, greaterThanOrEqualTo(0.8));
  });
}
