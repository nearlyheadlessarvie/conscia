import 'package:conscia_app/core/utils/email_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts multi-part country-code domains', () {
    expect(isValidEmailAddress('nearlyheadlessarvie@live.com.ph'), isTrue);
  });

  test('rejects incomplete email addresses', () {
    expect(isValidEmailAddress('nearlyheadlessarvie@live'), isFalse);
  });
}
