import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app/lib uses only app-owned icon abstractions', () {
    const allowlist = {
      'lib/core/constants/app_icons.dart',
      'lib/core/constants/category_icons.dart',
      'lib/widgets/glyphs/conscia_glyph.dart',
    };

    final bannedPatterns = <String, RegExp>{
      'Icons.': RegExp(r'\bIcons\.'),
      'CupertinoIcons.': RegExp(r'\bCupertinoIcons\.'),
      'HugeIcon(': RegExp(r'\bHugeIcon\('),
      'HugeIconsStrokeRounded.': RegExp(r'\bHugeIconsStrokeRounded\.'),
      'IconData': RegExp(r'\bIconData\b'),
    };

    final violations = <String>[];
    final libDir = Directory('lib');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final relativePath =
          entity.path.replaceAll('\\', '/').replaceFirst('${Directory.current.path.replaceAll('\\', '/')}/', '');
      if (allowlist.contains(relativePath)) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        for (final entry in bannedPatterns.entries) {
          if (entry.value.hasMatch(line)) {
            violations.add(
              '$relativePath:${index + 1}: contains forbidden icon API `${entry.key}`',
            );
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Move icon usage behind AppIcons, CategoryIcons, or ConsciaGlyph:\n${violations.join('\n')}',
    );
  });
}
