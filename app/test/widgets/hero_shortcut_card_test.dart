import 'package:conscia_app/core/constants/app_icons.dart';
import 'package:conscia_app/widgets/hero_shortcut_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HeroShortcutCard uses action-row title and subtitle scale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroShortcutCard(
            icon: AppIconKey.person,
            label: 'Profile',
            subtitle: 'Personal workspace',
            onPressed: () {},
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Profile'));
    final subtitle = tester.widget<Text>(find.text('Personal workspace'));

    expect(title.style?.fontSize, 14);
    expect(subtitle.style?.fontSize, 12);
  });
}
