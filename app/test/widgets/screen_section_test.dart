import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/widgets/screen_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScreenSection renders section title as editorial title case',
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

    expect(find.text('Regret patterns'), findsOneWidget);
    expect(find.text('REGRET PATTERNS'), findsNothing);
    expect(
      find.text('The repeat signals worth noticing before the next purchase.'),
      findsOneWidget,
    );

    final title = tester.widget<Text>(find.text('Regret patterns'));
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.style?.letterSpacing ?? 0, 0);
  });

  testWidgets('ScreenSection can opt into eyebrow uppercase labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ScreenSection(
            title: 'Audit trail',
            uppercase: true,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('AUDIT TRAIL'), findsOneWidget);
    expect(find.text('Audit trail'), findsNothing);
  });
}
