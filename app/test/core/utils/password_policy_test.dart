import 'package:conscia_app/core/utils/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cognito password policy requires length, number, lowercase, uppercase',
      () {
    expect(validatePasswordForCognito(''), 'Password is required');
    expect(validatePasswordForCognito('Aa1aaaa'), 'At least 8 characters');
    expect(validatePasswordForCognito('SecurePassword'), 'Include 1 number');
    expect(validatePasswordForCognito('SECUREPASS123'),
        'Include 1 lowercase letter');
    expect(validatePasswordForCognito('securepass123'),
        'Include 1 uppercase letter');
    expect(validatePasswordForCognito('SecurePass123'), isNull);
  });
}
