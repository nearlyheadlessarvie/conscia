import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
