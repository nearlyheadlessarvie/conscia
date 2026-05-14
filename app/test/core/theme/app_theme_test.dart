import 'dart:io';

import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme keeps card surfaces flat in light and dark modes', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();

    expect(
        RegExp(r'cardTheme:\s+CardThemeData\(\s+elevation:\s+0,')
            .allMatches(source)
            .length,
        2);
    expect(source, isNot(contains('elevation: 2,')));
  });

  test('AppTheme maps section and card typography to Conscia v2 weights', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();

    expect(
      source,
      matches(RegExp(
        r'titleLarge:\s+GoogleFonts\.poppins\(\s+fontSize:\s+18,\s+fontWeight:\s+FontWeight\.w700,',
      )),
    );
    expect(
      source,
      matches(RegExp(
        r'titleMedium:\s+GoogleFonts\.poppins\(\s+fontSize:\s+16,\s+fontWeight:\s+FontWeight\.w700,',
      )),
    );
    expect(source, contains('letterSpacing: 0,'));
  });

  test('AppTheme makes primary and secondary buttons pill CTAs', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final filledStyle = theme.filledButtonTheme.style!;
      final outlinedStyle = theme.outlinedButtonTheme.style!;
      final textStyle = theme.textButtonTheme.style!;

      expect(filledStyle.minimumSize?.resolve({}), const Size(0, 48));
      expect(outlinedStyle.minimumSize?.resolve({}), const Size(0, 48));
      expect(textStyle.minimumSize?.resolve({}), const Size(0, 48));
      expect(filledStyle.shape?.resolve({}), isA<StadiumBorder>());
      expect(outlinedStyle.shape?.resolve({}), isA<StadiumBorder>());
      expect(textStyle.shape?.resolve({}), isA<StadiumBorder>());
      expect(
        filledStyle.backgroundColor?.resolve({}),
        theme.colorScheme.primary,
      );
      expect(
        filledStyle.foregroundColor?.resolve({}),
        theme.colorScheme.onPrimary,
      );
      expect(
        outlinedStyle.side?.resolve({})?.color,
        theme.colorScheme.primary,
      );
      expect(
        outlinedStyle.foregroundColor?.resolve({}),
        theme.colorScheme.primary,
      );
    }
  });
}
