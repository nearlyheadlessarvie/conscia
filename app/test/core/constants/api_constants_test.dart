import 'package:conscia_app/core/constants/api_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('managed login defaults return directly to the app', () {
    expect(ApiConstants.cognitoRedirectUri, 'conscia://auth/callback');
    expect(ApiConstants.cognitoLogoutUri, 'conscia://auth/logout');
  });
}
