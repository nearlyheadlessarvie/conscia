import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../services/passkey_service.dart';
import 'auth_provider.dart';
import 'usage_provider.dart';

const passkeyRegisteredEmailsPreferenceKey = 'passkey_registered_emails';
const passkeyFirstSignInEnabledPreferenceKey = 'passkey_first_sign_in_enabled';

class PasskeySignInPreference {
  const PasskeySignInPreference({
    required this.registeredEmails,
    required this.isPasskeyFirstEnabled,
  });

  final List<String> registeredEmails;
  final bool isPasskeyFirstEnabled;

  bool get canUsePasskeyFirst =>
      isPasskeyFirstEnabled && registeredEmails.isNotEmpty;

  bool hasRegisteredEmail(String email) {
    return registeredEmails.contains(_normalizePasskeyEmail(email));
  }

  PasskeySignInPreference copyWith({
    List<String>? registeredEmails,
    bool? isPasskeyFirstEnabled,
  }) {
    return PasskeySignInPreference(
      registeredEmails: registeredEmails ?? this.registeredEmails,
      isPasskeyFirstEnabled:
          isPasskeyFirstEnabled ?? this.isPasskeyFirstEnabled,
    );
  }
}

class PasskeySignInPreferenceNotifier
    extends StateNotifier<PasskeySignInPreference> {
  PasskeySignInPreferenceNotifier(this._prefs)
      : super(
          PasskeySignInPreference(
            registeredEmails: _loadRegisteredEmails(_prefs),
            isPasskeyFirstEnabled:
                _prefs.getBool(passkeyFirstSignInEnabledPreferenceKey) ?? false,
          ),
        );

  final SharedPreferences _prefs;

  Future<void> registerEmail(String email) async {
    final normalized = _normalizePasskeyEmail(email);
    if (normalized.isEmpty) return;

    final emails = [...state.registeredEmails];
    if (!emails.contains(normalized)) {
      emails.add(normalized);
    }

    state = state.copyWith(registeredEmails: List.unmodifiable(emails));
    await _prefs.setStringList(passkeyRegisteredEmailsPreferenceKey, emails);
  }

  Future<void> forgetEmail(String email) async {
    final normalized = _normalizePasskeyEmail(email);
    if (normalized.isEmpty) return;

    final emails = state.registeredEmails
        .where((registeredEmail) => registeredEmail != normalized)
        .toList(growable: false);
    final passkeyFirstEnabled =
        emails.isNotEmpty && state.isPasskeyFirstEnabled;

    state = state.copyWith(
      registeredEmails: List.unmodifiable(emails),
      isPasskeyFirstEnabled: passkeyFirstEnabled,
    );
    await _prefs.setStringList(passkeyRegisteredEmailsPreferenceKey, emails);
    await _prefs.setBool(
      passkeyFirstSignInEnabledPreferenceKey,
      passkeyFirstEnabled,
    );
  }

  Future<void> setPasskeyFirstEnabled(bool value) async {
    final enabled = value && state.registeredEmails.isNotEmpty;
    state = state.copyWith(isPasskeyFirstEnabled: enabled);
    await _prefs.setBool(passkeyFirstSignInEnabledPreferenceKey, enabled);
  }
}

final passkeySignInPreferenceProvider = StateNotifierProvider<
    PasskeySignInPreferenceNotifier, PasskeySignInPreference>((ref) {
  return PasskeySignInPreferenceNotifier(ref.watch(sharedPreferencesProvider));
});

List<String> _loadRegisteredEmails(SharedPreferences prefs) {
  final normalizedEmails = <String>[];
  for (final email
      in prefs.getStringList(passkeyRegisteredEmailsPreferenceKey) ??
          const <String>[]) {
    final normalized = _normalizePasskeyEmail(email);
    if (normalized.isNotEmpty && !normalizedEmails.contains(normalized)) {
      normalizedEmails.add(normalized);
    }
  }
  return List.unmodifiable(normalizedEmails);
}

String _normalizePasskeyEmail(String email) => email.trim().toLowerCase();

final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService(
    publicDio: ref.watch(authDioProvider),
    authenticatedDio: ref.watch(dioProvider),
  );
});

final passkeyAvailabilityProvider = FutureProvider<bool>((ref) async {
  if (ApiConstants.useMockAuth) {
    return false;
  }

  return ref.watch(passkeyServiceProvider).isSupported();
});

final currentSessionSupportsPasskeysProvider = Provider<bool>((ref) {
  if (ApiConstants.useMockAuth) {
    return false;
  }

  final accessToken = ref.watch(authProvider).accessToken;
  if (accessToken == null || accessToken.split('.').length != 3) {
    return false;
  }

  try {
    final payload = accessToken.split('.')[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    final issuer = claims['iss'] as String?;
    return issuer?.contains('cognito-idp.') ?? false;
  } catch (_) {
    return false;
  }
});
