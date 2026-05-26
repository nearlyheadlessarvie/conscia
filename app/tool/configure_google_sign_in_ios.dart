import 'dart:io';

String applyGoogleSignInConfig({
  required String infoPlist,
  required String googleServiceInfoPlist,
  String? serverClientId,
}) {
  final clientId = _readPlistValue(googleServiceInfoPlist, 'CLIENT_ID');
  final reversedClientId =
      _readPlistValue(googleServiceInfoPlist, 'REVERSED_CLIENT_ID');

  var updated = _upsertStringKey(infoPlist, 'GIDClientID', clientId);
  if (serverClientId != null && serverClientId.trim().isNotEmpty) {
    updated = _upsertStringKey(
      updated,
      'GIDServerClientID',
      serverClientId.trim(),
    );
  }

  return _ensureGoogleUrlScheme(updated, reversedClientId);
}

String _readPlistValue(String plist, String key) {
  final pattern = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<string>([^<]+)</string>',
  );
  final match = pattern.firstMatch(plist);
  if (match == null) {
    throw StateError('Missing $key in GoogleService-Info.plist');
  }

  return match.group(1)!.trim();
}

String _upsertStringKey(String plist, String key, String value) {
  final pattern = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<string>[^<]*</string>',
    multiLine: true,
  );
  final replacement = '<key>$key</key>\n\t<string>$value</string>';
  if (pattern.hasMatch(plist)) {
    return plist.replaceFirst(pattern, replacement);
  }

  return _insertBeforeRootDictClose(plist, '$replacement\n');
}

String _ensureGoogleUrlScheme(String plist, String reversedClientId) {
  if (plist.contains('<string>$reversedClientId</string>')) {
    return plist;
  }

  final urlTypesPattern = RegExp(
    '<key>CFBundleURLTypes</key>\\s*<array>([\\s\\S]*?)</array>',
  );
  final match = urlTypesPattern.firstMatch(plist);

  const googleSchemeDict = '''
\t\t<dict>
\t\t\t<key>CFBundleTypeRole</key>
\t\t\t<string>Editor</string>
\t\t\t<key>CFBundleURLSchemes</key>
\t\t\t<array>
\t\t\t\t<string>%SCHEME%</string>
\t\t\t</array>
\t\t</dict>
''';

  final renderedDict =
      googleSchemeDict.replaceFirst('%SCHEME%', reversedClientId);

  if (match != null) {
    final existingBody = match.group(1)!;
    final replacement =
        '<key>CFBundleURLTypes</key>\n\t<array>$existingBody$renderedDict\t</array>';
    return plist.replaceFirst(urlTypesPattern, replacement);
  }

  final insertedSection = '''
\t<key>CFBundleURLTypes</key>
\t<array>
$renderedDict\t</array>
''';
  return _insertBeforeRootDictClose(plist, insertedSection);
}

String _insertBeforeRootDictClose(String plist, String content) {
  final rootCloseIndex = plist.lastIndexOf('</dict>');
  if (rootCloseIndex == -1) {
    throw StateError('Info.plist is missing a root dict');
  }

  return plist.replaceRange(rootCloseIndex, rootCloseIndex, content);
}

void main(List<String> args) {
  final options = _parseArgs(args);
  final infoPlistFile = File(options.infoPlistPath);
  final googleServiceInfoFile = File(options.googleServiceInfoPlistPath);

  final updated = applyGoogleSignInConfig(
    infoPlist: infoPlistFile.readAsStringSync(),
    googleServiceInfoPlist: googleServiceInfoFile.readAsStringSync(),
    serverClientId: options.serverClientId,
  );

  infoPlistFile.writeAsStringSync(updated);
}

_Options _parseArgs(List<String> args) {
  String? infoPlistPath;
  String? googleServiceInfoPlistPath;
  String? serverClientId;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    switch (arg) {
      case '--info-plist':
        infoPlistPath = args[++index];
      case '--google-service-info-plist':
        googleServiceInfoPlistPath = args[++index];
      case '--server-client-id':
        serverClientId = args[++index];
      default:
        throw ArgumentError('Unknown argument: $arg');
    }
  }

  if (infoPlistPath == null || googleServiceInfoPlistPath == null) {
    throw ArgumentError(
      'Usage: dart run tool/configure_google_sign_in_ios.dart '
      '--info-plist <path> --google-service-info-plist <path> '
      '[--server-client-id <id>]',
    );
  }

  return _Options(
    infoPlistPath: infoPlistPath,
    googleServiceInfoPlistPath: googleServiceInfoPlistPath,
    serverClientId: serverClientId,
  );
}

class _Options {
  const _Options({
    required this.infoPlistPath,
    required this.googleServiceInfoPlistPath,
    this.serverClientId,
  });

  final String infoPlistPath;
  final String googleServiceInfoPlistPath;
  final String? serverClientId;
}
