import 'package:flutter_test/flutter_test.dart';

import '../../tool/configure_google_sign_in_ios.dart';

void main() {
  test('applyGoogleSignInConfig injects Google client ids and callback scheme',
      () {
    const infoPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleURLTypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>CFBundleTypeRole</key>
\t\t\t<string>Editor</string>
\t\t\t<key>CFBundleURLName</key>
\t\t\t<string>com.getconscia.app.ai</string>
\t\t\t<key>CFBundleURLSchemes</key>
\t\t\t<array>
\t\t\t\t<string>conscia</string>
\t\t\t</array>
\t\t</dict>
\t</array>
</dict>
</plist>
''';

    final updated = applyGoogleSignInConfig(
      infoPlist: infoPlist,
      clientId: 'ios-client-id.apps.googleusercontent.com',
      reversedClientId: 'com.googleusercontent.apps.1234567890-example',
      serverClientId: 'server-client-id.apps.googleusercontent.com',
    );

    expect(
      updated,
      contains(
          '<key>GIDClientID</key>\n\t<string>ios-client-id.apps.googleusercontent.com</string>'),
    );
    expect(
      updated,
      contains(
          '<key>GIDServerClientID</key>\n\t<string>server-client-id.apps.googleusercontent.com</string>'),
    );
    expect(updated, contains('<string>conscia</string>'));
    expect(
        updated,
        contains(
            '<string>com.googleusercontent.apps.1234567890-example</string>'));
    expect(
      updated.lastIndexOf('<key>GIDClientID</key>'),
      greaterThan(updated.lastIndexOf('</array>')),
    );
  });
}
