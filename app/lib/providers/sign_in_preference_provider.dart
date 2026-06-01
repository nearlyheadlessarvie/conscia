import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'usage_provider.dart';

const rememberedSignInEmailPreferenceKey = 'last_login_email';
const rememberedSignInDisplayNamePreferenceKey =
    'remembered_sign_in_display_name';
const showInitialSignInPreferenceKey = 'show_initial_sign_in';

class RememberedSignInPreference {
  const RememberedSignInPreference({
    required this.email,
    required this.displayName,
    required this.showInitialSignIn,
  });

  final String? email;
  final String? displayName;
  final bool showInitialSignIn;

  bool get hasRememberedIdentity => email != null && email!.trim().isNotEmpty;

  String get displayNameOrEmail {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return rememberedDisplayNameFromEmail(email ?? '');
  }

  RememberedSignInPreference copyWith({
    String? email,
    String? displayName,
    bool? showInitialSignIn,
  }) {
    return RememberedSignInPreference(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      showInitialSignIn: showInitialSignIn ?? this.showInitialSignIn,
    );
  }
}

class RememberedSignInPreferenceNotifier
    extends StateNotifier<RememberedSignInPreference> {
  RememberedSignInPreferenceNotifier(this._prefs)
      : super(_loadRememberedSignIn(_prefs));

  final SharedPreferences _prefs;

  Future<void> remember({
    required String email,
    String? displayName,
  }) async {
    final next = await persistRememberedSignInIdentity(
      _prefs,
      email: email,
      displayName: displayName,
    );
    state = next;
  }

  Future<void> showInitialSignIn() async {
    await _prefs.setBool(showInitialSignInPreferenceKey, true);
    state = state.copyWith(showInitialSignIn: true);
  }
}

final rememberedSignInPreferenceProvider = StateNotifierProvider<
    RememberedSignInPreferenceNotifier, RememberedSignInPreference>((ref) {
  return RememberedSignInPreferenceNotifier(
    ref.watch(sharedPreferencesProvider),
  );
});

Future<RememberedSignInPreference> persistRememberedSignInIdentity(
  SharedPreferences prefs, {
  required String email,
  String? displayName,
}) async {
  final normalizedEmail = _normalizeEmail(email);
  if (normalizedEmail == null) {
    return _loadRememberedSignIn(prefs);
  }

  final normalizedDisplayName = _normalizeText(displayName) ?? normalizedEmail;

  await prefs.setString(rememberedSignInEmailPreferenceKey, normalizedEmail);
  await prefs.setString(
    rememberedSignInDisplayNamePreferenceKey,
    normalizedDisplayName,
  );
  await prefs.setBool(showInitialSignInPreferenceKey, false);

  return RememberedSignInPreference(
    email: normalizedEmail,
    displayName: normalizedDisplayName,
    showInitialSignIn: false,
  );
}

RememberedSignInPreference _loadRememberedSignIn(SharedPreferences prefs) {
  return RememberedSignInPreference(
    email: _normalizeEmail(prefs.getString(rememberedSignInEmailPreferenceKey)),
    displayName: _normalizeText(
      prefs.getString(rememberedSignInDisplayNamePreferenceKey),
    ),
    showInitialSignIn: prefs.getBool(showInitialSignInPreferenceKey) ?? false,
  );
}

String rememberedDisplayNameFromEmail(String email) {
  final normalized = _normalizeEmail(email);
  if (normalized == null) return 'there';

  final localPart = normalized.split('@').first;
  final words = localPart
      .split(RegExp(r'[._+\-]+'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return normalized;

  return words
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String? _normalizeEmail(String? email) {
  final trimmed = email?.trim().toLowerCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _normalizeText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
