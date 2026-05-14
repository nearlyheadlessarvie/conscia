import 'package:conscia_app/core/utils/localized_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizedDateFormat', () {
    test('formats supported regional date patterns without app localization',
        () {
      final date = DateTime(2026, 5, 3);

      expect(LocalizedDateFormat.numeric(date, locale: 'en_US'), '5/3/2026');
      expect(LocalizedDateFormat.numeric(date, locale: 'de_DE'), '3.5.2026');
      expect(LocalizedDateFormat.numeric(date, locale: 'fr_FR'), '3.5.2026');
      expect(LocalizedDateFormat.numeric(date, locale: 'en_IN'), '3/5/2026');
    });

    test('accepts locale tags with hyphens', () {
      expect(
        LocalizedDateFormat.numeric(DateTime(2026, 5, 3), locale: 'de-DE'),
        '3.5.2026',
      );
    });
  });
}
