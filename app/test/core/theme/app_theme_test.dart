import 'dart:io';

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
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();

    expect(source, contains('filledButtonTheme: FilledButtonThemeData('));
    expect(source, contains('outlinedButtonTheme: OutlinedButtonThemeData('));
    expect(source, contains('textButtonTheme: TextButtonThemeData('));
    expect(
      RegExp(r'minimumSize:\s+const Size\(0,\s+48\)')
          .allMatches(source)
          .length,
      8,
    );
    expect(
      RegExp(r'shape:\s+const StadiumBorder\(\)').allMatches(source).length,
      8,
    );
    expect(source, contains('backgroundColor: colorScheme.primary'));
    expect(source, contains('foregroundColor: colorScheme.onPrimary'));
    expect(source, contains('side: BorderSide(color: colorScheme.primary'));
    expect(source, contains('foregroundColor: colorScheme.primary'));
  });

  test('AppTheme uses paper as the default pull-up sheet surface', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();

    expect(
      RegExp(
        r'bottomSheetTheme:\s+const BottomSheetThemeData\(\s+backgroundColor:\s+Color\(0xFFFFFDF8\),\s+modalBackgroundColor:\s+Color\(0xFFFFFDF8\),',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'bottomSheetTheme:\s+const BottomSheetThemeData\(\s+backgroundColor:\s+Color\(0xFF0D1117\),\s+modalBackgroundColor:\s+Color\(0xFF0D1117\),',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(r'borderRadius:\s+BorderRadius\.vertical\(top:\s+Radius\.circular\(28\)\)')
          .allMatches(source)
          .length,
      2,
    );
  });
}
